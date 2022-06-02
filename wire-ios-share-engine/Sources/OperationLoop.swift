//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import CoreData
import WireTransport
import WireRequestStrategy

let contextWasMergedNotification = Notification.Name("zm_contextWasSaved")

final class RequestGeneratorStore {

    let requestGenerators: [ZMTransportRequestGenerator]
    let changeTrackers: [ZMContextChangeTracker]
    private var isTornDown = false

    private let strategies: [AnyObject]

    init(strategies: [AnyObject]) {

        self.strategies = strategies

        var requestGenerators: [ZMTransportRequestGenerator] = []
        var changeTrackers: [ZMContextChangeTracker] = []

        for strategy in strategies {
            if let requestGeneratorSource = strategy as? ZMRequestGeneratorSource {
                for requestGenerator in requestGeneratorSource.requestGenerators {
                    requestGenerators.append({
                        guard let apiVersion = APIVersion.current else { return nil }
                        return requestGenerator.nextRequest(for: apiVersion)
                    })
                }
            }

            if let contextChangeTrackerSource = strategy as? ZMContextChangeTrackerSource {
                changeTrackers.append(contentsOf: contextChangeTrackerSource.contextChangeTrackers)
            }

            if let contextChangeTracker = strategy as? ZMContextChangeTracker {
                changeTrackers.append(contextChangeTracker)
            }

            if let requestStrategy = strategy as? RequestStrategy {
                requestGenerators.append({
                    guard let apiVersion = APIVersion.current else { return nil }
                    return requestStrategy.nextRequest(for: apiVersion)
                })
            }
        }

        self.requestGenerators = requestGenerators
        self.changeTrackers = changeTrackers
    }

    deinit {
        precondition(isTornDown, "Need to call `tearDown` before deallocating this object")
    }

    func tearDown() {
        strategies.forEach {
            if $0.responds(to: #selector(ZMObjectSyncStrategy.tearDown)) {
                ($0 as? ZMObjectSyncStrategy)?.tearDown()
            }
        }

        isTornDown = true
    }

    public func nextRequest() -> ZMTransportRequest? {
        for requestGenerator in requestGenerators {
            if let request = requestGenerator() {
                return request
            }
        }

        return nil
    }
}

final class RequestGeneratorObserver {

    private let context: NSManagedObjectContext
    public var observedGenerator: ZMTransportRequestGenerator?

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func nextRequest() -> ZMTransportRequest? {
        guard let request = observedGenerator?() else { return nil }

        request.add(ZMCompletionHandler(on: context, block: { [weak self] _ in
            self?.context.saveOrRollback()

            RequestAvailableNotification.notifyNewRequestsAvailable(nil)

            self?.context.dispatchGroup.notify(on: DispatchQueue.global(), block: {
                RequestAvailableNotification.notifyNewRequestsAvailable(nil)
            })
        }))

        return request
    }

}

final class OperationLoop: NSObject, RequestAvailableObserver {

    typealias RequestAvailableClosure = () -> Void
    typealias ChangeClosure = (_ changed: Set<NSManagedObject>) -> Void
    typealias SaveClosure = (_ notification: Notification, _ insertedObjects: Set<NSManagedObject>, _ updatedObjects: Set<NSManagedObject>) -> Void

    private unowned let syncContext: NSManagedObjectContext
    private unowned let userContext: NSManagedObjectContext
    private let callBackQueue: OperationQueue
    private var tokens: [NSObjectProtocol] = []

    public var changeClosure: ChangeClosure?
    public var requestAvailableClosure: RequestAvailableClosure?

    init(userContext: NSManagedObjectContext, syncContext: NSManagedObjectContext, callBackQueue: OperationQueue = .main) {
        self.userContext = userContext
        self.syncContext = syncContext
        self.callBackQueue = callBackQueue

        super.init()

        RequestAvailableNotification.addObserver(self)

        tokens.append(setupObserver(for: userContext) { [weak self] (note, inserted, updated) in
            self?.userInterfaceContextDidSave(notification: note, insertedObjects: inserted, updatedObjects: updated)
        })
        tokens.append(setupObserver(for: syncContext) { [weak self] (note, inserted, updated) in
            self?.syncContextDidSave(notification: note, insertedObjects: inserted, updatedObjects: updated)
        })
    }

