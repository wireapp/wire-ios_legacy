//
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
import WireSystem
import WireTransport
import WireUtilities
import WireCryptobox
import WireDataModel

private let zmLog = ZMSLog(tag: "userClientRS")

/// Performs actions on the self clients
///
/// Actions:
/// - Register a new client
/// - Update an existing client with prekeys
/// - Delete an existing client
/// - Fetch all self clients

@objcMembers
public final class UserClientRequestStrategy: ZMObjectSyncStrategy, ZMObjectStrategy, ZMUpstreamTranscoder, ZMSingleRequestTranscoder, RequestStrategy {

    weak var clientRegistrationStatus: ZMClientRegistrationStatus?
    weak var clientUpdateStatus: ClientUpdateStatus?

    fileprivate(set) var modifiedSync: ZMUpstreamModifiedObjectSync! = nil
    fileprivate(set) var deleteSync: ZMUpstreamModifiedObjectSync! = nil
    fileprivate(set) var insertSync: ZMUpstreamInsertedObjectSync! = nil
    fileprivate(set) var fetchAllClientsSync: ZMSingleRequestSync! = nil
    fileprivate var didRetryRegisteringSignalingKeys: Bool = false
    fileprivate var didRetryUpdatingCapabilities: Bool = false
    fileprivate let userKeysStore: UserClientKeysStore

    public var requestsFactory: UserClientRequestFactory
    public var minNumberOfRemainingKeys: UInt = 20

    fileprivate var insertSyncFilter: NSPredicate {
        return NSPredicate { object, _ -> Bool in
            guard let client = object as? UserClient, let user = client.user else { return false }
            return user.isSelfUser
        }
    }

