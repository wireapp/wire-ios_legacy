// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

public class ConnectionRequestStrategy: AbstractRequestStrategy, ZMRequestGeneratorSource, ZMContextChangeTrackerSource {

    let eventsToProcess: [ZMUpdateEventType] = [
        .userConnection
    ]

    var isFetchingAllConnections: Bool = false
    let syncProgress: SyncProgress
    let connectionByIDSync: IdentifierObjectSync<ConnectionByIDTranscoder>
    let connectionByIDTranscoder: ConnectionByIDTranscoder
    let connectionByQualifiedIDSync: IdentifierObjectSync<ConnectionByQualifiedIDTranscoder>
    let connectionByQualifiedIDTranscoder: ConnectionByQualifiedIDTranscoder
    let localConnectionListSync: PaginatedSync<Payload.PaginatedLocalConnectionList>
    let connectionListSync: PaginatedSync<Payload.PaginatedConnectionList>
    let updateSync: KeyPathObjectSync<ConnectionRequestStrategy>
    let connectToUserActionHandler: ConnectToUserActionHandler
    let updateConnectionActionHandler: UpdateConnectionActionHandler
    let actionSync: EntityActionSync

    public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext,
                applicationStatus: ApplicationStatus,
                syncProgress: SyncProgress) {

        self.syncProgress = syncProgress
        self.localConnectionListSync =
            PaginatedSync<Payload.PaginatedLocalConnectionList>(basePath: "/connections",
                                                                pageSize: 200,
                                                                context: managedObjectContext)

        self.connectionListSync =
            PaginatedSync<Payload.PaginatedConnectionList>(basePath: "/list-connections",
                                                           pageSize: 200,
                                                           method: .post,
                                                           context: managedObjectContext)

        connectionByIDTranscoder = ConnectionByIDTranscoder(context: managedObjectContext)
        connectionByIDSync = IdentifierObjectSync(managedObjectContext: managedObjectContext,
                                                  transcoder: connectionByIDTranscoder)
        connectionByQualifiedIDTranscoder = ConnectionByQualifiedIDTranscoder(context: managedObjectContext)
        connectionByQualifiedIDSync = IdentifierObjectSync(managedObjectContext: managedObjectContext, transcoder: connectionByQualifiedIDTranscoder)

        self.updateSync = KeyPathObjectSync(entityName: ZMConnection.entityName(), \.needsToBeUpdatedFromBackend)

        self.connectToUserActionHandler = ConnectToUserActionHandler(context: managedObjectContext)
        self.updateConnectionActionHandler = UpdateConnectionActionHandler(context: managedObjectContext)
        self.actionSync = EntityActionSync(actionHandlers: [
            connectToUserActionHandler,
            updateConnectionActionHandler
        ])

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration = [.allowsRequestsWhileOnline,
                              .allowsRequestsDuringSlowSync]

        updateSync.transcoder = self
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        if syncProgress.currentSyncPhase == .fetchingConnections {
            fetchAllConnections(for: apiVersion)
        }

        return requestGenerators.nextRequest(for: apiVersion)
    }

    func fetchAllConnections(for apiVersion: APIVersion) {
        guard !isFetchingAllConnections else { return }

        isFetchingAllConnections = true

        switch apiVersion {
        case .v0:
            localConnectionListSync.fetch { [weak self] (result) in
                switch result {
                case .success(let connectionList):
                    self?.createConnectionsAndFinishSyncPhase(connectionList.connections,
                                                        hasMore: connectionList.hasMore)
                case .failure:
                    self?.failSyncPhase()
                }
            }

        case .v1:
            connectionListSync.fetch { [weak self] result in
                switch result {
                case .success(let connectionList):
                    self?.createConnectionsAndFinishSyncPhase(connectionList.connections,
                                                        hasMore: connectionList.hasMore)
                case .failure:
                    self?.failSyncPhase()
                }
            }
        }
    }

    private func createConnectionsAndFinishSyncPhase(_ connections: [Payload.Connection], hasMore: Bool) {
        connections.forEach { $0.updateOrCreate(in: managedObjectContext) }

        if !hasMore {
            syncProgress.finishCurrentSyncPhase(phase: .fetchingConnections)
            isFetchingAllConnections = false
        }
    }

    private func failSyncPhase() {
        syncProgress.failCurrentSyncPhase(phase: .fetchingConnections)
    }

    public var requestGenerators: [ZMRequestGenerator] {
        if syncProgress.currentSyncPhase == .fetchingConnections {
            return [connectionListSync,
                    localConnectionListSync]
        } else {
            return [connectionByIDSync,
                    connectionByQualifiedIDSync,
                    actionSync]
        }
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [updateSync]
    }

}

