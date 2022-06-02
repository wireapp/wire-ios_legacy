//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import XCTest
@testable import WireRequestStrategy

class ZMLocalNotificationTests: MessagingTestBase {

    typealias ZMLocalNotification = WireRequestStrategy.ZMLocalNotification

    var sender: ZMUser!
    var selfUser: ZMUser!
    var otherUser1: ZMUser!
    var otherUser2: ZMUser!
    var userWithNoName: ZMUser!
    var oneOnOneConversation: ZMConversation!
    var groupConversationWithoutUserDefinedName: ZMConversation!
    var groupConversationWithoutName: ZMConversation!
    var invalidConversation: ZMConversation!

    override func setUp() {
        super.setUp()
        self.syncMOC.performGroupedBlockAndWait {
            self.selfUser = ZMUser.selfUser(in: self.syncMOC)
            self.selfUser.remoteIdentifier = UUID.create()
            self.sender = self.insertUser(with: UUID.create(), name: "Super User")
            self.otherUser1 = self.insertUser(with: UUID.create(), name: "Other User1")
            self.otherUser2 = self.insertUser(with: UUID.create(), name: "Other User2")
            self.userWithNoName = self.insertUser(with: UUID.create(), name: nil)
            self.oneOnOneConversation = self.insertConversation(
                with: UUID.create(),
                name: "Super Conversation",
                type: .oneOnOne,
                mutedMessages: .none,
                otherParticipants: [self.selfUser, self.sender])
            self.groupConversation = self.insertConversation(
                with: UUID.create(),
                name: "Super Conversation",
                type: .group,
                mutedMessages: .none,
                otherParticipants: [self.sender, self.otherUser1]
            )

            // an empty conversation will have no meaninful display name
            self.groupConversationWithoutName = self.insertConversation(
                with: UUID.create(),
                name: nil,
                type: .group,
                mutedMessages: .none,
                otherParticipants: []
            )
            self.groupConversationWithoutUserDefinedName = self.insertConversation(
                with: UUID.create(),
                name: nil,
                type: .group,
                mutedMessages: .none,
                otherParticipants: [self.sender, self.otherUser1]
            )
            self.invalidConversation = self.insertConversation(
                with: UUID.create(),
                name: nil,
                type: .invalid,
                mutedMessages: .none,
                otherParticipants: []
            )
        }
    }

    override func tearDown() {
        sender = nil
        otherUser1 = nil
        otherUser2 = nil
        userWithNoName = nil
        oneOnOneConversation = nil
        groupConversationWithoutName = nil
        groupConversationWithoutUserDefinedName = nil
        invalidConversation = nil
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)
        super.tearDown()
    }

    // MARK: - Helpers

    func insertUser(with remoteID: UUID, name: String?) -> ZMUser {
        var user: ZMUser!
        self.syncMOC.performGroupedBlockAndWait {
            user = ZMUser.insertNewObject(in: self.syncMOC)
            user.name = name
            user.remoteIdentifier = remoteID
        }
        return user
    }

    func insertConversation(
        with remoteID: UUID,
        name: String?,
        type: ZMConversationType,
        mutedMessages: MutedMessageTypes,
        otherParticipants: [ZMUser]) -> ZMConversation {
            var conversation: ZMConversation!
            self.syncMOC.performGroupedBlockAndWait {
                conversation = ZMConversation.insertNewObject(in: self.syncMOC)
                conversation.remoteIdentifier = remoteID
                conversation.userDefinedName = name
                conversation.conversationType = type
                conversation.mutedMessageTypes = mutedMessages
                conversation.lastServerTimeStamp = Date()
                conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp
                conversation?.addParticipantsAndUpdateConversationState(
                    users: Set(otherParticipants + [self.selfUser]),
                    role: nil)
               // self.uiMOC.saveOrRollback()
            }
            return conversation
        }

    func noteWithPayload(_ data: NSDictionary?, fromUserID: UUID?, in conversation: ZMConversation?, type: String) -> ZMLocalNotification? {
        var note: ZMLocalNotification?
        self.syncMOC.performGroupedBlockAndWait {
            let payload = self.payloadForEvent(in: conversation, type: type, data: data, from: fromUserID)
            if let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil) {
                note = ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: self.syncMOC)
            }
        }
        return note
    }

    func noteWithPayload(_ data: NSDictionary?, from user: ZMUser, in conversation: ZMConversation?, type: String) -> ZMLocalNotification? {
        return noteWithPayload(data, fromUserID: user.remoteIdentifier, in: conversation, type: type)
    }

    func payloadForEvent(in conversation: ZMConversation?, type: String, data: NSDictionary?, from userID: UUID?) -> NSMutableDictionary {
        let userRemoteID = userID ?? UUID.create()
        let convRemoteID = conversation?.remoteIdentifier ?? UUID.create()
        let serverTimeStamp = conversation?.lastReadServerTimeStamp?.addingTimeInterval(5) ?? Date()

        return NSMutableDictionary(dictionary: [
            "conversation": convRemoteID.transportString(),
            "data": data ?? [:],
            "from": userRemoteID.transportString(),
            "type": type,
            "time": serverTimeStamp.transportString()
        ]).mutableCopy() as! NSMutableDictionary
    }

    func createUpdateEvent(_ nonce: UUID, conversationID: UUID, genericMessage: GenericMessage, senderID: UUID = UUID.create()) -> ZMUpdateEvent {
        let payload: [String: Any] = [
            "id": UUID.create().transportString(),
            "conversation": conversationID.transportString(),
            "from": senderID.transportString(),
            "time": Date().transportString(),
            "data": ["text": try? genericMessage.serializedData().base64String()],
            "type": "conversation.otr-message-add"
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nonce)!
    }

    func createMemberJoinUpdateEvent(_ nonce: UUID, conversationID: UUID, users: [ZMUser], senderID: UUID = UUID.create()) -> ZMUpdateEvent {
        let userIds = users.map { $0.remoteIdentifier.transportString() }
        let usersWithRoles = users.map { (user) -> [String: String] in
            return ["id": user.remoteIdentifier.transportString(),
                    "conversation_role": "wire_admin"]
        }

        let payload: [String: Any] = [
            "from": senderID.transportString(),
            "conversation": conversationID.transportString(),
            "time": NSDate().transportString(),
            "data": [
                "user_ids": userIds,
                "users": usersWithRoles
            ],
            "type": "conversation.member-join"
        ]
        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nonce)!
    }

    func createMemberLeaveUpdateEvent(_ nonce: UUID, conversationID: UUID, users: [ZMUser], senderID: UUID = UUID.create()) -> ZMUpdateEvent {
        let userIds = users.map { $0.remoteIdentifier.transportString() }
        let payload: [String: Any] = [
            "from": senderID.transportString(),
            "conversation": conversationID.transportString(),
            "time": NSDate().transportString(),
            "data": [
                "user_ids": userIds
            ],
            "type": "conversation.member-leave"
        ]
        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nonce)!
    }

    func createMessageTimerUpdateEvent(_ nonce: UUID,
                                       conversationID: UUID,
                                       senderID: UUID = UUID.create(),
                                       timer: Int64 = 31536000,
                                       timestamp: Date = Date()) -> ZMUpdateEvent {

       let payload: [String: Any] = [
        "from": senderID.transportString(),
        "conversation": conversationID.transportString(),
        "time": timestamp.transportString(),
        "data": ["message_timer": timer],
        "type": "conversation.message-timer-update"
        ]
        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nonce)!
    }

}
