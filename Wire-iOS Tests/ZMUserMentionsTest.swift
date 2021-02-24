//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
@testable import Wire

class ZMUserMentionsTest: XCTestCase {

    var selfUser: MockUserType!
    var otherUser: MockUserType!
    var serviceUser: MockUserType!

    override func setUp() {
        super.setUp()

        selfUser = MockUserType.createSelfUser(name: "selfUser")
        otherUser = MockUserType.createUser(name: "Bruno")
        serviceUser = MockServiceUserType.createServiceUser(name: "Mr. Bot")
    }

    override func tearDown() {
        selfUser = nil
        otherUser = nil
        serviceUser = nil

        super.tearDown()
    }

    func testThatItSearchesByName() {
        // given
        let userWithDifferentNameAndHandle = MockUserType.createUser(name: "user")
        userWithDifferentNameAndHandle.handle = "test"

        let users: [UserType] = [otherUser, userWithDifferentNameAndHandle]

        // when
        let results = users.searchForMentions(withQuery: "user").map(HashBox.init)

        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results.contains(HashBox(value: otherUser)))
        XCTAssertTrue(results.contains(HashBox(value: userWithDifferentNameAndHandle)))
    }

    func testThatItSearchesByHandle() {
        // given
        let userWithDifferentNameAndHandle = MockUserType.createUser(name: "user")
        userWithDifferentNameAndHandle.handle = "test"

        let users: [UserType] = [otherUser, userWithDifferentNameAndHandle]

        // when
        let results = users.searchForMentions(withQuery: "test").map(HashBox.init)

        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results.contains(HashBox(value: otherUser)))
        XCTAssertTrue(results.contains(HashBox(value: userWithDifferentNameAndHandle)))
    }

    func testThatSelfUserIsNotIncludedWithEmptyQuery() {
        // given
        let users: [UserType] = [selfUser, otherUser]

        // when
        let results = users.searchForMentions(withQuery: "").map(HashBox.init)

        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(HashBox(value: otherUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }

    func testThatSelfUserIsNotIncludedWithQuery() {
        // given
        let users: [UserType] = [selfUser, otherUser]

        // when
        let results = users.searchForMentions(withQuery: "u").map(HashBox.init)

        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(HashBox(value: otherUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }

    func testThatConversationWithServiceUserDoesntReturnUsersWithEmptyQuery() {
        // given
        let users: [UserType] = [selfUser, serviceUser]

        // when
        let results = users.searchForMentions(withQuery: "").map(HashBox.init)

        // then
        XCTAssertEqual(results.count, 0)
        XCTAssertFalse(results.contains(HashBox(value: serviceUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }

    func testThatConversationWithServiceUserDoesntReturnUsersWithQuery() {
        // given
        let users: [UserType] = [selfUser, serviceUser]

        // when
        let results = users.searchForMentions(withQuery: "u").map(HashBox.init)

        // then
        XCTAssertEqual(results.count, 0)
        XCTAssertFalse(results.contains(HashBox(value: serviceUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }

    func testThatSelfAndServiceUsersAreNotIncludedWithEmptyQuery() {
        // given
        let users: [UserType] = [selfUser, otherUser, serviceUser]

        // when
        let results = users.searchForMentions(withQuery: "").map(HashBox.init)

        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(HashBox(value: otherUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }

    func testThatSelfAndServiceUsersAreNotIncludedWithQuery() {
        // given
        let users: [UserType] = [selfUser, otherUser, serviceUser]

        // when
        let results = users.searchForMentions(withQuery: "u").map(HashBox.init)

        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(HashBox(value: otherUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }

    func testThatItFindsUsersWithEmoji() {
        // GIVEN
        let mockUserWithEmoji = MockUserType.createUser(name: "😀 Hello world")
        let users: [UserType] = [mockUserWithEmoji]

        // WHEN
        let results = users.searchForMentions(withQuery: "😀 hello")

        // THEN
        XCTAssertEqual(results.map(HashBox.init), users.map(HashBox.init))
    }

    func testThatItFindsUsersWithPunctuation() {
        // GIVEN
        let mockUser = MockUserType.createUser(name: "@ööö")
        let users: [UserType] = [mockUser]

        // WHEN
        let results = users.searchForMentions(withQuery: "@o")

        // THEN
        XCTAssertEqual(results.map(HashBox.init), users.map(HashBox.init))
    }
}
