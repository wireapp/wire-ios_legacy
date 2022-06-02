//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension ZMConversation {
    @objc public static let defaultAdminRoleName = "wire_admin"
    @objc public static let defaultMemberRoleName = "wire_member"

    static func predicateSecureWithIgnored() -> NSPredicate {
        return NSPredicate(format: "%K == %d", #keyPath(ZMConversation.securityLevel), ZMConversationSecurityLevel.secureWithIgnored.rawValue)
    }

    /// After changes to conversation security degradation logic we need
    /// to migrate all conversations from .secureWithIgnored to .notSecure
    /// so that users wouldn't get degratation prompts to conversations that 
    /// at any point in the past had been secure
    static func migrateAllSecureWithIgnored(in moc: NSManagedObjectContext) {
        let predicate = ZMConversation.predicateSecureWithIgnored()

        let request = ZMConversation.sortedFetchRequest(with: predicate)

        guard let allConversations = moc.fetchOrAssert(request: request) as? [ZMConversation] else {
            fatal("fetchOrAssert failed")
        }

        for conversation in allConversations {
            conversation.securityLevel = .notSecure
        }
    }

    // Migration rules for the Model version 2.78.0
    static func introduceParticipantRoles(in moc: NSManagedObjectContext) {
        migrateUsersToParticipants(in: moc)
        migrateIsSelfAnActiveMemberToTheParticipantRoles(in: moc)
        addUserFromTheConnectionToTheParticipantRoles(in: moc)
        forceToFetchConversationRoles(in: moc)
    }

    // Model version 2.78.0 adds a `participantRoles` attribute to the `Conversation` entity.
    // The set should contain the self user if 'isSelfAnActiveMember' is true.
    static func migrateIsSelfAnActiveMemberToTheParticipantRoles(in moc: NSManagedObjectContext) {
        let selfUser = ZMUser.selfUser(in: moc)

        let request = ZMConversation.sortedFetchRequest()

        guard let allConversations = moc.fetchOrAssert(request: request) as? [ZMConversation] else {
            fatal("fetchOrAssert failed")
        }

        for conversation in allConversations {

            let oldKey = "isSelfAnActiveMember"
            conversation.willAccessValue(forKey: oldKey)
            let isSelfAnActiveMember = (conversation.primitiveValue(forKey: oldKey) as! NSNumber).boolValue
            conversation.didAccessValue(forKey: oldKey)

            if isSelfAnActiveMember {
                var participantRoleForSelfUser: ParticipantRole
                let adminRole = conversation.getRoles().first(where: {$0.name == defaultAdminRoleName})

                if let conversationTeam = conversation.team, conversationTeam == selfUser.team, selfUser.isTeamMember {
                    participantRoleForSelfUser = getAParticipantRole(in: moc, adminRole: adminRole, user: selfUser, conversation: conversation, team: conversationTeam)
                } else {
                    participantRoleForSelfUser = getAParticipantRole(in: moc, adminRole: adminRole, user: selfUser, conversation: conversation, team: nil)
                }
                conversation.participantRoles.insert(participantRoleForSelfUser)
            }
        }
    }

    static private func getAParticipantRole(in moc: NSManagedObjectContext, adminRole: Role?, user: ZMUser, conversation: ZMConversation, team: Team?) -> ParticipantRole {
        let participantRoleForUser = ParticipantRole.create(managedObjectContext: moc, user: user, conversation: conversation)
        let customRole = Role.fetchOrCreateRole(with: defaultAdminRoleName, teamOrConversation: team != nil ? .team(team!) : .conversation(conversation), in: moc)

        if let adminRole = adminRole {
            participantRoleForUser.role = adminRole
        } else {
            participantRoleForUser.role = customRole
        }
        return participantRoleForUser
    }

    // Model version 2.78.0 adds a `participantRoles` attribute to the `Conversation` entity.
    // After creating a new connection, we should add user to the participants roles, because we do not get it from the backend.
    static func addUserFromTheConnectionToTheParticipantRoles(in moc: NSManagedObjectContext) {
        guard let allConnections = ZMConnection.connections(inManagedObjectContext: moc) as? [ZMConnection] else { return }

        for connection in allConnections {
            guard let conversation = connection.conversation,
                  let user = connection.to else { continue }

            conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        }
    }

    // Model version 2.78.0 adds a `participantRoles` attribute to the `Conversation` entity,
    // and `Role` to `Team` and `ZMConversation`. All group conversation memberships need to be refetched
    // in order to get which roles the users have. Additionally, we need to download the roles
    // definitions for teams and conversations.
    static func forceToFetchConversationRoles(in moc: NSManagedObjectContext) {

        // Mark group conversation membership to be refetched
        let selfUser = ZMUser.selfUser(in: moc)

        let groupConversationsFetch = ZMConversation.sortedFetchRequest(
            with: NSPredicate(format: "%K == %d",
                              ZMConversationConversationTypeKey,
                              ZMConversationType.group.rawValue))

        guard let conversations = moc.fetchOrAssert(request: groupConversationsFetch) as? [ZMConversation] else {
                fatal("fetchOrAssert failed")
        }

        conversations.forEach {
            guard $0.isSelfAnActiveMember else { return }
            $0.needsToBeUpdatedFromBackend = true
            $0.needsToDownloadRoles = $0.team == nil || $0.team != selfUser.team
        }

        // Mark team as need to download roles
        selfUser.team?.needsToDownloadRoles = true
    }

    // Model version 2.78.0 adds a `participantRoles` attribute to the `Conversation` entity, and deprecates the `lastServerSyncedActiveParticipants`.
    // Those need to be migrated to the new relationship
    static func migrateUsersToParticipants(in moc: NSManagedObjectContext) {

        let oldKey = "lastServerSyncedActiveParticipants"

        let request = ZMConversation.sortedFetchRequest()

        guard let conversations = moc.fetchOrAssert(request: request) as? [ZMConversation] else {
                fatal("fetchOrAssert failed")
        }

        conversations.forEach { convo in
            let users = (convo.value(forKey: oldKey) as! NSOrderedSet).array as? [ZMUser]
            users?.forEach { user in
                let participantRole = ParticipantRole.insertNewObject(in: moc)
                participantRole.conversation = convo
                participantRole.user = user
                participantRole.role = nil
            }
            convo.setValue(NSOrderedSet(), forKey: oldKey)
        }
    }
    // Model version add a `accessRoleStringsV2` attribute to the `Conversation` entity. The values from accessRoleString, need to be migrated to the new relationship
    static func forceToFetchConversationAccessRoles(in moc: NSManagedObjectContext) {
        let conversationsToFetch = ZMConversation.fetchRequest()

        guard let conversations = moc.fetchOrAssert(request: conversationsToFetch) as? [ZMConversation] else {
                fatal("fetchOrAssert failed")
        }

        conversations.forEach {
            guard $0.isSelfAnActiveMember else { return }
            $0.needsToBeUpdatedFromBackend = true
        }
    }

    // Migration rules for the Model Version 2.98.0
    static func introduceAccessRoleV2(in moc: NSManagedObjectContext) {
        forceToFetchConversationAccessRoles(in: moc)
    }

}
