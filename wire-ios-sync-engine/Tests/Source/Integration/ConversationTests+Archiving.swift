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

class ConversationTests_Archiving: ConversationTestsBase {

    func checkThatItUnarchives(shouldUnarchive: Bool, isSilenced: Bool, mockConversation: MockConversation, session block: @escaping (MockTransportSessionObjectCreation) -> Void) {
        // given
        XCTAssertTrue(login())

        let conversation = self.conversation(for: mockConversation)

        self.userSession?.perform {
            conversation!.isArchived = true
            if isSilenced {
                conversation!.isFullyMuted = true
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(conversation!.isArchived)
        if isSilenced {
            XCTAssertTrue(conversation!.isFullyMuted)
        }

        // when
        self.mockTransportSession.performRemoteChanges { (session) in
            block(session)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        shouldUnarchive
            ? XCTAssertFalse(conversation!.isArchived)
            : XCTAssertTrue(conversation!.isArchived)
    }

    func testThatAddingAMessageToAnArchivedConversation_Unarchives_ThisConversation() {
        // expect
        let shouldUnarchive = true

        // when
        checkThatItUnarchives(shouldUnarchive: shouldUnarchive, isSilenced: false, mockConversation: self.groupConversation) { (_) in
            let message = GenericMessage(content: Text(content: "Some text", mentions: [], linkPreviews: [], replyingTo: nil), nonce: UUID.create())
            let fromUser = self.groupConversation.activeUsers.lastObject as! MockUser
            self.groupConversation.encryptAndInsertData(from: fromUser.clients.anyObject() as! MockUserClient,
                                                              to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                              data: try! message.serializedData())
        }
    }

    func testThatAddingAMessageToAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation() {
        // expect
        let shouldUnarchive = false

        // when
        checkThatItUnarchives(shouldUnarchive: shouldUnarchive, isSilenced: true, mockConversation: self.groupConversation) { (_) in
            let message = GenericMessage(content: Text(content: "Some text", mentions: [], linkPreviews: [], replyingTo: nil), nonce: UUID.create())
            let fromUser = self.groupConversation.activeUsers.lastObject as! MockUser
            self.groupConversation.encryptAndInsertData(from: fromUser.clients.anyObject() as! MockUserClient,
                                                        to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                        data: try! message.serializedData())
        }
    }

    func testThatAddingAnImageToAnArchivedConversation_Unarchives_ThisConversation() {
        // expect
        let shouldUnarchive = true

        let message = GenericMessage(content: WireProtos.Asset(imageSize: CGSize(width: 10, height: 10), mimeType: "image/jpeg", size: 123), nonce: UUID.create())

        // when
        checkThatItUnarchives(shouldUnarchive: shouldUnarchive, isSilenced: false, mockConversation: self.groupConversation) { (_) in
            let fromUser = self.groupConversation.activeUsers.lastObject as! MockUser
            self.groupConversation.encryptAndInsertData(from: fromUser.clients.anyObject() as! MockUserClient,
                                                        to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                        data: try! message.serializedData())
        }
    }

    func testThatAddingAnImageToAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation() {
        // expect
        let shouldUnarchive = false

        let message = GenericMessage(content: WireProtos.Asset(imageSize: CGSize(width: 10, height: 10), mimeType: "image/jpeg", size: 123), nonce: UUID.create())

        // when
        checkThatItUnarchives(shouldUnarchive: shouldUnarchive, isSilenced: true, mockConversation: self.groupConversation) { (_) in
            let fromUser = self.groupConversation.activeUsers.lastObject as! MockUser
            self.groupConversation.encryptAndInsertData(from: fromUser.clients.anyObject() as! MockUserClient,
                                                        to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                        data: try! message.serializedData())
        }
    }

    func testThatAddingAnKnockToAnArchivedConversation_Unarchives_ThisConversation() {
        // expect
        let shouldUnarchive = true

        // when
        checkThatItUnarchives(shouldUnarchive: shouldUnarchive, isSilenced: false, mockConversation: self.groupConversation) { (_) in
            let message = GenericMessage(content: Knock.with { $0.hotKnock = false }, nonce: UUID.create())
            let fromUser = self.groupConversation.activeUsers.lastObject as! MockUser
            self.groupConversation.encryptAndInsertData(from: fromUser.clients.anyObject() as! MockUserClient,
                                                        to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                        data: try! message.serializedData())
        }
    }

    func testThatAddingAnKnockToAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation() {
        // expect
        let shouldUnarchive = false

        // when
        checkThatItUnarchives(shouldUnarchive: shouldUnarchive, isSilenced: true, mockConversation: self.groupConversation) { (_) in
            let message = GenericMessage(content: Knock.with { $0.hotKnock = false }, nonce: UUID.create())
            let fromUser = self.groupConversation.activeUsers.lastObject as! MockUser
            self.groupConversation.encryptAndInsertData(from: fromUser.clients.anyObject() as! MockUserClient,
                                                        to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                        data: try! message.serializedData())
        }
    }
}