    deinit {
        RequestAvailableNotification.removeObserver(self)
        tokens.forEach(NotificationCenter.default.removeObserver)
    }

    func setupObserver(for context: NSManagedObjectContext, onSave: @escaping SaveClosure) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: context, queue: callBackQueue) { note in
            if let insertedObjects = note.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>, let updatedObjects = note.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                onSave(note, insertedObjects, updatedObjects)
            }
        }
    }

    func merge(changes notification: Notification, intoContext context: NSManagedObjectContext) {
        let moc = notification.object as! NSManagedObjectContext
        let userInfo = moc.userInfo as NSDictionary as! [String: Any]
        context.performGroupedBlock {
            context.mergeUserInfo(fromUserInfo: userInfo)
            context.mergeChanges(fromContextDidSave: notification)
            context.processPendingChanges() // We need this because merging sometimes leaves the MOC in a 'dirty' state

            NotificationCenter.default.post(name: contextWasMergedNotification, object: context, userInfo: notification.userInfo)
        }
    }

    func syncContextDidSave(notification: Notification, insertedObjects: Set<NSManagedObject>, updatedObjects: Set<NSManagedObject>) {
        merge(changes: notification, intoContext: userContext)

        syncContext.performGroupedBlock {
            self.changeClosure?(Set(insertedObjects).union(updatedObjects))
        }
    }

    func userInterfaceContextDidSave(notification: Notification, insertedObjects: Set<NSManagedObject>, updatedObjects: Set<NSManagedObject>) {
        merge(changes: notification, intoContext: syncContext)

        let insertedObjectsIds = insertedObjects.map({ $0.objectID })
        let updatedObjectsIds  =  updatedObjects.map({ $0.objectID })

        syncContext.performGroupedBlock {
            let insertedObjects = insertedObjectsIds.compactMap(self.syncContext.object)
            let updatedObjects = updatedObjectsIds.compactMap(self.syncContext.object)

            self.changeClosure?(Set(insertedObjects).union(updatedObjects))
        }
    }

    func newRequestsAvailable() {
        requestAvailableClosure?()
    }

}

final class RequestGeneratingOperationLoop {

    private let operationLoop: OperationLoop!
    private let callBackQueue: OperationQueue

    private let requestGeneratorStore: RequestGeneratorStore
    private let requestGeneratorObserver: RequestGeneratorObserver
    private unowned let transportSession: ZMTransportSession

    init(userContext: NSManagedObjectContext, syncContext: NSManagedObjectContext, callBackQueue: OperationQueue = .main, requestGeneratorStore: RequestGeneratorStore, transportSession: ZMTransportSession) {
        self.callBackQueue = callBackQueue
        self.requestGeneratorStore = requestGeneratorStore
        self.requestGeneratorObserver = RequestGeneratorObserver(context: syncContext)
        self.transportSession = transportSession
        self.operationLoop = OperationLoop(userContext: userContext, syncContext: syncContext, callBackQueue: callBackQueue)

        operationLoop.changeClosure = { [weak self] changes in self?.objectsDidChange(changes: changes) }
        operationLoop.requestAvailableClosure = { [weak self] in self?.enqueueRequests() }
        requestGeneratorObserver.observedGenerator = { [weak self] in self?.requestGeneratorStore.nextRequest() }
    }

    fileprivate func objectsDidChange(changes: Set<NSManagedObject>) {
        requestGeneratorStore.changeTrackers.forEach {
            $0.objectsDidChange(changes)
        }

        enqueueRequests()
    }

    deinit {
        transportSession.tearDown()
        requestGeneratorStore.tearDown()
    }

    fileprivate func enqueueRequests() {
        var result: ZMTransportEnqueueResult

        repeat {
            result = transportSession.attemptToEnqueueSyncRequest(generator: { [weak self] in self?.requestGeneratorObserver.nextRequest() })
        } while result.didGenerateNonNullRequest && result.didHaveLessRequestThanMax

    }
}
