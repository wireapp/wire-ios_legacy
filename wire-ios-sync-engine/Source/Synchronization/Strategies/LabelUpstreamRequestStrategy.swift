//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

public class LabelUpstreamRequestStrategy: AbstractRequestStrategy, ZMContextChangeTracker, ZMContextChangeTrackerSource, ZMSingleRequestTranscoder {

    fileprivate let jsonEncoder = JSONEncoder()
    fileprivate var upstreamSync: ZMSingleRequestSync!

    override public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration = .allowsRequestsWhileOnline
        self.upstreamSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
    }

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return upstreamSync.nextRequest(for: apiVersion)
    }

    // MARK: - ZMContextChangeTracker, ZMContextChangeTrackerSource

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [self]
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        guard let predicateForObjectsThatNeedToBeUpdatedUpstream = Label.predicateForObjectsThatNeedToBeUpdatedUpstream() else {
            fatal("predicateForObjectsThatNeedToBeUpdatedUpstream not defined for Label entity")
        }

        return Label.sortedFetchRequest(with: predicateForObjectsThatNeedToBeUpdatedUpstream)
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        guard !objects.isEmpty  else { return }

        upstreamSync.readyForNextRequestIfNotBusy()
    }

    public func objectsDidChange(_ object: Set<NSManagedObject>) {
        let labels = object.compactMap({ $0 as? Label })

        guard !labels.isEmpty, labels.any({ Label.predicateForObjectsThatNeedToBeUpdatedUpstream()!.evaluate(with: $0) }) else { return }

        upstreamSync.readyForNextRequestIfNotBusy()
    }

// MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
        let labels = managedObjectContext.fetchOrAssert(request: fetchRequest)
        let labelsToUpload = labels.filter({ !$0.markedForDeletion })
        let updatedKeys = labels.map({ return ($0, $0.modifiedKeys) })

        let labelPayload = LabelPayload(labels: labelsToUpload.compactMap({ LabelUpdate($0) }))
        let transportPayload: Any
        do {
            let data = try jsonEncoder.encode(labelPayload)
            transportPayload = try JSONSerialization.jsonObject(with: data, options: [])
        } catch let error {
            fatal("Couldn't encode label update: \(error)")
        }

        let request = ZMTransportRequest(path: "/properties/labels", method: .methodPUT, payload: transportPayload as? ZMTransportData, apiVersion: apiVersion.rawValue)
        request.add(ZMCompletionHandler(on: managedObjectContext, block: { [weak self] (response) in
            self?.didReceive(response, updatedKeys: updatedKeys)
        }))

        return request
    }

    private func didReceive(_ response: ZMTransportResponse, updatedKeys: [(Label, Set<AnyHashable>?)]) {
        guard response.result == .permanentError || response.result == .success else {
            return
        }

        for (label, updatedKeys) in updatedKeys {
            guard let updatedKeys = updatedKeys else { continue }

            if updatedKeys.contains(#keyPath(Label.markedForDeletion)) {
                managedObjectContext.delete(label)
            } else {
                label.resetLocallyModifiedKeys(updatedKeys)
            }
        }
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        if let labelsWithModifications = try? managedObjectContext.count(for: fetchRequestForTrackedObjects()!), labelsWithModifications > 0 {
            upstreamSync.readyForNextRequestIfNotBusy()
        }
    }

}
