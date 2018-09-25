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

class MentionsSearchResultsViewControllerTests: CoreDataSnapshotTestCase {

    var sut: MentionsSearchResultsViewController!
    var serviceUser: ZMUser!
    
    override func setUp() {
        super.setUp()
        
        serviceUser = ZMUser.insertNewObject(in: uiMOC)
        serviceUser.remoteIdentifier = UUID()
        serviceUser.name = "ServiceUser"
        serviceUser.setHandle(name.lowercased())
        serviceUser.accentColorValue = .brightOrange
        serviceUser.serviceIdentifier = UUID.create().transportString()
        serviceUser.providerIdentifier = UUID.create().transportString()
        uiMOC.saveOrRollback()
        
        sut = MentionsSearchResultsViewController(nibName: nil, bundle: nil)
        
        sut.view.layoutIfNeeded()
        
        sut.view.backgroundColor = .black
        sut.view.layer.speed = 0
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // Tests
    
    func testThatItSearchesByName() {
        // given
        let userWithDifferentNameAndHandle = ZMUser.insertNewObject(in: uiMOC)
        userWithDifferentNameAndHandle.remoteIdentifier = UUID()
        userWithDifferentNameAndHandle.name = "user"
        userWithDifferentNameAndHandle.setHandle("test")
        
        let users = [otherUser, userWithDifferentNameAndHandle]
        
        // when
        let results = sut.search(in: users as! [ZMUser], with: "user")
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results.contains(otherUser))
        XCTAssertTrue(results.contains(userWithDifferentNameAndHandle))
    }
    
    func testThatItSearchesByHandle() {
        // given
        let userWithDifferentNameAndHandle = ZMUser.insertNewObject(in: uiMOC)
        userWithDifferentNameAndHandle.remoteIdentifier = UUID()
        userWithDifferentNameAndHandle.name = "user"
        userWithDifferentNameAndHandle.setHandle("test")
        
        let users = [otherUser, userWithDifferentNameAndHandle]
        
        // when
        let results = sut.search(in: users as! [ZMUser], with: "test")
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results.contains(otherUser))
        XCTAssertTrue(results.contains(userWithDifferentNameAndHandle))
    }
    
    func testThatSelfUserIsNotIncludedWithEmptyQuery() {
        // given
        let users = [selfUser, otherUser]
        
        // when
        let results = sut.search(in: users as! [ZMUser], with: "")
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(otherUser))
        XCTAssertFalse(results.contains(selfUser))
    }
    
    func testThatSelfUserIsNotIncludedWithQuery() {
        // given
        let users = [selfUser, otherUser]
        
        // when
        let results = sut.search(in: users as! [ZMUser], with: "u")
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(otherUser))
        XCTAssertFalse(results.contains(selfUser))
    }
    
    func testThatConversationWithServiceUserDoesntReturnUsersWithEmptyQuery() {
        // given
        let users = [selfUser, serviceUser]
        
        // when
        let results = sut.search(in: users as! [ZMUser], with: "")
        
        // then
        XCTAssertEqual(results.count, 0)
        XCTAssertFalse(results.contains(serviceUser))
        XCTAssertFalse(results.contains(selfUser))
    }
    
    func testThatConversationWithServiceUserDoesntReturnUsersWithQuery() {
        // given
        let users = [selfUser, serviceUser]
        
        // when
        let results = sut.search(in: users as! [ZMUser], with: "u")
        
        // then
        XCTAssertEqual(results.count, 0)
        XCTAssertFalse(results.contains(serviceUser))
        XCTAssertFalse(results.contains(selfUser))
    }
    
    func testThatSelfAndServiceUsersAreNotIncludedWithEmptyQuery() {
        // given
        let users = [selfUser, otherUser, serviceUser]
        
        // when
        let results = sut.search(in: users as! [ZMUser], with: "")
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(otherUser))
        XCTAssertFalse(results.contains(selfUser))
    }
    
    func testThatSelfAndServiceUsersAreNotIncludedWithQuery() {
        // given
        let users = [selfUser, otherUser, serviceUser]
        
        // when
        let results = sut.search(in: users as! [ZMUser], with: "u")
        
        // then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.contains(otherUser))
        XCTAssertFalse(results.contains(selfUser))
    }
    
    // UI Tests
    
    func testThatShowsResultsInConversationWithEmptyQuery() {
        sut.search(in: [selfUser, otherUser], with: "")
        guard let view = sut.view else { XCTFail(); return }
        verify(view: view)
    }

    func testThatShowsResultsInConversationWithQuery() {
        sut.search(in: [selfUser, otherUser], with: "u")
        guard let view = sut.view else { XCTFail(); return }
        verify(view: view)
    }
    
    func testThatItOverflowsWithTooManyUsers() {
        var allUsers: [ZMUser] = []
        
        for name in usernames {
            let user = ZMUser.insertNewObject(in: uiMOC)
            user.remoteIdentifier = UUID()
            user.name = name
            user.setHandle(name.lowercased())
            user.accentColorValue = .brightOrange
            uiMOC.saveOrRollback()
            allUsers.append(user)
        }
        
        allUsers.append(selfUser)
        
        sut.search(in: allUsers, with: "")
        guard let view = sut.view else { XCTFail(); return }
        verify(view: view)
    }
    
    
}