extension ConnectionRequestStrategy: KeyPathObjectSyncTranscoder {

    typealias T = ZMConnection

    func synchronize(_ object: ZMConnection, completion: @escaping () -> Void) {
        defer { completion() }
        guard let apiVersion = APIVersion.current else { return }

        switch apiVersion {
        case .v0:
            if let userID = object.to.remoteIdentifier {
                let userIdSet: Set<ConnectionByIDTranscoder.T> = [userID]
                connectionByIDSync.sync(identifiers: userIdSet)
            }

        case .v1:
            if let qualifiedID = object.to.qualifiedID {
                let qualifiedIdSet: Set<ConnectionByQualifiedIDTranscoder.T> = [qualifiedID]
                connectionByQualifiedIDSync.sync(identifiers: qualifiedIdSet)
            }
        }
    }

    func cancel(_ object: ZMConnection) {
        // We don't need to cancel connections
    }

}

extension ConnectionRequestStrategy: ZMEventConsumer {

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        for event in events {
            guard
                eventsToProcess.contains(event.type),
                let payloadAsDictionary = event.payload as? [String: Any],
                let payloadData = try? JSONSerialization.data(withJSONObject: payloadAsDictionary, options: [])
            else {
                continue
            }

            switch event.type {
            case .userConnection:
                let conversationEvent = Payload.UserConnectionEvent(payloadData)
                conversationEvent?.process(in: managedObjectContext)
            default:
                break
            }
        }
    }

}

class ConnectionByIDTranscoder: IdentifierObjectSyncTranscoder {
    public typealias T = UUID

    var fetchLimit: Int = 1

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func request(for identifiers: Set<UUID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let userID = identifiers.first.map({ $0.transportString() }) else { return nil }

        // GET /connections/<UUID>
        return ZMTransportRequest(getFromPath: "/connections/\(userID)", apiVersion: apiVersion.rawValue)
    }

    func didReceive(response: ZMTransportResponse, for identifiers: Set<UUID>) {
        guard
            let userID = identifiers.first,
            let connection = ZMConnection.fetch(userID: userID, domain: nil, in: context)
        else {
            Logging.eventProcessing.error("Can't update connection since it was found, aborting...")
            return
        }

        guard response.result != .permanentError else {
            connection.needsToBeUpdatedFromBackend = false
            return
        }

        guard
            let rawData = response.rawData,
            let payload = Payload.Connection(rawData, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        payload.update(connection, in: context)
    }

}

class ConnectionByQualifiedIDTranscoder: IdentifierObjectSyncTranscoder {
    public typealias T = QualifiedID

    var fetchLimit: Int = 1

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func request(for identifiers: Set<QualifiedID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            apiVersion > .v0,
            let qualifiedID = identifiers.first
        else {
            return nil
        }

        // GET /connections/domain/<UUID>
        return ZMTransportRequest(getFromPath: "/connections/\(qualifiedID.domain)/\(qualifiedID.uuid.transportString())", apiVersion: apiVersion.rawValue)
    }

    func didReceive(response: ZMTransportResponse, for identifiers: Set<QualifiedID>) {
        guard
            let qualifiedID = identifiers.first,
            let connection = ZMConnection.fetch(userID: qualifiedID.uuid, domain: qualifiedID.domain, in: context)
        else {
            Logging.eventProcessing.error("Can't update connection since it was found, aborting...")
            return
        }

        guard response.result != .permanentError else {
            connection.needsToBeUpdatedFromBackend = false
            return
        }

        guard
            let rawData = response.rawData,
            let payload = Payload.Connection(rawData, decoder: decoder)
        else {
            Logging.network.error("Can't process response, aborting.")
            return
        }

        payload.update(connection, in: context)
    }

}
