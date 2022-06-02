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

protocol EventData: Codable {
    static var eventType: ZMUpdateEventType { get }
}

extension Payload {

    struct NewConversation: Codable {
        enum CodingKeys: String, CodingKey {
            case users
            case qualifiedUsers = "qualified_users"
            case access
            case accessRole = "access_role"
            case accessRoleV2 = "access_role_v2"
            case name
            case team
            case messageTimer = "message_timer"
            case readReceiptMode = "receipt_mode"
            case conversationRole = "conversation_role"
        }

        let users: [UUID]?
        let qualifiedUsers: [QualifiedID]?
        let access: [String]?
        let accessRole: String?
        let accessRoleV2: [String]?
        let name: String?
        let team: ConversationTeamInfo?
        let messageTimer: TimeInterval?
        let readReceiptMode: Int?
        let conversationRole: String?

        init(_ conversation: ZMConversation) {
            if let qualifiedUsers = conversation.localParticipantsExcludingSelf.qualifiedUserIDs {
                self.qualifiedUsers = qualifiedUsers
                self.users = nil
            } else {
                qualifiedUsers = nil
                users = conversation.localParticipantsExcludingSelf.map(\.remoteIdentifier)
            }

            name = conversation.userDefinedName
            access = conversation.accessMode?.stringValue
            accessRole = conversation.accessRole?.rawValue
            accessRoleV2 = conversation.accessRoles.map(\.rawValue)
            conversationRole = ZMConversation.defaultMemberRoleName
            team = conversation.team?.remoteIdentifier.map({ ConversationTeamInfo(teamID: $0) })
            readReceiptMode = conversation.hasReadReceiptsEnabled ? 1 : 0
            messageTimer = nil
        }
    }

    struct Conversation: EventData {

        enum CodingKeys: String, CodingKey {
            case qualifiedID = "qualified_id"
            case id
            case type
            case creator
            case access
            case accessRole = "access_role"
            case accessRoleV2 = "access_role_v2"
            case name
            case members
            case lastEvent = "last_event"
            case lastEventTime = "last_event_time"
            case teamID = "team"
            case messageTimer = "message_timer"
            case readReceiptMode = "receipt_mode"
        }

        static var eventType: ZMUpdateEventType {
            return .conversationCreate
        }

        let qualifiedID: QualifiedID?
        let id: UUID?
        let type: Int?
        let creator: UUID?
        let access: [String]?
        let accessRole: String?
        let accessRoleV2: [String]?
        let name: String?
        let members: ConversationMembers?
        let lastEvent: String?
        let lastEventTime: String?
        let teamID: UUID?
        let messageTimer: TimeInterval?
        let readReceiptMode: Int?

        init(qualifiedID: QualifiedID? = nil,
             id: UUID?  = nil,
             type: Int? = nil,
             creator: UUID? = nil,
             access: [String]? = nil,
             accessRole: String? = nil,
             accessRoleV2: [String]? = nil,
             name: String? = nil,
             members: ConversationMembers? = nil,
             lastEvent: String? = nil,
             lastEventTime: String? = nil,
             teamID: UUID? = nil,
             messageTimer: TimeInterval? = nil,
             readReceiptMode: Int? = nil) {

            self.qualifiedID = qualifiedID
            self.id = id
            self.type = type
            self.creator = creator
            self.access = access
            self.accessRole = accessRole
            self.accessRoleV2 = accessRoleV2
            self.name = name
            self.members = members
            self.lastEvent = lastEvent
            self.lastEventTime = lastEventTime
            self.teamID = teamID
            self.messageTimer = messageTimer
            self.readReceiptMode = readReceiptMode
        }
    }

    struct ConversationList: Codable {
        enum CodingKeys: String, CodingKey {
            case conversations
            case hasMore = "has_more"
        }

        let conversations: [Conversation]
        let hasMore: Bool?
    }

    struct QualifiedConversationList: Codable {
        enum CodingKeys: String, CodingKey {
            case found = "found"
            case notFound = "not_found"
            case failed = "failed"
        }

        let found: [Conversation]
        let notFound: [QualifiedID]
        let failed: [QualifiedID]
    }

