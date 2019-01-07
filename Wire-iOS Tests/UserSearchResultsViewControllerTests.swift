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
        // self user should be a team member and other participants should be guests, in order to show guest icon in the user cells
        selfUserInTeam = true

        super.setUp()
        
        serviceUser = ZMUser.insertNewObject(in: uiMOC)
        serviceUser.remoteIdentifier = UUID()
        serviceUser.name = "ServiceUser"
        serviceUser.setHandle(name.lowercased())
        serviceUser.accentColorValue = .brightOrange
        serviceUser.serviceIdentifier = UUID.create().transportString()
        serviceUser.providerIdentifier = UUID.create().transportString()
        uiMOC.saveOrRollback()

        XCTAssert(ZMUser.selfUser().isTeamMember, "selfUser should be a team member to generate snapshots with guest icon")

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

    func mockSearchResultUsers(file: StaticString = #file, line: UInt = #line) -> [UserType] {
        var allUsers: [ZMUser] = []

        for name in usernames {
            let user = ZMUser.insertNewObject(in: uiMOC)
            user.remoteIdentifier = UUID()
            user.teamIdentifier = nil
            user.name = name
            user.setHandle(name.lowercased())
            user.accentColorValue = .brightOrange
            XCTAssertFalse(user.isTeamMember, "user should not be a team member to generate snapshots with guest icon", file: file, line: line)
            uiMOC.saveOrRollback()
            allUsers.append(user)
        }

        allUsers.append(selfUser)

        return ZMUser.searchForMentions(in: allUsers, with: "")
    }


    func testThatItOverflowsWithTooManyUsers_darkMode() {
        ColorScheme.default.variant = .dark
        createSUT()

        sut.users = mockSearchResultUsers()
        guard let view = sut.view else { XCTFail(); return }
        verify(view: view)
    }

    func testThatHighlightedTopMostItemUpdatesAfterSelectedTopMostUser() {
        createSUT()

        sut.users = mockSearchResultUsers()
        guard let view = sut.view else { XCTFail(); return }

        let numberOfUsers = usernames.count

        for _ in 0..<numberOfUsers {
            sut.selectPreviousUser()
        }

        verify(view: view)
    }

    func testThatHighlightedItemStaysAtMiddleAfterSelectedAnUserAtTheMiddle() {
        createSUT()

        sut.users = mockSearchResultUsers()
        guard let view = sut.view else { XCTFail(); return }

        let numberOfUsers = usernames.count

        // go to top most
        for _ in 0..<numberOfUsers+5 {
            sut.selectPreviousUser()
        }

        // go to bottom most
        for _ in 0..<numberOfUsers+5 {
            sut.selectNextUser()
        }

        // go to middle
        for _ in 0..<numberOfUsers/2 {
            sut.selectPreviousUser()
        }

        verify(view: view)
    }

    func testThatLowestItemIsNotHighlightedIfKeyboardIsNotCollapsed() {
        createSUT()
        sut.users = mockSearchResultUsers()
        guard let view = sut.view else { XCTFail(); return }

        ///post a mock show keyboard notification
        NotificationCenter.default.post(name: UIResponder.keyboardWillShowNotification, object: nil, userInfo: [
            UIResponder.keyboardFrameBeginUserInfoKey: CGRect(x: 0, y: 0, width: 0, height: 0),
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 0, height: 100),
            UIResponder.keyboardAnimationDurationUserInfoKey: TimeInterval(0.0)])


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
