//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireProtos

public enum ConversationRemoveParticipantError: Error {
   case unknown,
        invalidOperation,
        conversationNotFound
}

public enum ConversationAddParticipantsError: Error {
   case unknown,
        invalidOperation,
        accessDenied,
        notConnectedToUser,
        conversationNotFound,
        tooManyMembers,
        missingLegalHoldConsent
}

public class AddParticipantAction: EntityAction {
    public var resultHandler: ResultHandler?

    public typealias Result = Void
    public typealias Failure = ConversationAddParticipantsError

    public let userIDs: [NSManagedObjectID]
    public let conversationID: NSManagedObjectID

    public required init(users: [ZMUser], conversation: ZMConversation) {
        userIDs = users.map(\.objectID)
        conversationID = conversation.objectID
    }
}

public class RemoveParticipantAction: EntityAction {
    public var resultHandler: ResultHandler?

    public typealias Result = Void
    public typealias Failure = ConversationRemoveParticipantError

    public let userID: NSManagedObjectID
    public let conversationID: NSManagedObjectID

    public required init(user: ZMUser, conversation: ZMConversation) {
        userID = user.objectID
        conversationID = conversation.objectID
    }
}

extension ZMConversation {

    func sortedUsers(_ users: Set<ZMUser>) -> [ZMUser] {
        let nameDescriptor = NSSortDescriptor(key: "normalizedName", ascending: true)
        let sortedUser = (users as NSSet?)?.sortedArray(using: [nameDescriptor]) as? [ZMUser]

        return sortedUser ?? []
    }

    @objc public var sortedActiveParticipants: [ZMUser] {
        return sortedUsers(localParticipants)
    }

    /// Whether the roles defined for this conversation should be re-downloaded
    @NSManaged public var needsToDownloadRoles: Bool

    @objc
    public var isSelfAnActiveMember: Bool {
        return self.participantRoles.contains(where: { (role) -> Bool in
            role.user?.isSelfUser == true
        })
    }
    // MARK: - keyPathsForValuesAffecting

