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

@testable import WireSyncEngine

class TypingUsersTests: MessagingTest {

    private typealias TypingUsers = WireSyncEngine.TypingUsers

    private var sut: TypingUsers!
    private var user1: ZMUser!
    private var user2: ZMUser!
    private var selfUser: ZMUser!
    private var conversation1: ZMConversation!
    private var conversation2: ZMConversation!

    override func setUp() {
        super.setUp()

        sut = TypingUsers()

        user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Hans"

        user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "Gretel"

        selfUser = ZMUser.insertNewObject(in: uiMOC)
        selfUser.name = "Myself"

        conversation1 = ZMConversation.insertNewObject(in: uiMOC)
        conversation1.userDefinedName = "A Walk in the Forest"

        conversation2 = ZMConversation.insertNewObject(in: uiMOC)
        conversation2.userDefinedName = "The Great Escape"

        XCTAssert(uiMOC.saveOrRollback())
    }

    override func tearDown() {
        sut = nil
        user1 = nil
        user2 = nil
        selfUser = nil
        conversation1 = nil
        conversation2 = nil

        super.tearDown()
    }

    // MARK: - Tests

    func testThatItReturnsAnEmptySetByDefault() {
        // Given, then
        XCTAssertEqual(sut.typingUsers(in: conversation1), Set())
    }

    func testThatItReturnsTheTypingUsers() {
        // Given
        let users: Set<ZMUser> = Set([user1, user2])
        // When
        sut.update(typingUsers: users, in: conversation1)

        // Then
        XCTAssertEqual(sut.typingUsers(in: conversation1), users)
        XCTAssertEqual(sut.typingUsers(in: conversation2), Set())
    }

    func testThatItUpdatesTheTypingUsers() {
        // Given
        let usersA: Set<ZMUser> = Set([user1, user2])
        let usersB: Set<ZMUser> = Set([user1])

        // When
        sut.update(typingUsers: usersA, in: conversation1)
        sut.update(typingUsers: usersB, in: conversation1)

        // Then
        XCTAssertEqual(sut.typingUsers(in: conversation1), usersB)
        XCTAssertEqual(sut.typingUsers(in: conversation2), Set())
    }

    func testThatItUpdatesMultipleConversations() {
        // Given
        let usersA: Set<ZMUser> = Set([user1])
        let usersB: Set<ZMUser> = Set([user1])

        // When
        sut.update(typingUsers: usersA, in: conversation1)
        sut.update(typingUsers: usersB, in: conversation2)

        // Then
        XCTAssertEqual(sut.typingUsers(in: conversation1), usersA)
        XCTAssertEqual(sut.typingUsers(in: conversation2), usersB)
    }

    func testThatItAddsAnInstanceToTheUiContext() {
        // When
        sut = uiMOC.typingUsers

        // Then
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isKind(of: TypingUsers.self))
        XCTAssertEqual(sut, uiMOC.typingUsers)
    }

    func testThatItDoesNotAddAnInstanceToTheSyncContext() {
        // When, then
        syncMOC.performGroupedBlockAndWait { XCTAssertNil(self.syncMOC.typingUsers) }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}
