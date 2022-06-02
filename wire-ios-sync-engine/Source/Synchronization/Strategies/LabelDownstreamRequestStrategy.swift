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

struct LabelUpdate: Codable, Equatable {
    let id: UUID
    let type: Int16
    let name: String?
    let conversations: [UUID]

    init(id: UUID, type: Int16, name: String?, conversations: [UUID]) {
        self.id = id
        self.type = type
        self.name = name
        self.conversations = conversations
    }

    init?(_ label: Label) {
        guard let remoteIdentifier = label.remoteIdentifier else { return nil }

        self = .init(id: remoteIdentifier, type: label.kind.rawValue, name: label.name, conversations: label.conversations.compactMap(\.remoteIdentifier))
    }
}

struct LabelPayload: Codable, Equatable {
    var labels: [LabelUpdate]
}

public class LabelDownstreamRequestStrategy: AbstractRequestStrategy, ZMEventConsumer, ZMSingleRequestTranscoder {

    fileprivate let syncStatus: SyncStatus

    fileprivate var slowSync: ZMSingleRequestSync!
    fileprivate let jsonDecoder = JSONDecoder()

    public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus, syncStatus: SyncStatus) {
        self.syncStatus = syncStatus

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration = [.allowsRequestsDuringSlowSync,
                              .allowsRequestsDuringQuickSync,
                              .allowsRequestsWhileWaitingForWebsocket,
                              .allowsRequestsWhileOnline]
        self.slowSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
    }

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard syncStatus.currentSyncPhase == .fetchingLabels || ZMUser.selfUser(in: managedObjectContext).needsToRefetchLabels else { return nil }

        slowSync.readyForNextRequestIfNotBusy()

        return slowSync.nextRequest(for: apiVersion)
    }

    func update(with transportData: Data) {
        guard let labelResponse = try? jsonDecoder.decode(LabelPayload.self, from: transportData) else {
            Logging.eventProcessing.error("Can't apply label update due to malformed JSON")
            return
        }

        update(with: labelResponse)
    }

    func update(with response: LabelPayload) {
        updateLabels(with: response)
        deleteLabels(with: response)
    }

    fileprivate func updateLabels(with response: LabelPayload) {
        for labelUpdate in response.labels {
            var created = false

            let label: Label?
            if labelUpdate.type == Label.Kind.favorite.rawValue {
                label = Label.fetchFavoriteLabel(in: managedObjectContext)
            } else {
                label = Label.fetchOrCreate(remoteIdentifier: labelUpdate.id, create: true, in: managedObjectContext, created: &created)
            }

            label?.kind = Label.Kind(rawValue: labelUpdate.type) ?? .folder
            label?.name = labelUpdate.name
            label?.conversations = ZMConversation.fetchObjects(withRemoteIdentifiers: Set(labelUpdate.conversations), in: managedObjectContext) as? Set<ZMConversation> ?? Set()
            label?.modifiedKeys = nil
        }
    }

    fileprivate func deleteLabels(with response: LabelPayload) {
        let uuids: [NSData] = response.labels.map({ $0.id.uuidData as NSData })
        let predicate = NSPredicate(format: "type == \(Label.Kind.folder.rawValue) AND NOT remoteIdentifier_data IN %@", uuids as CVarArg)
        let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
        fetchRequest.predicate = predicate

        let deletedLabels = managedObjectContext.fetchOrAssert(request: fetchRequest)
        deletedLabels.forEach { managedObjectContext.delete($0) } // TODO jacob consider doing a batch delete
        managedObjectContext.saveOrRollback()
    }

    // MARK: - ZMEventConsumer

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        for event in events {
            guard event.type == .userPropertiesSet, (event.payload["key"] as? String) == "labels" else { continue }

            guard let value = event.payload["value"], let data = try? JSONSerialization.data(withJSONObject: value, options: []) else {
                Logging.eventProcessing.error("Skipping label update due to missing value field")
                continue
            }

            update(with: data)
        }
    }

// MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        return ZMTransportRequest(getFromPath: "/properties/labels", apiVersion: apiVersion.rawValue)
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        guard response.result == .permanentError || response.result == .success else {
            return
        }

        if response.result == .success, let rawData = response.rawData {
            update(with: rawData)
        }

        if syncStatus.currentSyncPhase == .fetchingLabels {
            syncStatus.finishCurrentSyncPhase(phase: .fetchingLabels)
        }

        ZMUser.selfUser(in: managedObjectContext).needsToRefetchLabels = false
    }

}
