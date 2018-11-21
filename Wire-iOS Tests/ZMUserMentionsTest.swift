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
    
    var selfUser: MockUser!
    var otherUser: MockUser!
    var serviceUser: MockUser!
    
    override func setUp() {
        super.setUp()
        
        let mockUsers = MockUser.realMockUsers()!
        
        selfUser = MockUser.mockSelf()
        selfUser.name = "selfUser"
        
        otherUser = mockUsers[0]
        otherUser.name = "Bruno"
        
        serviceUser = mockUsers[1]
        serviceUser.isServiceUser = true

        MockUser.setMockSelf(selfUser)
    }
    
    override func tearDown() {
        selfUser = nil
        otherUser = nil
        serviceUser = nil

        MockUser.setMockSelf(nil)

        super.tearDown()
    }
    
    func testThatItSearchesByName() {
        // given
        let userWithDifferentNameAndHandle = MockUser.realMockUsers()![2]
        userWithDifferentNameAndHandle.name = "user"
        userWithDifferentNameAndHandle.handle = "test"
        
        let users: [UserType] = [otherUser, userWithDifferentNameAndHandle]
        
        // when
        let results = ZMUser.searchForMentions(in: users, with: "user").map(HashBox.init)
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results.contains(HashBox(value: otherUser)))
        XCTAssertTrue(results.contains(HashBox(value: userWithDifferentNameAndHandle)))
    }
    
    func testThatItSearchesByHandle() {
        // given
        let userWithDifferentNameAndHandle = MockUser.realMockUsers()![2]
        userWithDifferentNameAndHandle.name = "user"
        userWithDifferentNameAndHandle.handle = "test"
        
        let users: [UserType] = [otherUser, userWithDifferentNameAndHandle]
        
        // when
        let results = ZMUser.searchForMentions(in: users, with: "test").map(HashBox.init)
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results.contains(HashBox(value: otherUser)))
        XCTAssertTrue(results.contains(HashBox(value: userWithDifferentNameAndHandle)))
    }
    
    func testThatSelfUserIsNotIncludedWithEmptyQuery() {
        // given
        let users: [UserType] = [selfUser, otherUser]
        
        // when
        let results = ZMUser.searchForMentions(in: users, with: "").map(HashBox.init)
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(HashBox(value: otherUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }
    
    func testThatSelfUserIsNotIncludedWithQuery() {
        // given
        let users: [UserType] = [selfUser, otherUser]
        
        // when
        let results = ZMUser.searchForMentions(in: users, with: "u").map(HashBox.init)
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(HashBox(value: otherUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }
    
    func testThatConversationWithServiceUserDoesntReturnUsersWithEmptyQuery() {
        // given
        let users: [UserType] = [selfUser, serviceUser]
        
        // when
        let results = ZMUser.searchForMentions(in: users, with: "").map(HashBox.init)
        
        // then
        XCTAssertEqual(results.count, 0)
        XCTAssertFalse(results.contains(HashBox(value: serviceUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }
    
    func testThatConversationWithServiceUserDoesntReturnUsersWithQuery() {
        // given
        let users: [UserType] = [selfUser, serviceUser]
        
        // when
        let results = ZMUser.searchForMentions(in: users, with: "u").map(HashBox.init)
        
        // then
        XCTAssertEqual(results.count, 0)
        XCTAssertFalse(results.contains(HashBox(value: serviceUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }
    
    func testThatSelfAndServiceUsersAreNotIncludedWithEmptyQuery() {
        // given
        let users: [UserType] = [selfUser, otherUser, serviceUser]
        
        // when
        let results = ZMUser.searchForMentions(in: users, with: "").map(HashBox.init)
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(HashBox(value: otherUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }
    
    func testThatSelfAndServiceUsersAreNotIncludedWithQuery() {
        // given
        let users: [UserType] = [selfUser, otherUser, serviceUser]
        
        // when
        let results = ZMUser.searchForMentions(in: users, with: "u").map(HashBox.init)
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(HashBox(value: otherUser)))
        XCTAssertFalse(results.contains(HashBox(value: selfUser)))
    }
    
    func testThatItFindsUsersWithEmoji() {
        // GIVEN
        let mockUserWithEmoji = MockUser.realMockUsers()![0]
        mockUserWithEmoji.name = "😀 Hello world"
        
        let users: [UserType] = [mockUserWithEmoji]
        
        // WHEN
        let results = ZMUser.searchForMentions(in: users, with: "😀 hello")
        
        // THEN
        XCTAssertEqual(results.map(HashBox.init), users.map(HashBox.init))
    }
    
    func testThatItFindsUsersWithPunctuation() {
        // GIVEN
        let mockUser = MockUser.realMockUsers()![0]
        mockUser.name = "@ööö"
        
        let users: [UserType] = [mockUser]
        
        // WHEN
        let results = ZMUser.searchForMentions(in: users, with: "@o")
        
        // THEN
        XCTAssertEqual(results.map(HashBox.init), users.map(HashBox.init))
    }
}
