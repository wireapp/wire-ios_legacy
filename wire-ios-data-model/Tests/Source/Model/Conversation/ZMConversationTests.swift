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

import Foundation

extension ZMConversationTests {
    func testThatClearingMessageHistorySetsLastReadServerTimeStampToLastServerTimeStamp() {
        // given
        let clearedTimeStamp = Date()

        let otherUser = createUser()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastServerTimeStamp = clearedTimeStamp

        let message1 = ZMClientMessage(nonce: NSUUID.create(), managedObjectContext: uiMOC)
        message1.serverTimestamp = clearedTimeStamp
        message1.sender = otherUser
        message1.visibleInConversation = conversation

        XCTAssertNil(conversation.lastReadServerTimeStamp)

        // when
        conversation.clearMessageHistory()
        uiMOC.saveOrRollback()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // then
        XCTAssertEqual(conversation.lastReadServerTimeStamp, clearedTimeStamp)
    }

    // MARK: - SendOnlyEncryptedMessages

    func testThatItInsertsEncryptedKnockMessages() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // when
        try! conversation.appendKnock()

        // then
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        let result = uiMOC.executeFetchRequestOrAssert(request)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue((result.first is ZMClientMessage))
    }

    func testThatItInsertsEncryptedTextMessages() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // when
        conversation._appendText(content: "hello")

        // then
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        let result = uiMOC.executeFetchRequestOrAssert(request)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue((result.first is ZMClientMessage))
    }

    func testThatItInsertsEncryptedImageMessages() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // when
        conversation._appendImage(from: verySmallJPEGData())

        // then
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        let result = uiMOC.executeFetchRequestOrAssert(request)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue((result.first is ZMAssetClientMessage))
    }

    // MARK: - Domain tests

    func testThatItTreatsEmptyDomainAsNil() {
        // given
        let uuid = UUID.create()

        syncMOC.performGroupedBlockAndWait {
            // when
            let created = ZMConversation.fetchOrCreate(with: uuid, domain: "", in: self.syncMOC)

            // then
            XCTAssertEqual(uuid, created.remoteIdentifier)
            XCTAssertEqual(nil, created.domain)
        }
    }

    func testThatItIgnoresDomainWhenFederationIsDisabled() {
        // given
        let uuid = UUID.create()

        syncMOC.performGroupedBlockAndWait {
            // when
            APIVersion.isFederationEnabled = false
            let created = ZMConversation.fetchOrCreate(with: uuid, domain: "a.com", in: self.syncMOC)

            // then
            XCTAssertNotNil(created)
            XCTAssertEqual(uuid, created.remoteIdentifier)
            XCTAssertEqual(nil, created.domain)
        }
    }

    func testThatItAssignsDomainWhenFederationIsEnabled() {
        // given
        let uuid = UUID.create()
        let domain = "a.com"

        syncMOC.performGroupedBlockAndWait {
            // when
            APIVersion.isFederationEnabled = true
            let created = ZMConversation.fetchOrCreate(with: uuid, domain: domain, in: self.syncMOC)

            // then
            XCTAssertNotNil(created)
            XCTAssertEqual(uuid, created.remoteIdentifier)
            XCTAssertEqual(domain, created.domain)

            // Since the test class is an objc class, we can't set this to false in tearDown because APIVersion is a swift enum
            APIVersion.isFederationEnabled = false
        }
    }
}
