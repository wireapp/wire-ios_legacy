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

/// Register new client, update it with new keys, deletes clients.
@objc
public final class MissingClientsRequestStrategy: AbstractRequestStrategy, ZMUpstreamTranscoder, ZMContextChangeTrackerSource {

    fileprivate(set) var modifiedSync: ZMUpstreamModifiedObjectSync! = nil
    public var requestsFactory = MissingClientsRequestFactory()

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration =  [
            .allowsRequestsWhileOnline,
            .allowsRequestsWhileInBackground,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsWhileWaitingForWebsocket
        ]
        self.modifiedSync = ZMUpstreamModifiedObjectSync(transcoder: self, entityName: UserClient.entityName(), update: modifiedPredicate(), filter: nil, keysToSync: [ZMUserClientMissingKey], managedObjectContext: managedObjectContext)
    }

    func modifiedPredicate() -> NSPredicate {
        guard let baseModifiedPredicate = UserClient.predicateForObjectsThatNeedToBeUpdatedUpstream() else {
            fatal("predicateForObjectsThatNeedToBeUpdatedUpstream is nil!")
        }
        let missingClientsPredicate = NSPredicate(format: "\(ZMUserClientMissingKey).@count > 0")

        let modifiedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            baseModifiedPredicate,
            missingClientsPredicate
            ])
        return modifiedPredicate
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return modifiedSync.nextRequest(for: apiVersion)
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [modifiedSync]
    }

    public var hasOutstandingItems: Bool {
        return modifiedSync.hasOutstandingItems
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }

    public func shouldCreateRequest(toSyncObject managedObject: ZMManagedObject, forKeys keys: Set<String>, withSync sync: Any) -> Bool {

        var keysToSync = keys
        if keys.contains(ZMUserClientMissingKey),
            let client = managedObject as? UserClient, (client.missingClients == nil || client.missingClients?.count == 0) {
            let userClientMissingKeySet: Set<AnyHashable> = [ZMUserClientMissingKey]
            let clientSet: Set<NSManagedObject> = [client]
            keysToSync.remove(ZMUserClientMissingKey)
            client.resetLocallyModifiedKeys(userClientMissingKeySet)

            modifiedSync.objectsDidChange(clientSet)
        }
        return (keysToSync.count > 0)
    }

    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject,
                                             request upstreamRequest: ZMUpstreamRequest,
                                             response: ZMTransportResponse,
                                             keysToParse keys: Set<String>) -> Bool {

        return false
    }

    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>, apiVersion: APIVersion) -> ZMUpstreamRequest? {
        guard let client = managedObject as? UserClient
        else { fatal("Called requestForUpdatingObject() on \(managedObject) to sync keys: \(keys)") }

        guard keys.contains(ZMUserClientMissingKey)
        else { fatal("Unknown keys to sync (\(keys))") }

        guard let missing = client.missingClients, missing.count > 0
        else { fatal("no missing clients found") }

        let request: ZMUpstreamRequest?

        switch apiVersion {
        case .v0:
            request = requestsFactory.fetchPrekeys(for: missing, apiVersion: apiVersion)
        case .v1:
            request = requestsFactory.fetchPrekeysFederated(for: missing, apiVersion: apiVersion)
        }

        request?.transportRequest.forceToVoipSession()
        return request
    }

    /// Returns whether synchronization of this object needs additional requests
    public func updateUpdatedObject(_ managedObject: ZMManagedObject,
                                    requestUserInfo: [AnyHashable: Any]?,
                                    response: ZMTransportResponse,
                                    keysToParse: Set<String>) -> Bool {

        guard let apiVersion = APIVersion(rawValue: response.apiVersion) else {
            return false
        }

        if keysToParse.contains(ZMUserClientMissingKey) {
            switch apiVersion {
            case .v0:
                guard let rawData = response.rawData,
                      let prekeys = Payload.PrekeyByUserID(rawData),
                      let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
                else {
                    return false
                }

                return prekeys.establishSessions(with: selfClient, context: managedObjectContext)

            case .v1:
                guard let rawData = response.rawData,
                      let prekeys = Payload.PrekeyByQualifiedUserID(rawData),
                      let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
                else {
                    return false
                }

                return prekeys.establishSessions(with: selfClient, context: managedObjectContext)
            }
        } else {
            fatal("We only expect request about missing clients")
        }
    }

    // MARK: - Unused functions

    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?, apiVersion: APIVersion) -> ZMUpstreamRequest? {
        return nil
    }

    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        // no op
    }

    // Should return the objects that need to be refetched from the BE in case of upload error
    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        // no op
    }

    public var requestGenerators: [ZMRequestGenerator] {
        return []
    }
}
