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

import WireTransport

private let zmLog = ZMSLog(tag: "event-processing")

/// This enum matches the backend convention for type
@objc(ZMBackendConversationType)
public enum BackendConversationType: Int {
    case group = 0
    case `self` = 1
    case oneOnOne = 2
    case connection = 3

    public static func clientConversationType(rawValue: Int) -> ZMConversationType {
        guard let backendType = BackendConversationType(rawValue: rawValue) else {
            return .invalid
        }
        switch backendType {
        case .group:
            return .group
        case .oneOnOne:
            return .oneOnOne
        case .connection:
            return .connection
        case .`self`:
            return .`self`
        }
    }
}

extension ZMConversation {

    public struct PayloadKeys {

        private init() {}

        public static let nameKey = "name"
        public static let typeKey = "type"
        public static let IDKey = "id"
        public static let qualifiedIDKey = "qualified_id"
        public static let targetKey = "target"
        public static let domainKey = "domain"

        public static let othersKey = "others"
        public static let membersKey = "members"
        public static let selfKey = "self"
        public static let creatorKey = "creator"
        public static let teamIdKey = "team"
        public static let conversationRoleKey = "conversation_role"
        public static let accessModeKey = "access"
        public static let accessRoleKey = "access_role"
        public static let accessRoleKeyV2 = "access_role_v2"
        public static let messageTimer = "message_timer"
        public static let receiptMode = "receipt_mode"

        public static let OTRMutedValueKey = "otr_muted"
        public static let OTRMutedStatusValueKey = "otr_muted_status"
        public static let OTRMutedReferenceKey = "otr_muted_ref"
        public static let OTRArchivedValueKey = "otr_archived"
        public static let OTRArchivedReferenceKey = "otr_archived_ref"
    }

    public func updateCleared(fromPostPayloadEvent event: ZMUpdateEvent ) {
        if let timeStamp = event.timestamp {
            updateCleared(timeStamp, synchronize: true)
        }
    }

    @objc
    public func update(updateEvent: ZMUpdateEvent) {
        if let timeStamp = updateEvent.timestamp {
            self.updateServerModified(timeStamp)
        }
    }

    public func updateMessageDestructionTimeout(timeout: TimeInterval) {
        // Backend is sending the miliseconds, we need to convert to seconds.
        setMessageDestructionTimeoutValue(.init(rawValue: timeout / 1000), for: .groupConversation)
    }

    public func updateAccessStatus(accessModes: [String], accessRoles: [String]) {
        accessModeStrings = accessModes
        accessRoleStringsV2 = accessRoles
    }

    public func updateReceiptMode(_ receiptMode: Int?) {
        if let receiptMode = receiptMode {
            let enabled = receiptMode > 0
            let receiptModeChanged = !self.hasReadReceiptsEnabled && enabled
            self.hasReadReceiptsEnabled = enabled

            // We only want insert a system message if this is an existing conversation (non empty)
            if receiptModeChanged && self.lastMessage != nil {
                self.appendMessageReceiptModeIsOnMessage(timestamp: Date())
            }
        }
    }

    public func updateMembers(_ usersAndRoles: [(ZMUser, Role?)], selfUserRole: Role?) {
        guard let context = self.managedObjectContext else {
            return
        }

        let allParticipants = Set(usersAndRoles.map { $0.0 })
        let removedParticipants = self.localParticipantsExcludingSelf.subtracting(allParticipants)
        addParticipantsAndUpdateConversationState(usersAndRoles: usersAndRoles)
        removeParticipantsAndUpdateConversationState(users: removedParticipants,
                                                     initiatingUser: ZMUser.selfUser(in: context))

        let selfUser = ZMUser.selfUser(in: context)
        if let role = selfUserRole {
            addParticipantAndUpdateConversationState(user: selfUser, role: role)
        } else if !isSelfAnActiveMember {
            addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        }

        updatePotentialGapSystemMessagesIfNeeded(users: localParticipants)
    }

    public func updateTeam(identifier: UUID?) {
        guard let teamId = identifier,
              let moc = self.managedObjectContext else { return }
        self.teamRemoteIdentifier = teamId
        self.team = Team.fetchOrCreate(with: teamId, create: false, in: moc, created: nil)
    }

    @objc func updatePotentialGapSystemMessagesIfNeeded(users: Set<ZMUser>) {
        guard let latestSystemMessage = ZMSystemMessage.fetchLatestPotentialGapSystemMessage(in: self)
        else { return }

        let removedUsers = latestSystemMessage.users.subtracting(users)
        let addedUsers = users.subtracting(latestSystemMessage.users)

        latestSystemMessage.addedUsers = addedUsers
        latestSystemMessage.removedUsers = removedUsers
        latestSystemMessage.updateNeedsUpdatingUsersIfNeeded()
    }

    public func updateArchivedStatus(archived: Bool, referenceDate: Date) {
        guard updateArchived(referenceDate, synchronize: false) else {
            return
        }

        internalIsArchived = archived
    }

    private func updateIsArchived(payload: [String: Any]) -> Bool {
        if let silencedRef = payload.date(fromKey: PayloadKeys.OTRArchivedReferenceKey),
           self.updateArchived(silencedRef, synchronize: false) {
            self.internalIsArchived = (payload[PayloadKeys.OTRArchivedValueKey] as? Int) == 1
            return true
        }
        return false
    }

    /// Update the muted status when from event or response payloads
    public func updateMutedStatus(status: Int32, referenceDate: Date) {
        guard updateMuted(referenceDate, synchronize: false) else {
            return
        }

        mutedStatus = status
    }

    @objc(shouldAddEvent:)
    public func shouldAdd(event: ZMUpdateEvent) -> Bool {
        if let clearedTime = self.clearedTimeStamp, let time = event.timestamp,
           clearedTime.compare(time) != .orderedAscending {
            return false
        }
        return self.conversationType != .self
    }

}

// MARK: - Payload parsing utils

extension ZMConversation {

    public func fetchOrCreateRoleForConversation(name: String) -> Role {
        return Role.fetchOrCreateRole(
            with: name,
            teamOrConversation: self.team != nil ? .team(self.team!) : .conversation(self),
            in: self.managedObjectContext!)
    }

}

extension Dictionary where Key == String, Value == Any {

    func UUID(fromKey key: String) -> UUID? {
        return (self[key] as? String).flatMap(Foundation.UUID.init)
    }

    func date(fromKey key: String) -> Date? {
        return (self as NSDictionary).optionalDate(forKey: key)
    }

    func domain(fromKey key: String) -> String? {
        return optionalDictionary(forKey: key)?.optionalString(forKey: ZMConversation.PayloadKeys.domainKey)
    }
}

extension Dictionary where Key == String, Value == Any? {

    func UUID(fromKey key: String) -> UUID? {
        return (self[key] as? String).flatMap(Foundation.UUID.init)
    }

    func date(fromKey key: String) -> Date? {
        return (self as NSDictionary).optionalDate(forKey: key)
    }

}