    struct PaginatedConversationIDList: Codable, Paginatable {

        enum CodingKeys: String, CodingKey {
            case conversations
            case hasMore = "has_more"
        }

        var nextStartReference: String? {
            return conversations.last?.transportString()
        }

        let conversations: [UUID]
        let hasMore: Bool
    }

    struct PaginatedQualifiedConversationIDList: Codable, Paginatable {

        enum CodingKeys: String, CodingKey {
            case conversations = "qualified_conversations"
            case pagingState = "paging_state"
            case hasMore = "has_more"
        }

        var nextStartReference: String? {
            return pagingState
        }

        let conversations: [QualifiedID]
        let pagingState: String
        let hasMore: Bool
    }

    struct Service: Codable {
        let id: UUID
        let provider: UUID
    }

    struct ConversationMember: EventData {

        enum CodingKeys: String, CodingKey {
            case id
            case qualifiedID = "qualified_id"
            case target
            case qualifiedTarget = "qualified_target"
            case service
            case mutedStatus = "otr_muted_status"
            case mutedReference = "otr_muted_ref"
            case archived = "otr_archived"
            case archivedReference = "otr_archived_ref"
            case hidden = "otr_hidden"
            case hiddenReference = "otr_hidden_ref"
            case conversationRole = "conversation_role"
        }

        static var eventType: ZMUpdateEventType {
            return .conversationMemberUpdate
        }

        let id: UUID?
        let qualifiedID: QualifiedID?
        let target: UUID?
        let qualifiedTarget: QualifiedID?
        let service: Service?
        let mutedStatus: Int?
        let mutedReference: Date?
        let archived: Bool?
        let archivedReference: Date?
        let hidden: Bool?
        let hiddenReference: String?
        let conversationRole: String?

        init(id: UUID? = nil,
             qualifiedID: QualifiedID? = nil,
             target: UUID? = nil,
             qualifiedTarget: QualifiedID? = nil,
             service: Service? = nil,
             mutedStatus: Int? = nil,
             mutedReference: Date? = nil,
             archived: Bool? = nil,
             archivedReference: Date? = nil,
             hidden: Bool? = nil,
             hiddenReference: String? = nil,
             conversationRole: String? = nil) {
            self.id = id
            self.qualifiedID = qualifiedID
            self.target = target
            self.qualifiedTarget = qualifiedTarget
            self.service = service
            self.mutedStatus  = mutedStatus
            self.mutedReference = mutedReference
            self.archived = archived
            self.archivedReference = archivedReference
            self.hidden = hidden
            self.hiddenReference = hiddenReference
            self.conversationRole = conversationRole
        }
    }

    struct ConversationMembers: Codable {
        enum CodingKeys: String, CodingKey {
            case selfMember = "self"
            case others
        }

        let selfMember: ConversationMember
        let others: [ConversationMember]
    }

    struct ConversationTeamInfo: Codable {
        enum CodingKeys: String, CodingKey {
            case teamID = "teamid"
            case managed
        }

        init (teamID: UUID, managed: Bool = false) {
            self.teamID = teamID
            self.managed = managed
        }

        let teamID: UUID
        let managed: Bool?
    }

    struct UpdateConversationStatus: Codable {
        enum CodingKeys: String, CodingKey {
            case mutedStatus = "otr_muted_status"
            case mutedReference = "otr_muted_ref"
            case archived = "otr_archived"
            case archivedReference = "otr_archived_ref"
            case hidden = "otr_hidden"
            case hiddenReference = "otr_hidden_ref"
        }

        var mutedStatus: Int?
        var mutedReference: Date?
        var archived: Bool?
        var archivedReference: Date?
        var hidden: Bool?
        var hiddenReference: String?

        init(_ conversation: ZMConversation) {

            if conversation.hasLocalModifications(forKey: ZMConversationSilencedChangedTimeStampKey) {
                let reference = conversation.silencedChangedTimestamp ?? Date()
                conversation.silencedChangedTimestamp = reference

                mutedStatus = Int(conversation.mutedMessageTypes.rawValue)
                mutedReference = reference
            }

            if conversation.hasLocalModifications(forKey: ZMConversationArchivedChangedTimeStampKey) {
                let reference = conversation.archivedChangedTimestamp ?? Date()
                conversation.archivedChangedTimestamp = reference

                archived = conversation.isArchived
                archivedReference = reference
            }
        }
    }

