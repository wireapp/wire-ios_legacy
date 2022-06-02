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

import XCTest
import WireDataModel
import WireTesting

class SharingSessionTests: BaseSharingSessionTests {

    func createConversation(type: ZMConversationType, archived: Bool) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: moc)
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: moc), role: nil)
        conversation.conversationType = type
        conversation.isArchived = archived
        return conversation
    }

    var activeConversation1: ZMConversation!
    var activeConversation2: ZMConversation!
    var activeConnection: ZMConversation!
    var archivedConversation: ZMConversation!
    var archivedConnection: ZMConversation!

    override func setUp() {
        super.setUp()
        activeConversation1 = createConversation(type: .group, archived: false)
        activeConversation2 = createConversation(type: .group, archived: false)
        activeConnection = createConversation(type: .connection, archived: false)
        archivedConversation = createConversation(type: .group, archived: true)
        archivedConnection = createConversation(type: .connection, archived: true)
    }

    override func tearDown() {
        activeConversation1 = nil
        activeConversation2 = nil
        activeConnection = nil
        archivedConversation = nil
        archivedConnection = nil
        super.tearDown()
    }

    func testThatWriteableNonArchivedConversationsAreReturned() {
        let conversations = Set(sharingSession.writeableNonArchivedConversations.map { $0 as! ZMConversation })
        let activeConversationsSet: Set<ZMConversation?> =  [activeConversation1, activeConversation2]
        XCTAssertEqual(conversations, activeConversationsSet)
    }

    func testThatWritebleArchivedConversationsAreReturned() {
        let conversations = sharingSession.writebleArchivedConversations.map { $0 as! ZMConversation }
        XCTAssertEqual(conversations, [archivedConversation])
    }
}
