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

import XCTest

class UserTests_AccountDeletion: IntegrationTest {

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    func testThatUserIsMarkedAsDeleted() {
        // given
        XCTAssertTrue(login())

        // when
        mockTransportSession.performRemoteChanges { (mockTransport) in
            mockTransport.deleteAccount(for: self.user1)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let user1 = self.user(for: self.user1)!
        XCTAssertTrue(user1.isAccountDeleted)
    }

    func testThatUserIsRemovedFromAllConversationsWhenDeleted() {
        // given
        XCTAssertTrue(login())

        // when
        mockTransportSession.performRemoteChanges { (foo) in
            foo.deleteAccount(for: self.user1)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let user1 = self.user(for: self.user1)!
        let groupConversation = self.conversation(for: self.groupConversation)!
        XCTAssertFalse(groupConversation.localParticipants.contains(user1))
    }

}
