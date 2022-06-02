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
import WireTransport

private let zmLog = ZMSLog(tag: "Dependencies")

@objc public protocol OTREntity: DependencyEntity {

    /// NSManagedObjectContext which the OTR entity is associated with.
    var context: NSManagedObjectContext { get }

    /// Conversation in which the OTR entity is sent. If the OTR entity is not associated with
    /// any conversation this property should return nil.
    var conversation: ZMConversation? { get }

    /// Add clients as missing recipients for this entity. If we want to resend
    /// the entity, we need to make sure those missing recipients are fetched
    /// or sending the entity will fail again.
    func missesRecipients(_ recipients: Set<WireDataModel.UserClient>!)

    /// if the BE tells us that these users are not in the
    /// conversation anymore, it means that we are out of sync
    /// with the list of participants
    func detectedRedundantUsers(_ users: [ZMUser])

    func delivered(with response: ZMTransportResponse)

}

/// HTTP status of a request that has
private let ClientNotAuthorizedResponseStatus = 403

/// Label for clients that are missing from the uploaded payload
private let MissingLabel = "missing"

/// Label for clients that were deleted and are still present in the uploaded payload
private let DeletedLabel = "deleted"

/// Label for clients whose user was removed from the conversation but we still think it is in the conversation
private let RedundantLabel = "redundant"

/// Label error for uploading a message with a client that does not exist
private let UnknownClientLabel = "unknown-client"

/// Error label
private let ErrorLabel = "label"

extension OTREntity {

    /// Which object this message depends on when sending
    public func dependentObjectNeedingUpdateBeforeProcessingOTREntity(in conversation: ZMConversation) -> ZMManagedObject? {

        // If we receive a missing payload that includes users that are not part of the conversation,
        // we need to refetch the conversation before recreating the message payload.
        // Otherwise we end up in an endless loop receiving missing clients error
        if conversation.needsToBeUpdatedFromBackend || conversation.needsToVerifyLegalHold {
            zmLog.debug("conversation needs to be update from backend")
            return conversation
        }

        if (conversation.conversationType == .oneOnOne || conversation.conversationType == .connection)
            && conversation.connection?.needsToBeUpdatedFromBackend == true {
            zmLog.debug("connection needs to be update from backend")
            return conversation.connection
        }

        // If the conversation is degraded we shouldn't send the message until the conversation
        // is marked as not secure or it's verified again
        if conversation.securityLevel == .secureWithIgnored {
            zmLog.debug("conversations has security level ignored")
            return conversation
        }

        return dependentObjectNeedingUpdateBeforeProcessingOTREntity(recipients: conversation.localParticipants)
    }

    /// Which objects this message depends on when sending it to a list recipients
    public func dependentObjectNeedingUpdateBeforeProcessingOTREntity(recipients: Set<ZMUser>) -> ZMManagedObject? {
        let recipientClients = recipients.flatMap {
            return Array($0.clients)
        }

        // If we discovered a new client we need fetch the client details before retrying
        if let newClient = recipientClients.first(where: { $0.needsToBeUpdatedFromBackend }) {
            return newClient
        }

        // If we are missing clients, we need to refetch the clients before retrying
        if let selfClient = ZMUser.selfUser(in: context).selfClient(),
           let missingClients = selfClient.missingClients, missingClients.count > 0 {
            // Don't block sending of messages if they are not affected by the missing clients
            if !missingClients.isDisjoint(with: recipientClients) {

                // make sure that we fetch those clients, even if we somehow gave up on fetching them
                if !(selfClient.modifiedKeys?.contains(ZMUserClientMissingKey) ?? false) {
                    let userClientMissingKeySet: Set<AnyHashable> = [ZMUserClientMissingKey]
                    selfClient.setLocallyModifiedKeys(userClientMissingKeySet)
                    context.enqueueDelayedSave()
                }
                return selfClient
            }
        }

        return nil
    }

