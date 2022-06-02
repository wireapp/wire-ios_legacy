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

import XCTest
@testable import WireDataModel

class ZMMessageTests_SystemMessages: BaseZMMessageTests {

    func testThatOnlyRecoverableDecryptionErrorsAreReportedAsRecoverable() throws {
        let allEncryptionErrors = [
            CBOX_STORAGE_ERROR,
            CBOX_SESSION_NOT_FOUND,
            CBOX_DECODE_ERROR,
            CBOX_REMOTE_IDENTITY_CHANGED,
            CBOX_INVALID_SIGNATURE,
            CBOX_INVALID_MESSAGE,
            CBOX_DUPLICATE_MESSAGE,
            CBOX_TOO_DISTANT_FUTURE,
            CBOX_OUTDATED_MESSAGE,
            CBOX_UTF8_ERROR,
            CBOX_NUL_ERROR,
            CBOX_ENCODE_ERROR,
            CBOX_IDENTITY_ERROR,
            CBOX_PREKEY_NOT_FOUND,
            CBOX_PANIC,
            CBOX_INIT_ERROR,
            CBOX_DEGENERATED_KEY
        ]

        let recoverableEncryptionErrors = [
            CBOX_TOO_DISTANT_FUTURE,
            CBOX_DEGENERATED_KEY,
            CBOX_PREKEY_NOT_FOUND
        ]

        for encryptionError in allEncryptionErrors {
            assertDecryptionErrorIsReportedAsRecoverable(
                encryptionError,
                recoverable: recoverableEncryptionErrors.contains(encryptionError))
        }
    }

    private func assertDecryptionErrorIsReportedAsRecoverable(_ decryptionError: CBoxResult,
                                                              recoverable: Bool,
                                                              file: StaticString = #file,
                                                              line: UInt = #line) {
        // given
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage.systemMessageType = .decryptionFailed
        systemMessage.decryptionErrorCode = NSNumber(value: decryptionError.rawValue)

        // then
        XCTAssertEqual(systemMessage.isDecryptionErrorRecoverable, recoverable, file: file, line: line)
    }

}

extension ZMMessageTests_SystemMessages {

    func testThatItGeneratesTheCorrectSystemMessageTypesFromUpdateEvents() {
        // expect a message
        checkThatUpdateEventTypeGeneratesSystemMessage(updateEventType: .conversationMemberJoin,
                                                       systemMessageType: .participantsAdded,
                                                       reason: nil)

        checkThatUpdateEventTypeGeneratesSystemMessage(updateEventType: .conversationMemberLeave,
                                                       systemMessageType: .participantsRemoved,
                                                       reason: nil)
        checkThatUpdateEventTypeGeneratesSystemMessage(updateEventType: .conversationMemberLeave,
                                                       systemMessageType: .participantsRemoved,
                                                       reason: .legalHoldPolicyConflict)

        checkThatUpdateEventTypeGeneratesSystemMessage(updateEventType: .conversationRename,
                                                       systemMessageType: .conversationNameChanged,
                                                       reason: nil)
    }

    func testThatItGeneratesTheCorrectSystemMessageTypesFromMemberJoinedUpdateEventWithQualifiedUsers() {
        // expect a message
        checkThatUpdateEventTypeGeneratesSystemMessage(updateEventType: .conversationMemberJoin,
                                                       systemMessageType: .participantsAdded,
                                                       reason: nil,
                                                       selfUserDomain: "foo.com",
                                                       otherUserDomain: "bar.com")
    }

    func testThatItGeneratesTheCorrectSystemMessageTypesFromMemberLeaveMUpdateEventWithQualifiedUsers() {
        // expect a message
        checkThatUpdateEventTypeGeneratesSystemMessage(updateEventType: .conversationMemberLeave,
                                                       systemMessageType: .participantsRemoved,
                                                       reason: nil,
                                                       selfUserDomain: "foo.com",
                                                       otherUserDomain: "bar.com")
    }

    private func createSystemMessageFrom(updateEventType: ZMUpdateEventType,
                                         in conversation: ZMConversation,
                                         with usersIDs: [UUID],
                                         senderID: UUID?,
                                         reason: ZMParticipantsRemovedReason?,
                                         domain: String? = nil) -> ZMSystemMessage? {
        let updateEventTypeDict: [ZMUpdateEventType: String] = [
            .conversationMemberJoin: "conversation.member-join",
            .conversationMemberLeave: "conversation.member-leave",
            .conversationRename: "conversation.rename"
        ]

        var data: [String: Any]
        if let domain = domain {
            if updateEventType == .conversationMemberJoin {
                data = ["users": usersIDs.map {
                    ["qualified_id":
                        ["id": $0.transportString(), "domain": domain]
                    ]
                } ] as [String: Any]
            } else {
                data = ["qualified_user_ids": usersIDs.map {
                    ["id": $0.transportString(), "domain": domain]
                } ] as [String: Any]
            }
        } else {
            data = ["user_ids": usersIDs.map { $0.transportString() }] as [String: Any]
        }

        if reason != nil {
            data["reason"] = reason?.stringValue
        }
        let payload = self.payloadForMessage(
            in: conversation,
            type: updateEventTypeDict[updateEventType] ?? "",
            data: data
        )
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
        var result: ZMSystemMessage?
        self.performPretendingUiMocIsSyncMoc {
            result = ZMSystemMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        return result
    }

    private func checkThatUpdateEventTypeGeneratesSystemMessage(updateEventType: ZMUpdateEventType,
                                                                systemMessageType: ZMSystemMessageType,
                                                                reason: ZMParticipantsRemovedReason?,
                                                                selfUserDomain: String? = nil,
                                                                otherUserDomain: String? = nil) {

        // given
        ZMUser.selfUser(in: uiMOC).domain = selfUserDomain
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID()
       conversation.conversationType = updateEventType == .conversationConnectRequest ? .connection : .group

        conversation.remoteIdentifier = NSUUID.create()
        let userID1 = UUID()
        let userID2 = UUID()

        // when
        var message: ZMSystemMessage?
        self.performPretendingUiMocIsSyncMoc {
            message = self.createSystemMessageFrom(updateEventType: updateEventType,
                                                   in: conversation,
                                                   with: [userID1, userID2],
                                                   senderID: nil,
                                                   reason: reason,
                                                   domain: otherUserDomain)
        }
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNotNil(message)
        XCTAssertEqual(message!.systemMessageType, systemMessageType)
        XCTAssertEqual(message!.participantsRemovedReason, reason ?? .none)
        XCTAssertEqual(message!.users.count, 2)
        XCTAssertTrue(conversation.lastMessage is ZMSystemMessage)
    }

}