    static var participantRolesKeys: [String] {
        return [#keyPath(ZMConversation.participantRoles)]
    }

    @objc
    public class func keyPathsForValuesAffectingActiveParticipants() -> Set<String> {
        return Set(participantRolesKeys)
    }

    @objc
    public class func keyPathsForValuesAffectingLocalParticipants() -> Set<String> {
        return Set(participantRolesKeys)
    }

    @objc
    public class func keyPathsForValuesAffectingLocalParticipantRoles() -> Set<String> {
        return Set(participantRolesKeys + [#keyPath(ZMConversation.participantRoles.role)])
    }

    @objc
    public class func keyPathsForValuesAffectingDisplayName() -> Set<String> {
        return Set([ZMConversationConversationTypeKey,
                    "participantRoles.user.name",
                    "connection.to.name",
                    "connection.to.availability",
                    ZMConversationUserDefinedNameKey] +
                   ZMConversation.participantRolesKeys)
    }

    @objc
    public class func keyPathsForValuesAffectingLocalParticipantsExcludingSelf() -> Set<String> {
        return Set(ZMConversation.participantRolesKeys)
    }

    // MARK: - Participant actions

    public func addParticipants(_ participants: [UserType],
                                completion: @escaping AddParticipantAction.ResultHandler) {
        guard
            let context = managedObjectContext
        else {
            return completion(.failure(ConversationAddParticipantsError.unknown))
        }

        let users = participants.materialize(in: context)

        guard
            conversationType == .group,
            !users.isEmpty,
            !users.contains(ZMUser.selfUser(in: context))
        else {
            return completion(.failure(ConversationAddParticipantsError.invalidOperation))
        }

        var action = AddParticipantAction(users: users, conversation: self)
        action.onResult(resultHandler: completion)
        action.send(in: context.notificationContext)
    }

    public func removeParticipant(_ participant: UserType,
                                  completion: @escaping RemoveParticipantAction.ResultHandler) {
        guard
            let context = managedObjectContext
        else {
            return completion(.failure(ConversationRemoveParticipantError.unknown))
        }

        guard
            conversationType == .group,
            let user = participant as? ZMUser
        else {
            return completion(.failure(ConversationRemoveParticipantError.invalidOperation))
        }

        var action = RemoveParticipantAction(user: user, conversation: self)
        action.onResult(resultHandler: completion)
        action.send(in: context.notificationContext)
    }

    // MARK: - Participants methods

    /// Participants that are in the conversation, according to the local state,
    /// even if that state is not yet synchronized with the backend
    @objc
    public var localParticipantRoles: Set<ParticipantRole> {
        return participantRoles
    }

    /// Participants that are in the conversation, according to the local state
    /// even if that state is not yet synchronized with the backend
    @objc
    public var localParticipants: Set<ZMUser> {
        return Set(localParticipantRoles.compactMap { $0.user })
    }

    /// Participants that are in the conversation, according to the local state
    /// even if that state is not yet synchronized with the backend

    @objc
    public var localParticipantsExcludingSelf: Set<ZMUser> {
        return self.localParticipants.filter { !$0.isSelfUser }
    }

    // MARK: - Participant operations

    /// Add participants to the conversation. The method will decide on its own whether
    /// this operation need to be synchronized to the backend or not based on the current context.
    /// If the operation is executed from the UI context, then the operation will be synchronized.
    /// If the operation is executed from the sync context, then the operation will not be synchronized.
    ///
    /// The method will handle the case when the participant is already there, so it's safe to call
    /// it multiple time for the same user. It will update the role if the user is already there with
    /// a different role.
    ///
    /// The method will also check if the addition of the users will change the verification status, the archive
    /// status, etc.
    @objc
    public func addParticipantAndUpdateConversationState(user: ZMUser, role: Role?) {
        self.addParticipantsAndUpdateConversationState(usersAndRoles: [(user, role)])
    }

    /// Add participants to the conversation. The method will decide on its own whether
    /// this operation need to be synchronized to the backend or not based on the current context.
    /// If the operation is executed from the UI context, then the operation will be synchronized.
    /// If the operation is executed from the sync context, then the operation will not be synchronized.
    ///
    /// The method will handle the case when the participant is already there, so it's safe to call
    /// it multiple time for the same user. It will update the role if the user is already there with
    /// a different role.
    ///
    /// The method will also check if the addition of the users will change the verification status, the archive
    /// status, etc.
    @objc
    public func addParticipantsAndUpdateConversationState(users: Set<ZMUser>, role: Role?) {
        self.addParticipantsAndUpdateConversationState(usersAndRoles: users.map { ($0, role) })
    }

    /// Add participants to the conversation. The method will decide on its own whether
    /// this operation need to be synchronized to the backend or not based on the current context.
    /// If the operation is executed from the UI context, then the operation will be synchronized.
    /// If the operation is executed from the sync context, then the operation will not be synchronized.
    ///
    /// The method will handle the case when the participant is already there, so it's safe to call
    /// it multiple time for the same user. It will update the role if the user is already there with
    /// a different role.
    ///
    /// The method will also check if the addition of the users will change the verification status, the archive
    /// status, etc.
    public func addParticipantsAndUpdateConversationState(usersAndRoles: [(ZMUser, Role?)]) {

        // Is this a new conversation, or an existing one that is being updated?
        let doesExistsOnBackend = self.remoteIdentifier != nil

        let addedRoles = usersAndRoles.compactMap { (user, role) -> ParticipantRole? in
            guard !user.isAccountDeleted else { return nil }

            // make sure the role is the right team/conversation role
            require(
                role == nil || (role!.team == self.team || role!.conversation == self),
                "Tried to add a role that does not belong to the conversation"
            )

            guard let (result, pr) = updateExistingOrCreateParticipantRole(for: user, with: role) else { return nil }
            return (result == .created) ? pr : nil
        }

        let addedSelfUser = doesExistsOnBackend && addedRoles.contains(where: {$0.user?.isSelfUser == true})
        if addedSelfUser {
            self.markToDownloadRolesIfNeeded()
            self.needsToBeUpdatedFromBackend = true
        }

        if !addedRoles.isEmpty {
            self.checkIfArchivedStatusChanged(addedSelfUser: addedSelfUser)
            self.checkIfVerificationLevelChanged(addedUsers: Set(addedRoles.compactMap { $0.user }), addedSelfUser: addedSelfUser)
        }
    }

    private enum FetchOrCreation {
        case fetched
        case created
    }

    // Fetch an existing role or create a new one if needed
    // Returns whether it was created or found
    private func updateExistingOrCreateParticipantRole(for user: ZMUser, with role: Role?) -> (FetchOrCreation, ParticipantRole)? {

        guard let moc = self.managedObjectContext else { return nil }

        // If the user is already there, just change the role
        if let current = self.participantRoles.first(where: {$0.user == user}) {
            if let role = role {
                current.role = role
            }

            return (.fetched, current)

        } else {
            // A new participant role
            let participantRole = ParticipantRole.insertNewObject(in: moc)
            participantRole.conversation = self
            participantRole.user = user
            participantRole.role = role

            return (.created, participantRole)
        }
    }

    private func checkIfArchivedStatusChanged(addedSelfUser: Bool) {
        if addedSelfUser &&
            self.mutedStatus == MutedMessageOptionValue.none.rawValue &&
            self.isArchived {
            self.isArchived = false
        }
    }

    private func checkIfVerificationLevelChanged(addedUsers: Set<ZMUser>, addedSelfUser: Bool) {
        let clients = Set(addedUsers.flatMap { $0.clients })
        self.decreaseSecurityLevelIfNeededAfterDiscovering(clients: clients, causedBy: addedUsers)

        if addedSelfUser {
            self.increaseSecurityLevelIfNeededAfterTrusting(clients: clients)
        }
    }

    /// Remove participants to the conversation. The method will decide on its own whether
    /// this operation need to be synchronized to the backend or not based on the current context.
    /// If the operation is executed from the UI context, then the operation will be synchronized.
    /// If the operation is executed from the sync context, then the operation will not be synchronized.
    ///
    /// The method will handle the case when the participant is not there, so it's safe to call
    /// it even if the user is not there.
    ///
    /// The method will also check if the addition of the users will change the verification status, the archive
    /// status, etc.
    @objc
    public func removeParticipantsAndUpdateConversationState(users: Set<ZMUser>, initiatingUser: ZMUser? = nil) {

        guard let moc = self.managedObjectContext else { return }
        let existingUsers = Set(self.participantRoles.map { $0.user })

        let removedUsers = Set(users.compactMap { user -> ZMUser? in

            guard existingUsers.contains(user),
                let existingRole = participantRoles.first(where: { $0.user == user })
                else { return nil }

            participantRoles.remove(existingRole)
            moc.delete(existingRole)
            return user
        })

        if !removedUsers.isEmpty {
            let removedSelf = removedUsers.contains(where: { $0.isSelfUser })
            self.checkIfArchivedStatusChanged(removedSelfUser: removedSelf, initiatingUser: initiatingUser)
            self.checkIfVerificationLevelChanged(removedUsers: removedUsers)
        }
    }

    /// Remove participants to the conversation. The method will decide on its own whether
    /// this operation need to be synchronized to the backend or not based on the current context.
    /// If the operation is executed from the UI context, then the operation will be synchronized.
    /// If the operation is executed from the sync context, then the operation will not be synchronized.
    ///
    /// The method will handle the case when the participant is not there, so it's safe to call
    /// it even if the user is not there.
    ///
    /// The method will also check if the addition of the users will change the verification status, the archive
    /// status, etc.
    @objc
    public func removeParticipantAndUpdateConversationState(user: ZMUser, initiatingUser: ZMUser? = nil) {
        self.removeParticipantsAndUpdateConversationState(users: Set(arrayLiteral: user), initiatingUser: initiatingUser)
    }

    private func checkIfArchivedStatusChanged(removedSelfUser: Bool, initiatingUser: ZMUser?) {
        if removedSelfUser, let initiatingUser = initiatingUser {
            self.isArchived = initiatingUser.isSelfUser
        }
    }

    private func checkIfVerificationLevelChanged(removedUsers: Set<ZMUser>) {
        self.increaseSecurityLevelIfNeededAfterRemoving(users: removedUsers)
    }

    // MARK: - Conversation roles

    /// List of roles for the conversation whether it's linked with a team or not
    @objc
    public func getRoles() -> Set<Role> {
        if let team = team {
            return team.roles
        }
        return nonTeamRoles
    }

    /// Check if roles are missing, and mark them to download if needed
    @objc public func markToDownloadRolesIfNeeded() {
        guard
            conversationType == .group,
            !isTeamConversation
        else { return }

        // if there are no roles with actions
        if nonTeamRoles.isEmpty || !nonTeamRoles.contains(where: { !$0.actions.isEmpty }) {
            needsToDownloadRoles = true
        }
    }

    // MARK: - Utils
    func has(participantWithId userId: Proteus_UserId?) -> Bool {
        return localParticipants.contains { $0.userId == userId }
    }
}
