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

extension Payload.UserClient {

    func update(_ client: WireDataModel.UserClient) {
        client.needsToBeUpdatedFromBackend = false

        guard
            client.user?.isSelfUser == false,
            let deviceClass = deviceClass
        else { return }

        client.deviceClass = DeviceClass(rawValue: deviceClass)
    }

    func createOrUpdateClient(for user: ZMUser) -> WireDataModel.UserClient {
        let client = WireDataModel.UserClient.fetchUserClient(withRemoteId: id, forUser: user, createIfNeeded: true)!

        update(client)

        return client
    }

}

extension Array where Array.Element == Payload.UserClient {

    func updateClients(for user: ZMUser, selfClient: UserClient) {
        let clients: [UserClient] = map { $0.createOrUpdateClient(for: user) }

        // Remove clients that have not been included in the response
        let deletedClients = user.clients.subtracting(clients)
        deletedClients.forEach {
            $0.deleteClientAndEndSession()
        }

        // Mark new clients as missed and ignore them
        let newClients = Set(clients.filter({ $0.isInserted || !$0.hasSessionWithSelfClient }))
        selfClient.missesClients(newClients)
        selfClient.addNewClientsToIgnored(newClients)
        selfClient.updateSecurityLevelAfterDiscovering(newClients)
    }

}

// MARK: - Prekeys

extension Payload.PrekeyByUserID {

    /// Establish new sessions using the prekeys retreived for each client.
    ///
    /// - parameter selfClient: The self user's client
    /// - parameter context: The `NSManagedObjectContext` on which the operation should be performed
    /// - parameter domain: originating domain of the clients.
    ///
    /// - returns `True` if there's more sessions which needs to be established.
    func establishSessions(with selfClient: UserClient,
                           context: NSManagedObjectContext,
                           domain: String? = nil) -> Bool {
        for (userID, prekeyByClientID) in self {
            for (clientID, prekey) in prekeyByClientID {
                guard
                    let userID = UUID(uuidString: userID),
                    let user = ZMUser.fetch(with: userID, domain: domain, in: context),
                    let missingClient = UserClient.fetchUserClient(withRemoteId: clientID,
                                                                   forUser: user,
                                                                   createIfNeeded: true)
                else {
                    continue
                }

                if let prekey = prekey {
                    missingClient.establishSessionAndUpdateMissingClients(prekey: prekey,
                                                                          selfClient: selfClient)
                } else {
                    missingClient.markClientAsInvalidAfterFailingToRetrievePrekey(selfClient: selfClient)
                }

            }
        }

        let hasMoreMissingClients = (selfClient.missingClients?.count ?? 0) > 0

        return hasMoreMissingClients
    }

}

extension Payload.PrekeyByQualifiedUserID {

    /// Establish new sessions using the prekeys retreived for each client.
    ///
    /// - parameter selfClient: The self user's client
    /// - parameter context: The `NSManagedObjectContext` on which the operation should be performed
    ///
    /// - returns `True` if there's more sessions which needs to be established.
    func establishSessions(with selfClient: UserClient, context: NSManagedObjectContext) -> Bool {
        for (domain, prekeyByUserID) in self {
            _ = prekeyByUserID.establishSessions(with: selfClient, context: context, domain: domain)
        }

        let hasMoreMissingClients = selfClient.missingClients?.isEmpty == false

        return hasMoreMissingClients
    }

}

// MARK: - UserClient

extension UserClient {

    /// Creates session and update missing clients and messages that depend on those clients
    fileprivate func establishSessionAndUpdateMissingClients(prekey: Payload.Prekey,
                                                             selfClient: UserClient) {

        let sessionCreated = selfClient.establishSessionWithClient(self,
                                                                   usingPreKey: prekey.key)

       // If the session creation failed, the client probably has corrupted prekeys,
       // we mark the client in order to send him a bogus message and not block all requests
       failedToEstablishSession = !sessionCreated
       clearMessagesMissingRecipient()
       selfClient.removeMissingClient(self)
   }

    fileprivate func markClientAsInvalidAfterFailingToRetrievePrekey(selfClient: UserClient) {
        failedToEstablishSession = true
        clearMessagesMissingRecipient()
        selfClient.removeMissingClient(self)
    }

    fileprivate func clearMessagesMissingRecipient() {
        messagesMissingRecipient.forEach {
            if let message = $0 as? ZMOTRMessage {
                message.doesNotMissRecipient(self)
            } else {
                mutableSetValue(forKey: "messagesMissingRecipient").remove($0)
            }
        }
    }

}

extension Payload.ClientListByQualifiedUserID {

    func fetchUsers(in context: NSManagedObjectContext) -> [ZMUser] {
        return flatMap { (domain, userClientsByUserID) in
            return userClientsByUserID.compactMap { (userID, _) -> ZMUser? in
                guard
                    let userID = UUID(uuidString: userID),
                    let user = ZMUser.fetch(with: userID, domain: domain, in: context)
                else {
                    return nil
                }

                return user
            }
        }
    }

    func fetchClients(in context: NSManagedObjectContext) -> [ZMUser: [UserClient]] {
        let userClientsByUserTuples = flatMap { (domain, userClientsByUserID) in
            return userClientsByUserID.compactMap { (userID, userClientIDs) -> [ZMUser: [UserClient]]? in
                guard
                    let userID = UUID(uuidString: userID),
                    let user = ZMUser.fetch(with: userID, domain: domain, in: context)
                else {
                    return nil
                }

                let userClients = user.clients.filter({
                    guard let clientID = $0.remoteIdentifier else { return false }
                    return userClientIDs.contains(clientID)
                })

                return [user: Array(userClients)]
            }
        }.flatMap { $0 }

        return [ZMUser: [UserClient]](userClientsByUserTuples, uniquingKeysWith: +)
    }

    func fetchOrCreateClients(in context: NSManagedObjectContext) -> [ZMUser: [UserClient]] {
        let userClientsByUserTuples = flatMap { (domain, userClientsByUserID) in
            return userClientsByUserID.compactMap { (userID, userClientIDs) -> [ZMUser: [UserClient]]? in
                guard
                    let userID = UUID(uuidString: userID)
                else {
                    return nil
                }

                let user = ZMUser.fetchOrCreate(with: userID, domain: domain, in: context)
                let userClients = userClientIDs.compactMap { (clientID) -> UserClient? in
                    guard
                        let userClient = UserClient.fetchUserClient(withRemoteId: clientID,
                                                                    forUser: user,
                                                                    createIfNeeded: true),
                        !userClient.hasSessionWithSelfClient
                    else {
                        return nil
                    }
                    return userClient
                }

                return [user: userClients]
            }
        }.flatMap { $0 }

        return [ZMUser: [UserClient]](userClientsByUserTuples, uniquingKeysWith: +)
    }

}
