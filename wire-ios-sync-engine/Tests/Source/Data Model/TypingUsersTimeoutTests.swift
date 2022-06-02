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

class TypingUsersTimeoutTests: MessagingTest {

    private typealias TypingUsersTimeout = WireSyncEngine.TypingUsersTimeout

    private var sut: TypingUsersTimeout!
    private var conversationA: ZMConversation!
    private var conversationB: ZMConversation!
    private var userA: ZMUser!
    private var userB: ZMUser!

    override func setUp() {
        super.setUp()

        sut = TypingUsersTimeout()
        conversationA = ZMConversation.insertNewObject(in: uiMOC)
        conversationB = ZMConversation.insertNewObject(in: uiMOC)
        userA = ZMUser.insertNewObject(in: uiMOC)
        userB = ZMUser.insertNewObject(in: uiMOC)
        XCTAssert(uiMOC.saveOrRollback())
    }

    override func tearDown() {
        sut = nil
        conversationA = nil
        conversationB = nil
        userA = nil
        userB = nil
        super.tearDown()
    }

    // MARK: - Adding / Removing Users

    func testThatItDoesNotContainUsersThatWeHaveNotAdded() {
        // Given, then
        XCTAssertFalse(sut.contains(userA, for: conversationA))
        XCTAssertFalse(sut.contains(userB, for: conversationB))
    }

    func testThatItCanAddAUser() {
        // When
        sut.add(userA, for: conversationA, withTimeout: Date())

        // Then
        XCTAssertTrue(sut.contains(userA, for: conversationA))
    }

    func testThatItCanRemoveAUser() {
        // Given
        sut.add(userA, for: conversationA, withTimeout: Date())
        sut.add(userB, for: conversationA, withTimeout: Date())

        // When
        sut.remove(userA, for: conversationA)

        // Then
        XCTAssertFalse(sut.contains(userA, for: conversationA))
        XCTAssertTrue(sut.contains(userB, for: conversationA))
    }

    // MARK: - First Timeout

    func testThatFirstTimeoutIsNilIfTimeoutsIsEmpty() {
        // Given, then
        XCTAssertNil(sut.firstTimeout)
    }

    func testThatFirstTimeoutIsNilForUsersAddedAndRemovedAgain() {
        // Given
        sut.add(userA, for: conversationA, withTimeout: Date())

        // when
        sut.remove(userA, for: conversationA)

        // Then
        XCTAssertNil(sut.firstTimeout)
    }

    func testThatItReturnsTheTimeoutWhenAUserIsAdded() {
        // Given
        let timeout = Date()

        // When
        sut.add(userA, for: conversationA, withTimeout: timeout)

        // Then
        XCTAssertEqual(sut.firstTimeout, timeout)
    }

    func testThatItReturnsTheEarliestTimeoutWhenMultipleAreAdded() {
        // Given
        let timeout1 = Date()
        let timeout2 = timeout1.addingTimeInterval(10)
        let timeout3 = timeout2.addingTimeInterval(20)

        // When
        sut.add(userA, for: conversationA, withTimeout: timeout1)
        sut.add(userA, for: conversationB, withTimeout: timeout2)
        sut.add(userB, for: conversationA, withTimeout: timeout3)

        // Then
        XCTAssertEqual(sut.firstTimeout, timeout1)
    }

    func testThatItReturnsTheLastSetTimeoutWhenAddedMultipleTimesForTheSameUserAndConversation() {
        // Given
        let timeout1 = Date()
        let timeout2 = timeout1.addingTimeInterval(10)
        let timeout3 = timeout2.addingTimeInterval(20)

        // When
        sut.add(userA, for: conversationA, withTimeout: timeout1)
        sut.add(userA, for: conversationA, withTimeout: timeout2)
        sut.add(userA, for: conversationA, withTimeout: timeout3)

        // Then
        XCTAssertEqual(sut.firstTimeout, timeout3)
    }

    // MARK: - Typing User Ids

    func testThatItReturnsTheCurrentlyTypingUserIds() {
        // Given
        sut.add(userA, for: conversationA, withTimeout: Date())
        sut.add(userB, for: conversationA, withTimeout: Date())

        // When
        let result = sut.userIds(in: conversationA)

        // Then
        XCTAssertEqual(result, Set([userA.objectID, userB.objectID]))
    }

    func testThatItReturnsAnEmptySetWhenNoUsersAreTyping() {
        // When
        let result = sut.userIds(in: conversationA)

        // Then
        XCTAssertEqual(result, Set())
    }

    // MARK: - Pruning

    func testThatItReturnsAnEmptySetWhenPruningAndNothingWasAdded() {
        // When
        let result = sut.pruneConversationsThatHaveTimoutBefore(date: Date(timeIntervalSinceNow: -10))

        // Then
        XCTAssertEqual(result, Set())
    }

    func testThatItReturnsAnEmptySetWhenPruningAndNothingHasExpired() {
        // Given
        let timeout = Date(timeIntervalSinceNow: 10)
        sut.add(userA, for: conversationA, withTimeout: timeout)

        // When
        let result = sut.pruneConversationsThatHaveTimoutBefore(date: Date())

        // Then
        XCTAssertEqual(result, Set())
    }

    func testThatItReturnsAPrunedConversation() {
        // Given
        let timeout1 = Date(timeIntervalSinceNow: 10)
        let timeout2 = Date(timeIntervalSinceNow: 20)
        sut.add(userA, for: conversationA, withTimeout: timeout1)

        // When
        let result = sut.pruneConversationsThatHaveTimoutBefore(date: timeout2)

        // Then
        XCTAssertEqual(result, Set([conversationA.objectID]))
    }

    func testThatItReturnsMultiplePrunedConversations() {
        // Given
        let timeout1 = Date(timeIntervalSinceNow: 10)
        let timeout2 = Date(timeIntervalSinceNow: 20)
        sut.add(userA, for: conversationA, withTimeout: timeout1)
        sut.add(userB, for: conversationB, withTimeout: timeout1)

        // When
        let result = sut.pruneConversationsThatHaveTimoutBefore(date: timeout2)

        // Then
        XCTAssertEqual(result, Set([conversationA.objectID, conversationB.objectID]))
    }

    func testThatItRemovesUsersWhenPruning() {
        // Given
        let timeout1 = Date(timeIntervalSinceNow: 10)
        let timeout2 = Date(timeIntervalSinceNow: 15)
        let timeout3 = Date(timeIntervalSinceNow: 20)
        sut.add(userA, for: conversationA, withTimeout: timeout1)
        sut.add(userB, for: conversationA, withTimeout: timeout3)

        // When
        _ = sut.pruneConversationsThatHaveTimoutBefore(date: timeout2)

        // Then
        XCTAssertFalse(sut.contains(userA, for: conversationA))
        XCTAssertTrue(sut.contains(userB, for: conversationA))
        XCTAssertEqual(sut.userIds(in: conversationA), Set([userB.objectID]))
    }
}
