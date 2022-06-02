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

public enum ClientUpdatePhase {
    case done
    case fetchingClients
    case deletingClients
}

let ClientUpdateErrorDomain = "ClientManagement"

@objc
public enum ClientUpdateError: NSInteger {
    case none
    case selfClientIsInvalid
    case invalidCredentials
    case deviceIsOffline
    case clientToDeleteNotFound

    func errorForType() -> NSError {
        return NSError(domain: ClientUpdateErrorDomain, code: self.rawValue, userInfo: nil)
    }
}

@objcMembers open class ClientUpdateStatus: NSObject {

    var syncManagedObjectContext: NSManagedObjectContext

    fileprivate var isFetchingClients = false
    fileprivate var isWaitingToDeleteClients = false
    fileprivate var needsToVerifySelfClient = false
    fileprivate var internalCredentials: ZMEmailCredentials?

    open var credentials: ZMEmailCredentials? {
        return internalCredentials
    }

    public init(syncManagedObjectContext: NSManagedObjectContext) {
        self.syncManagedObjectContext = syncManagedObjectContext
        super.init()

        let hasSelfClient = !ZMClientRegistrationStatus.needsToRegisterClient(in: self.syncManagedObjectContext)

        needsToFetchClients(andVerifySelfClient: hasSelfClient)

        // check if we are already trying to delete the client
        if let selfUser = ZMUser.selfUser(in: syncManagedObjectContext).selfClient(), selfUser.markedToDelete {
            // This recovers from the bug where we think we should delete the self cient.
            // See: https://wearezeta.atlassian.net/browse/ZIOS-6646
            // This code can be removed and possibly moved to a hotfix once all paths that lead to the bug
            // have been discovered
            selfUser.markedToDelete = false
            let userClientMarkedToDeleteKeysSet: Set<AnyHashable> = [ZMUserClientMarkedToDeleteKey]
            selfUser.resetLocallyModifiedKeys(userClientMarkedToDeleteKeysSet)
        }
    }

    open var currentPhase: ClientUpdatePhase {
        if isFetchingClients {
            return .fetchingClients
        }
        if isWaitingToDeleteClients {
            return .deletingClients
        }
        return .done
    }

    public func needsToFetchClients(andVerifySelfClient verifySelfClient: Bool) {
        isFetchingClients = true

        // there are three cases in which this method is called
        // (1) when not registered - we try to register a device but there are too many devices registered
        // (2) when registered - we want to manage our registered devices from the settings screen
        // (3) when registered - we want to verify the selfClient on startup
        // we only want to verify the selfClient when we are already registered
        needsToVerifySelfClient = verifySelfClient
    }

    open func didFetchClients(_ clients: [UserClient]) {
        if isFetchingClients {
            isFetchingClients = false
            var excludingSelfClient = clients
            if needsToVerifySelfClient {
                do {
                    excludingSelfClient = try filterSelfClientIfValid(excludingSelfClient)
                    ZMClientUpdateNotification.notifyFetchingClientsCompleted(userClients: excludingSelfClient, context: syncManagedObjectContext)
                } catch let error as NSError {
                    ZMClientUpdateNotification.notifyFetchingClientsDidFail(error: error, context: syncManagedObjectContext)
                }
            } else {
                ZMClientUpdateNotification.notifyFetchingClientsCompleted(userClients: clients, context: syncManagedObjectContext)
            }
        }
    }

    func filterSelfClientIfValid(_ clients: [UserClient]) throws -> [UserClient] {
        guard let selfClient = ZMUser.selfUser(in: self.syncManagedObjectContext).selfClient()
        else {
            throw ClientUpdateError.errorForType(.selfClientIsInvalid)()
        }
        var error: NSError?
        var excludingSelfClient: [UserClient] = []

        var didContainSelf = false
        excludingSelfClient = clients.filter {
            if $0.remoteIdentifier != selfClient.remoteIdentifier {
                return true
            }
            didContainSelf = true
            return false
        }
        if !didContainSelf {
            // the selfClient was removed by an other user
            error = ClientUpdateError.errorForType(.selfClientIsInvalid)()
            excludingSelfClient = []
        }

        if let error = error {
            throw error
        }
        return excludingSelfClient
    }

    public func failedToFetchClients() {
        if isFetchingClients {
            let error = ClientUpdateError.errorForType(.deviceIsOffline)()
            ZMClientUpdateNotification.notifyFetchingClientsDidFail(error: error, context: syncManagedObjectContext)
        }
    }

    public func deleteClients(withCredentials emailCredentials: ZMEmailCredentials?) {
        isWaitingToDeleteClients = true
        internalCredentials = emailCredentials
    }

    public func failedToDeleteClient(_ client: UserClient, error: NSError) {
        if !isWaitingToDeleteClients {
            return
        }
        if let errorCode = ClientUpdateError(rawValue: error.code), error.domain == ClientUpdateErrorDomain {
            if  errorCode == .clientToDeleteNotFound {
                // the client existed locally but not remotely, we delete it locally (done by the transcoder)
                // this should not happen since we just fetched the clients
                // however if it happens and there is no other client to delete we should notify that all clients where deleted
                internalCredentials = nil
                ZMClientUpdateNotification.notifyDeletionCompleted(remainingClients: selfUserClientsExcludingSelfClient, context: syncManagedObjectContext)
            } else if  errorCode == .invalidCredentials {
                isWaitingToDeleteClients = false
                internalCredentials = nil
                ZMClientUpdateNotification.notifyDeletionFailed(error: error, context: syncManagedObjectContext)
            }
        }
    }

    public func didDetectCurrentClientDeletion() {
        needsToVerifySelfClient = false
    }

    open func didDeleteClient() {
        if isWaitingToDeleteClients {
            isWaitingToDeleteClients = false
            internalCredentials = nil
            ZMClientUpdateNotification.notifyDeletionCompleted(remainingClients: selfUserClientsExcludingSelfClient, context: syncManagedObjectContext)
        }
    }

    var selfUserClientsExcludingSelfClient: [UserClient] {
        let selfUser = ZMUser.selfUser(in: self.syncManagedObjectContext)
        let selfClient = selfUser.selfClient()
        let remainingClients = selfUser.clients.filter {$0 != selfClient && !$0.isZombieObject}
        return Array(remainingClients)
    }
}
