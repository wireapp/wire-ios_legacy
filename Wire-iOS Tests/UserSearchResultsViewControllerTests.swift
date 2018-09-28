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

class UserSearchResultsViewControllerTests: CoreDataSnapshotTestCase {

    var sut: UserSearchResultsViewController!
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
    }
    
    func createSUT() {
        sut = UserSearchResultsViewController(nibName: nil, bundle: nil)
        
        sut.view.layoutIfNeeded()
        
        sut.view.backgroundColor = .black
        sut.view.layer.speed = 0
    }
    
    override func tearDown() {
        sut = nil
        serviceUser = nil
        resetColorScheme()
        super.tearDown()
    }
    
    // UI Tests
    
    func testThatShowsResultsInConversationWithEmptyQuery() {
        createSUT()
        sut.users = ZMUser.searchForMentions(in: [selfUser, otherUser], with: "")
        guard let view = sut.view else { XCTFail(); return }
        verify(view: view)
    }

    func testThatShowsResultsInConversationWithQuery() {
        createSUT()
        sut.users = ZMUser.searchForMentions(in: [selfUser, otherUser], with: "u")
        guard let view = sut.view else { XCTFail(); return }
        verify(view: view)
    }
    
    func testThatShowsResultsInConversationWithQuery_DarkMode() {
        ColorScheme.default.variant = .dark
        createSUT()
        sut.users = ZMUser.searchForMentions(in: [selfUser, otherUser], with: "u")
        guard let view = sut.view else { XCTFail(); return }
        verify(view: view)
    }
    
    func testThatItOverflowsWithTooManyUsers() {
        createSUT()
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
        
        sut.users = ZMUser.searchForMentions(in: allUsers, with: "")
        guard let view = sut.view else { XCTFail(); return }
        verify(view: view)
    }

    func testThatItDoesNotCrashWithNoResults() {
        createSUT()
        // given
        let users: [UserType] = [selfUser, otherUser, serviceUser]
        sut.users = ZMUser.searchForMentions(in: users, with: "u")
        
        // when
        sut.users = ZMUser.searchForMentions(in: users, with: "362D00AE-B606-4680-BD47-F17749229E64")
    }
    
}