    func processEmptyUploadResponse(_ response: ZMTransportResponse, in conversation: ZMConversation, clientRegistrationDelegate: ClientRegistrationDelegate) -> ZMConversationRemoteClientChangeSet {
        guard !detectedDeletedSelfClient(in: response) else {
            clientRegistrationDelegate.didDetectCurrentClientDeletion()
            return [.deleted]
        }

        guard let apiVersion = APIVersion(rawValue: response.apiVersion) else {
            return []
        }

        var clientListByUser = Payload.ClientListByUser()
        switch apiVersion {
        case .v0:
            guard
                let payload = response.payload as? [String: AnyObject],
                let clientListByUserID = payload[MissingLabel] as? Payload.ClientListByUserID
            else {
                return []
            }
            clientListByUser = clientListByUserID.materializingUsers(withDomain: nil, in: context)
        case .v1:
            guard let payload = Payload.MessageSendingStatus(response) else {
                return []
            }
            clientListByUser = payload.missingClientListByUser(context: context)
        }

        return parseMissingClients(clientListByUser, in: conversation)
    }

    private func parseMissingClients(_ clientListByUser: Payload.ClientListByUser, in conversation: ZMConversation) -> ZMConversationRemoteClientChangeSet {
        // 1) Parse the payload

        var changes: ZMConversationRemoteClientChangeSet = []
        var allMissingClients: Set<UserClient> = []
        var redundantUsers = conversation.localParticipants

        redundantUsers.remove(ZMUser.selfUser(in: context))

        for (user, remoteClientIdentifiers) in clientListByUser {
            if user.isSelfUser { continue }

            redundantUsers.remove(user)

            let remoteIdentifiers = Set(remoteClientIdentifiers)
            let localIdentifiers = Set(user.clients.compactMap(\.remoteIdentifier))

            // Compute changes
            let deletedClients = localIdentifiers.subtracting(remoteIdentifiers)
            if !deletedClients.isEmpty { changes.insert(.deleted) }

            let missingClients = remoteIdentifiers.subtracting(localIdentifiers)
            if !missingClients.isEmpty { changes.insert(.missing) }

            // Process deletions
            for deletedClientID in deletedClients {
                if let client = UserClient.fetchUserClient(withRemoteId: deletedClientID, forUser: user, createIfNeeded: false) {
                    client.deleteClientAndEndSession()
                }
            }

            // Process missing clients
            let userMissingClients: [UserClient] = missingClients.map {
                let client = UserClient.fetchUserClient(withRemoteId: $0, forUser: user, createIfNeeded: true)!
                client.discoveredByMessage = self as? ZMOTRMessage
                return client
            }

            if !userMissingClients.isEmpty {
                allMissingClients.formUnion(userMissingClients)
            }
        }

        for redundantUser in redundantUsers {
            // Users no longer present in the list of missing clients are either no longer in the group
            // or have deleted all their clients. Both cases are edges cases which should only happen
            // after missing events.
            redundantUser.clients.forEach({ $0.deleteClientAndEndSession() })
        }

        registersNewMissingClients(allMissingClients)

        return changes
    }

    /// Parse the response to an upload, that will inform us of missing, deleted and redundant clients
    public func parseUploadResponse(_ response: ZMTransportResponse, clientRegistrationDelegate: ClientRegistrationDelegate) -> ZMConversationRemoteClientChangeSet {
        guard !detectedDeletedSelfClient(in: response) else {
            clientRegistrationDelegate.didDetectCurrentClientDeletion()
            return [.deleted]
        }

        var changes: ZMConversationRemoteClientChangeSet = []

        guard let payload = response.payload as? [String: AnyObject] else { return changes }

        if let deletedMap = payload[DeletedLabel] as? [String: AnyObject] {
            if self.processDeletedClients(deletedMap) {
                changes.insert(.deleted)
            }
        }

        if let redundantMap = payload[RedundantLabel] as? [String: AnyObject] {
            if processRedundantClients(redundantMap) {
                changes.insert(.redundant)
            }
        }

        if let missingMap = payload[MissingLabel] as? [String: AnyObject] {
            if self.processMissingClients(missingMap) {
                changes.insert(.missing)
            }
        }

        return changes
    }

