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

import XCTest
import WireUtilities
@testable import WireDataModel
import WireLinkPreview

class ZMOTRMessage_SecurityDegradationTests: BaseZMClientMessageTests {

    func testThatAtCreationAMessageIsNotCausingDegradation_UIMoc() {

        // GIVEN
        let convo = createConversation(moc: self.uiMOC)

        // WHEN
        let message = try! convo.appendText(content: "Foo")
        self.uiMOC.saveOrRollback()

        // THEN
        XCTAssertFalse(message.causedSecurityLevelDegradation)
        XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
        XCTAssertFalse(self.uiMOC.zm_hasChanges)
    }

    func testThatAtCreationAMessageIsNotCausingDegradation_SyncMoc() {

        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)

            // WHEN
            let message = try! convo.appendText(content: "Foo")

            // THEN
            XCTAssertFalse(message.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
        }
    }

    func testThatItSetsMessageAsCausingDegradation() {

        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message = try! convo.appendText(content: "Foo") as! ZMOTRMessage
            self.syncMOC.saveOrRollback()

            // WHEN
            message.causedSecurityLevelDegradation = true

            // THEN
            XCTAssertTrue(message.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.contains(message))
            XCTAssertTrue(self.syncMOC.zm_hasChanges)

        }
    }

    func testThatItDoesNotSetDeliveryReceiptAsCausingDegradation() {

        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message = try! convo.appendText(content: "Foo") as! ZMClientMessage
            message.markAsSent()
            convo.securityLevel = .secure
            self.syncMOC.saveOrRollback()

            let confirmation = GenericMessage(content: Confirmation(messageId: message.nonce!, type: .delivered))
            let confirmationMessage = try! convo.appendClientMessage(with: confirmation, expires: false, hidden: true)

            // WHEN
            let newClient = UserClient.insertNewObject(in: self.syncMOC)
            convo.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [newClient], causedBy: confirmationMessage)
            self.syncMOC.saveOrRollback()

            // THEN
            XCTAssertEqual(convo.securityLevel, .secureWithIgnored)
            XCTAssertFalse(message.causedSecurityLevelDegradation)
            XCTAssertFalse(confirmationMessage.causedSecurityLevelDegradation)
            XCTAssertFalse(convo.messagesThatCausedSecurityLevelDegradation.contains(confirmationMessage))
            XCTAssertFalse(self.syncMOC.zm_hasChanges)
        }
    }

    func testThatItResetsMessageAsCausingDegradation() {

        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message = try! convo.appendText(content: "Foo") as! ZMOTRMessage
            message.causedSecurityLevelDegradation = true
            self.syncMOC.saveOrRollback()

            // WHEN
            message.causedSecurityLevelDegradation = false

            // THEN
            XCTAssertFalse(message.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
            XCTAssertTrue(self.syncMOC.zm_hasChanges)

        }
    }

    func testThatItResetsDegradedConversationWhenRemovingAllMessages() {

        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message1 = try! convo.appendText(content: "Foo") as! ZMOTRMessage
            message1.causedSecurityLevelDegradation = true
            let message2 = try! convo.appendText(content: "Foo") as! ZMOTRMessage
            message2.causedSecurityLevelDegradation = true

            // WHEN
            message1.causedSecurityLevelDegradation = false

            // THEN
            XCTAssertFalse(message1.causedSecurityLevelDegradation)
            XCTAssertFalse(convo.messagesThatCausedSecurityLevelDegradation.contains(message1))
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.contains(message2))

            // and WHEN
            self.syncMOC.saveOrRollback()
            message2.causedSecurityLevelDegradation = false

            // THEN
            XCTAssertFalse(message2.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
            XCTAssertTrue(self.syncMOC.zm_hasChanges)

        }
    }

    func testThatItResetsDegradedConversationWhenClearingDegradedMessagesOnConversation() {

        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message1 = try! convo.appendText(content: "Foo") as! ZMOTRMessage
            message1.causedSecurityLevelDegradation = true
            let message2 = try! convo.appendText(content: "Foo") as! ZMOTRMessage
            message2.causedSecurityLevelDegradation = true

            // WHEN
            convo.clearMessagesThatCausedSecurityLevelDegradation()

            // THEN
            XCTAssertFalse(message1.causedSecurityLevelDegradation)
            XCTAssertFalse(message2.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
            XCTAssertTrue(self.syncMOC.zm_hasUserInfoChanges)
        }
    }

    func testThatItResetsOnlyDegradedConversationWhenClearingDegradedMessagesOnThatConversation() {

        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message1 = try! convo.appendText(content: "Foo") as! ZMOTRMessage
            message1.causedSecurityLevelDegradation = true
            let message2 = try! convo.appendText(content: "Foo") as! ZMOTRMessage
            message2.causedSecurityLevelDegradation = true

            let otherConvo = self.createConversation(moc: self.syncMOC)
            let otherMessage = try! otherConvo.appendText(content: "Foo") as! ZMOTRMessage
            otherMessage.causedSecurityLevelDegradation = true

            // WHEN
            convo.clearMessagesThatCausedSecurityLevelDegradation()

            // THEN
            XCTAssertFalse(message1.causedSecurityLevelDegradation)
            XCTAssertFalse(message2.causedSecurityLevelDegradation)
            XCTAssertTrue(convo.messagesThatCausedSecurityLevelDegradation.isEmpty)
            XCTAssertTrue(self.syncMOC.zm_hasUserInfoChanges)

            XCTAssertFalse(otherConvo.messagesThatCausedSecurityLevelDegradation.isEmpty)
            XCTAssertTrue(otherMessage.causedSecurityLevelDegradation)
        }
    }

}