    public init(clientRegistrationStatus: ZMClientRegistrationStatus,
                clientUpdateStatus: ClientUpdateStatus,
                context: NSManagedObjectContext,
                userKeysStore: UserClientKeysStore) {
        self.clientRegistrationStatus = clientRegistrationStatus
        self.clientUpdateStatus = clientUpdateStatus
        self.userKeysStore = userKeysStore
        self.requestsFactory = UserClientRequestFactory(keysStore: userKeysStore)
        super.init(managedObjectContext: context)

        let deletePredicate = NSPredicate(format: "\(ZMUserClientMarkedToDeleteKey) == YES")
        let modifiedPredicate = self.modifiedPredicate()

        self.modifiedSync = ZMUpstreamModifiedObjectSync(transcoder: self,
                                                         entityName: UserClient.entityName(),
                                                         update: modifiedPredicate,
                                                         filter: nil,
                                                         keysToSync: [ZMUserClientNumberOfKeysRemainingKey,
                                                                      ZMUserClientNeedsToUpdateSignalingKeysKey,
                                                                      ZMUserClientNeedsToUpdateCapabilitiesKey],
                                                         managedObjectContext: context)
        self.deleteSync = ZMUpstreamModifiedObjectSync(transcoder: self, entityName: UserClient.entityName(), update: deletePredicate, filter: nil, keysToSync: [ZMUserClientMarkedToDeleteKey], managedObjectContext: context)
        self.insertSync = ZMUpstreamInsertedObjectSync(transcoder: self, entityName: UserClient.entityName(), filter: insertSyncFilter, managedObjectContext: context)

        self.fetchAllClientsSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: context)
    }

    func modifiedPredicate() -> NSPredicate {
        guard let baseModifiedPredicate = UserClient.predicateForObjectsThatNeedToBeUpdatedUpstream() else {
            fatal("baseModifiedPredicate is nil!")
        }

        let needToUploadKeysPredicate = NSPredicate(format: "\(ZMUserClientNumberOfKeysRemainingKey) < \(minNumberOfRemainingKeys)")
        let needsToUploadSignalingKeysPredicate = NSPredicate(format: "\(ZMUserClientNeedsToUpdateSignalingKeysKey) == YES")
        let needsToUpdateCapabilitiesPredicate = NSPredicate(format: "\(ZMUserClientNeedsToUpdateCapabilitiesKey) == YES")

        let modifiedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            baseModifiedPredicate,
            NSCompoundPredicate(orPredicateWithSubpredicates: [needToUploadKeysPredicate,
                                                              needsToUploadSignalingKeysPredicate,
                                                              needsToUpdateCapabilitiesPredicate])
            ])
        return modifiedPredicate
    }

    public func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let clientRegistrationStatus = self.clientRegistrationStatus,
            let clientUpdateStatus = self.clientUpdateStatus else {
                return nil
        }

        if clientRegistrationStatus.currentPhase == .waitingForLogin {
            return nil
        }

        if clientUpdateStatus.currentPhase == .fetchingClients {
            fetchAllClientsSync.readyForNextRequestIfNotBusy()
            return fetchAllClientsSync.nextRequest(for: apiVersion)
        }

        if clientUpdateStatus.currentPhase == .deletingClients {
            if let request =  deleteSync.nextRequest(for: apiVersion) {
                return request
            }
        }

        if clientRegistrationStatus.currentPhase == .unregistered {
            if let request = insertSync.nextRequest(for: apiVersion) {
                return request
            }
        }

        if let request = modifiedSync.nextRequest(for: apiVersion) {
            return request
        }

        return nil
    }

    // we don;t use this method but it's required by ZMObjectStrategy protocol
    public var requestGenerators: [ZMRequestGenerator] {
        return []
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [self.insertSync, self.modifiedSync, self.deleteSync]
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        return requestsFactory.fetchClientsRequest(apiVersion: apiVersion)
    }

    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>, apiVersion: APIVersion) -> ZMUpstreamRequest? {
        if let managedObject = managedObject as? UserClient {
            guard let clientUpdateStatus = self.clientUpdateStatus else { fatal("clientUpdateStatus is not set") }

            var request: ZMUpstreamRequest!

            switch keys {
            case _ where keys.contains(ZMUserClientNumberOfKeysRemainingKey):
                do {
                    try request = requestsFactory.updateClientPreKeysRequest(managedObject, apiVersion: apiVersion)
                } catch let e {
                    fatal("Couldn't create request for new pre keys: \(e)")
                }
            case _ where keys.contains(ZMUserClientMarkedToDeleteKey):
                if clientUpdateStatus.currentPhase == ClientUpdatePhase.deletingClients {
                    request = requestsFactory.deleteClientRequest(managedObject, credentials: clientUpdateStatus.credentials, apiVersion: apiVersion)
                } else {
                    fatal("No email credentials in memory")
                }
            case _ where keys.contains(ZMUserClientNeedsToUpdateSignalingKeysKey):
                do {
                    try request = requestsFactory.updateClientSignalingKeysRequest(managedObject, apiVersion: apiVersion)
                } catch let e {
                    fatal("Couldn't create request for new signaling keys: \(e)")
                }
            case _ where keys.contains(ZMUserClientNeedsToUpdateCapabilitiesKey):
                do {
                    try request = requestsFactory.updateClientCapabilitiesRequest(managedObject, apiVersion: apiVersion)
                } catch let e {
                    fatal("Couldn't create request for updating Capabilities: \(e)")
                }
            default: fatal("Unknown keys to sync (\(keys))")
            }

            return request
        } else {
            fatal("Called requestForUpdatingObject() on \(managedObject) to sync keys: \(keys)")
        }
    }

    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?, apiVersion: APIVersion) -> ZMUpstreamRequest? {
        guard let client = managedObject as? UserClient else { fatal("Called requestForInsertingObject() on \(managedObject.safeForLoggingDescription)") }
        return try? requestsFactory.registerClientRequest(
                client,
                credentials: clientRegistrationStatus?.emailCredentials,
                cookieLabel: CookieLabel.current.value,
                apiVersion: apiVersion
            )
    }

    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {
        if keysToParse.contains(ZMUserClientNumberOfKeysRemainingKey) {
            return false
        }
        if keysToParse.contains(ZMUserClientNeedsToUpdateSignalingKeysKey) {
            if response.httpStatus == 400, let label = response.payloadLabel(), label == "bad-request" {
                // Malformed prekeys uploaded - recreate and retry once per launch

                if didRetryRegisteringSignalingKeys {
                    (managedObject as? UserClient)?.needsToUploadSignalingKeys = false
                    managedObjectContext?.saveOrRollback()
                    fatal("UserClientTranscoder sigKey request failed with bad-request - \(upstreamRequest.transportRequest.safeForLoggingDescription)")
                }
                didRetryRegisteringSignalingKeys = true
                return true
            }
            (managedObject as? UserClient)?.needsToUploadSignalingKeys = false
            return false
        }
        if keysToParse.contains(ZMUserClientNeedsToUpdateCapabilitiesKey) {
            if response.httpStatus == 400, let label = response.payloadLabel(), label == "bad-request" {

                if didRetryUpdatingCapabilities {
                    (managedObject as? UserClient)?.needsToUpdateCapabilities = false
                    managedObjectContext?.saveOrRollback()
                    fatal("UserClientTranscoder PUT Capabilities request failed with bad-request - \(upstreamRequest.transportRequest.safeForLoggingDescription)")
                }
                didRetryUpdatingCapabilities = true
                return true
            }
            (managedObject as? UserClient)?.needsToUpdateCapabilities = false
            return false
        } else if keysToParse.contains(ZMUserClientMarkedToDeleteKey) {
            let error = self.errorFromFailedDeleteResponse(response)
            if error.code == ClientUpdateError.clientToDeleteNotFound.rawValue {
                self.managedObjectContext?.delete(managedObject)
                self.managedObjectContext?.saveOrRollback()
            }
            clientUpdateStatus?.failedToDeleteClient(managedObject as! UserClient, error: error)
            return false
        } else {
            // first we try to register without password (credentials can be there, but they can not contain password)
            // if there is no password in credentials but it's required, we will recieve error from backend and only then will ask for password
            let error = errorFromFailedInsertResponse(response)
            if error.code == Int(ZMUserSessionErrorCode.canNotRegisterMoreClients.rawValue) {
                clientUpdateStatus?.needsToFetchClients(andVerifySelfClient: false)
            }
            clientRegistrationStatus?.didFail(toRegisterClient: error)
            return true
        }
    }

    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        if let client = managedObject as? UserClient {

            guard
                let payload = response.payload as? [String: AnyObject],
                let remoteIdentifier = payload["id"] as? String
            else {
                zmLog.warn("Unexpected backend response for inserted client")
                return
            }

            client.remoteIdentifier = remoteIdentifier
            client.numberOfKeysRemaining = Int32(requestsFactory.keyCount)
            guard let moc = self.managedObjectContext else { return }
            _ = UserClient.createOrUpdateSelfUserClient(payload, context: moc)
            clientRegistrationStatus?.didRegister(client)
        } else {
            fatal("Called updateInsertedObject() on \(managedObject.safeForLoggingDescription)")
        }
    }

    public func errorFromFailedDeleteResponse(_ response: ZMTransportResponse!) -> NSError {
        var errorCode: ClientUpdateError = .none
        if let response = response, response.result == .permanentError {
            if let errorLabel = response.payload?.asDictionary()?["label"] as? String {
                switch errorLabel {
                case "client-not-found":
                    errorCode = .clientToDeleteNotFound
                case "invalid-credentials",
                     "missing-auth",
                     // in case the password not matching password format requirement
                     "bad-request":
                    errorCode = .invalidCredentials
                default:
                    break
                }
            }
        }
        return ClientUpdateError.errorForType(errorCode)()
    }

    public func errorFromFailedInsertResponse(_ response: ZMTransportResponse!) -> NSError {
        var errorCode: ZMUserSessionErrorCode = .unknownError
        if let moc = self.managedObjectContext, let response = response, response.result == .permanentError {

            if let errorLabel = response.payload?.asDictionary()?["label"] as? String {
                switch errorLabel {
                case "missing-auth":
                    if let emailAddress = ZMUser.selfUser(in: moc).emailAddress, !emailAddress.isEmpty {
                        errorCode = .needsPasswordToRegisterClient
                    } else {
                        errorCode = .invalidCredentials
                    }
                case "too-many-clients":
                    errorCode = .canNotRegisterMoreClients
                case "invalid-credentials",
                    "code-authentication-failed",
                    "code-authentication-required":
                    errorCode = .invalidCredentials
                default:
                    break
                }
            }
        }
        return NSError(domain: NSError.ZMUserSessionErrorDomain, code: Int(errorCode.rawValue), userInfo: nil)
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {

        switch response.result {
        case .success:
            if let payload = response.payload?.asArray() as? [[String: AnyObject]] {
                self.received(clients: payload)
            }
        case .expired:
            clientUpdateStatus?.failedToFetchClients()
        default:
            break
        }
    }

    private func received(clients: [[String: AnyObject]]) {
        guard let moc = self.managedObjectContext else { return }
        func createSelfUserClient(_ clientInfo: [String: AnyObject]) -> UserClient? {
            let client = UserClient.createOrUpdateSelfUserClient(clientInfo, context: moc)
            return client
        }

        let clients = clients.compactMap(createSelfUserClient)

        // remove all clients that are not there, with the exception of the self client
        // in theory we should also remove the self client and log out, but this will happen
        // next time the user sends a message or when we will receive the "deleted" event
        // for that client
        let foundClientsIdentifier = Set(clients.compactMap { $0.remoteIdentifier })
        let selfUser = ZMUser.selfUser(in: moc)
        let selfClient = selfUser.selfClient()
        let otherClients = selfUser.clients

        otherClients.forEach {
            guard $0 != selfClient, // not current client
                let identifier = $0.remoteIdentifier, // has remote ID
                !foundClientsIdentifier.contains(identifier) // not in the list of found ones
                else {
                return
            }
            // not there? delete
            $0.deleteClientAndEndSession()
        }

        moc.saveOrRollback()
        clientUpdateStatus?.didFetchClients(clients)
    }

    /// Returns whether synchronization of this object needs additional requests
    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable: Any]?, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {

        if keysToParse.contains(ZMUserClientMarkedToDeleteKey) {
            return processResponseForDeletingClients(managedObject, requestUserInfo: requestUserInfo, responsePayload: response.payload)
        } else if keysToParse.contains(ZMUserClientNumberOfKeysRemainingKey) {
            (managedObject as! UserClient).numberOfKeysRemaining += Int32(requestsFactory.keyCount)
        } else if keysToParse.contains(ZMUserClientNeedsToUpdateSignalingKeysKey) {
            didRetryRegisteringSignalingKeys = false
        } else if keysToParse.contains(ZMUserClientNeedsToUpdateCapabilitiesKey) {
            didRetryUpdatingCapabilities = false
        }

        return false
    }

    func processResponseForDeletingClients(_ managedObject: ZMManagedObject!, requestUserInfo: [AnyHashable: Any]!, responsePayload payload: ZMTransportData!) -> Bool {
        // is it safe for ui??
        if let client = managedObject as? UserClient {
            managedObject.managedObjectContext?.performGroupedBlock({ () -> Void in
                // end session and delete client
                client.deleteClientAndEndSession()
                // notify the clientStatus
                self.clientUpdateStatus?.didDeleteClient()
            })
        }
        return false
    }

    // Should return the objects that need to be refetched from the BE in case of upload error
    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        // Events are processed by the UserClientEventConsumer
    }

}