    // MARK: - Actions

    struct ConversationAddMember: Codable {
        enum CodingKeys: String, CodingKey {
            case userIDs = "users"
            case qualifiedUserIDs = "qualified_users"
            case role = "conversation_role"
        }

        let userIDs: [UUID]?
        let qualifiedUserIDs: [QualifiedID]?
        let role: String

        init?(userIDs: [UUID]? = nil, qualifiedUserIDs: [QualifiedID]? = nil) {
            self.userIDs = userIDs
            self.qualifiedUserIDs = qualifiedUserIDs
            self.role = ZMConversation.defaultMemberRoleName
        }
    }

    struct ConversationUpdateRole: Codable {
        enum CodingKeys: String, CodingKey {
            case role = "conversation_role"
        }

        let role: String

        init?(role: String) {
            self.role = role
        }
    }

    // MARK: - Events

    struct ConversationEvent<T: EventData>: Codable {

        enum CodingKeys: String, CodingKey {
            case id = "conversation"
            case qualifiedID = "qualified_conversation"
            case from
            case qualifiedFrom = "qualified_from"
            case timestamp = "time"
            case type
            case data
        }

        let id: UUID?
        let qualifiedID: QualifiedID?
        let from: UUID?
        let qualifiedFrom: QualifiedID?
        let timestamp: Date?
        let type: String?
        let data: T
    }

    struct UpdateConverationMemberLeave: EventData {
        enum CodingKeys: String, CodingKey {
            case userIDs = "user_ids"
            case qualifiedUserIDs = "qualified_user_ids"
        }

        static var eventType: ZMUpdateEventType {
            return .conversationMemberLeave
        }

        let userIDs: [UUID]?
        let qualifiedUserIDs: [QualifiedID]?
    }

    struct UpdateConverationMemberJoin: EventData {
        enum CodingKeys: String, CodingKey {
            case userIDs = "user_ids"
            case users
        }

        static var eventType: ZMUpdateEventType {
            return .conversationMemberJoin
        }

        let userIDs: [UUID]?
        let users: [ConversationMember]?
    }

    struct UpdateConversationConnectionRequest: EventData {
        static var eventType: ZMUpdateEventType {
            return .conversationConnectRequest
        }
    }

    struct UpdateConversationDeleted: EventData {
        static var eventType: ZMUpdateEventType {
            return .conversationDelete
        }
    }

    struct UpdateConversationReceiptMode: EventData {
        enum CodingKeys: String, CodingKey {
            case readReceiptMode = "receipt_mode"
        }

        static var eventType: ZMUpdateEventType {
            return .conversationReceiptModeUpdate
        }

        let readReceiptMode: Int
    }

    struct UpdateConversationMessageTimer: EventData {
        enum CodingKeys: String, CodingKey {
            case messageTimer = "message_timer"
        }

        static var eventType: ZMUpdateEventType {
            return .conversationMessageTimerUpdate
        }

        let messageTimer: TimeInterval?
    }

    struct UpdateConversationAccess: EventData {
        enum CodingKeys: String, CodingKey {
            case access
            case accessRole = "access_role"
            case accessRoleV2 = "access_role_v2"
        }

        static var eventType: ZMUpdateEventType {
            return .conversationAccessModeUpdate
        }

        let access: [String]
        let accessRole: String?
        let accessRoleV2: [String]?
    }

    struct UpdateConversationName: EventData {
        var name: String

        static var eventType: ZMUpdateEventType {
            return .conversationRename
        }

        init?(_ conversation: ZMConversation) {
            guard
                conversation.hasLocalModifications(forKey: ZMConversationUserDefinedNameKey),
                let userDefinedName = conversation.userDefinedName
            else {
                return nil
            }

            name = userDefinedName
        }

        init(name: String) {
            self.name = name
        }
    }

}