// MARK: - Propagation across contexes
extension ZMOTRMessage_SecurityDegradationTests {

    func testThatMessageIsNotMarkedOnUIMOCBeforeMerge() {
        // GIVEN
        let convo = createConversation(moc: self.uiMOC)
        let message = try! convo.appendText(content: "Foo") as! ZMOTRMessage
        self.uiMOC.saveOrRollback()

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let syncMessage = try! self.syncMOC.existingObject(with: message.objectID) as! ZMOTRMessage
            syncMessage.causedSecurityLevelDegradation = true
            self.syncMOC.saveOrRollback()
        }

        // THEN
        XCTAssertFalse(message.causedSecurityLevelDegradation)
    }

    func testThatMessageIsMarkedOnUIMOCAfterMerge() {
        // GIVEN
        let convo = createConversation(moc: self.uiMOC)
        let message = try! convo.appendText(content: "Foo") as! ZMOTRMessage
        self.uiMOC.saveOrRollback()
        var userInfo: [String: Any] = [:]
        self.syncMOC.performGroupedBlockAndWait {
            let syncMessage = try! self.syncMOC.existingObject(with: message.objectID) as! ZMOTRMessage
            syncMessage.causedSecurityLevelDegradation = true
            self.syncMOC.saveOrRollback()
            userInfo = self.syncMOC.userInfo.asDictionary() as! [String: Any]
        }

        // WHEN
        self.uiMOC.mergeUserInfo(fromUserInfo: userInfo)

        // THEN
        XCTAssertTrue(message.causedSecurityLevelDegradation)
    }

    func testThatItPreservesMessagesMargedOnSyncMOCAfterMerge() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message = try! convo.appendText(content: "Foo") as! ZMOTRMessage
            message.causedSecurityLevelDegradation = true

            // WHEN
            self.syncMOC.mergeUserInfo(fromUserInfo: [:])

            // THEN
            XCTAssertTrue(message.causedSecurityLevelDegradation)
        }
    }
}

// MARK: - Helper
extension ZMOTRMessage_SecurityDegradationTests {

    /// Creates a group conversation with two users
    func createConversation(moc: NSManagedObjectContext) -> ZMConversation {
        let user1 = ZMUser.insertNewObject(in: moc)
        user1.remoteIdentifier = UUID.create()
        let user2 = ZMUser.insertNewObject(in: moc)
        user2.remoteIdentifier = UUID.create()
        let convo = ZMConversation.insertGroupConversation(moc: moc, participants: [user1, user2], team: nil, participantsRole: nil)!
        return convo
    }

}