    private func detectedDeletedSelfClient(in response: ZMTransportResponse) -> Bool {
        // In case the self client got deleted remotely we will receive an event through the push channel and log out.
        // If we for some reason miss the push the BE will repond with a 403 and 'unknown-client' label to our
        // next sending attempt and we will logout and delete the current selfClient then
        if response.httpStatus == ClientNotAuthorizedResponseStatus,
            let payload = response.payload as? [String: AnyObject],
            let label = payload[ErrorLabel] as? String,
            label == UnknownClientLabel {
            return true
        } else {
            return false
        }
    }

    /// Parses the "deleted" clients and removes them
    ///
    /// - returns: **True** if there were any deleted users
    fileprivate func processDeletedClients(_ deletedMap: [String: AnyObject]) -> Bool {

        let allDeletedClients = Set(deletedMap.flatMap { pair -> [UserClient] in

            // user
            guard let userID = UUID(uuidString: pair.0) else { return [] }
            guard let user = ZMUser.fetch(with: userID, domain: nil, in: self.context) else { return [] }

            // clients
            guard let clientIDs = pair.1 as? [String] else { fatal("Deleted client ID is not parsed properly") }
            let clientIDsSet = Set(clientIDs)
            return user.clients.filter {
                guard let remoteIdentifier = $0.remoteIdentifier else { return false }
                return clientIDsSet.contains(remoteIdentifier)
            }
        })

        guard !allDeletedClients.isEmpty else {
            return false
        }

        allDeletedClients.forEach {
            $0.deleteClientAndEndSession()
        }

        return true
    }

    /// Parses the "redundant" clients and reports any redundants users.
    ///
    /// - returns: **True** if there were any redundant users
    fileprivate func processRedundantClients(_ redundantMap: [String: AnyObject]) -> Bool {
        let redundantUsers = redundantMap.compactMap { pair -> ZMUser? in
            guard let userID = UUID(uuidString: pair.0) else { return nil }
            let user = ZMUser.fetch(with: userID, domain: nil, in: self.context)!
            return user
        }

        if !redundantUsers.isEmpty {
            // if the BE tells us that these users are not in the
            // conversation anymore, it means that we are out of sync
            // with the list of participants
            conversation?.needsToBeUpdatedFromBackend = true

            // The missing users might have been deleted so we need re-fetch their profiles
            // to verify if that's the case.
            redundantUsers.forEach({ $0.needsToBeUpdatedFromBackend = true })

            detectedRedundantUsers(redundantUsers)
        }

        return !redundantUsers.isEmpty
    }

    /// Parses the "missing" clients and creates the corresponding UserClients, then set them as missing
    ///
    /// - returns: **True** if there were any missing clients
    fileprivate func processMissingClients(_ missingMap: [String: AnyObject]) -> Bool {

        let allMissingClients = Set(missingMap.flatMap { pair -> [UserClient] in

            // user
            guard let userID = UUID(uuidString: pair.0) else { return [] }
            let user = ZMUser.fetchOrCreate(with: userID, domain: nil, in: self.context)

            // client
            guard let clientIDs = pair.1 as? [String] else { fatal("Missing client ID is not parsed properly") }
            let clients: [UserClient] = clientIDs.compactMap {
                guard
                    let client = UserClient.fetchUserClient(withRemoteId: $0, forUser: user, createIfNeeded: true),
                    !client.hasSessionWithSelfClient
                else {
                    return nil
                }

                client.discoveredByMessage = self as? ZMOTRMessage
                return client
            }

            // is this user not there?
            conversation?.addParticipantAndSystemMessageIfMissing(user, date: nil)

            return clients
        })

        self.registersNewMissingClients(allMissingClients)
        return allMissingClients.count > 0
    }

    /// Adds clients to those missing for this message
    func registersNewMissingClients(_ missingClients: Set<UserClient>) {
        guard missingClients.count > 0 else { return }

        let selfClient = ZMUser.selfUser(in: self.context).selfClient()!
        selfClient.missesClients(missingClients)
        self.missesRecipients(missingClients)

        selfClient.addNewClientsToIgnored(missingClients)

    }

}
