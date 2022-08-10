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

import XCTest
@testable import Wire

final class UserSearchResultsViewControllerTests: ZMSnapshotTestCase {

    var sut: UserSearchResultsViewController!
    var serviceUser: MockServiceUserType!
    var selfUser: MockUserType!
    var otherUser: MockUserType!

    override func setUp() {
        super.setUp()

        // self user should be a team member and other participants should be guests, in order to show guest icon in the user cells
        SelfUser.setupMockSelfUser(inTeam: UUID())
        selfUser = (SelfUser.current as! MockUserType)
        otherUser = MockUserType.createDefaultOtherUser()

        serviceUser = MockServiceUserType.createServiceUser(name: "ServiceUser")

        XCTAssert(SelfUser.current.isTeamMember, "selfUser should be a team member to generate snapshots with guest icon")

    }

    func createSUT() {
        sut = UserSearchResultsViewController(nibName: nil, bundle: nil)

        sut.view.backgroundColor = .black
    }

    override func tearDown() {
        sut = nil

        selfUser = nil
        otherUser = nil
        serviceUser = nil

        resetColorScheme()

        super.tearDown()
    }

    // UI Tests

    func testThatShowsResultsInConversationWithEmptyQuery() {
        createSUT()
        sut.users = [selfUser, otherUser].searchForMentions(withQuery: "")
        verify(matching: sut)
    }

    func testThatShowsResultsInConversationWithQuery() {
        let createSut: () -> UIViewController = {
            self.createSUT()
            self.sut.users = [self.selfUser, self.otherUser].searchForMentions(withQuery: "u")

            return self.sut
        }

        verifyInAllColorSchemes(createSut: createSut)
    }

    func mockSearchResultUsers(file: StaticString = #file, line: UInt = #line) -> [UserType] {
        var allUsers: [UserType] = []

        for name in MockUserType.usernames {
            let user = MockUserType.createUser(name: name)
            user.accentColorValue = .brightOrange
            XCTAssertFalse(user.isTeamMember, "user should not be a team member to generate snapshots with guest icon", file: file, line: line)
            allUsers.append(user)
        }

        allUsers.append(selfUser)

        return allUsers.searchForMentions(withQuery: "")
    }

    func testThatItOverflowsWithTooManyUsers_darkMode() {
        ColorScheme.default.variant = .dark
        createSUT()
        sut.overrideUserInterfaceStyle = .dark

        sut.users = mockSearchResultUsers()
        verify(matching: sut)
    }

    func testThatHighlightedTopMostItemUpdatesAfterSelectedTopMostUser() {
        createSUT()

        sut.users = mockSearchResultUsers()

        let numberOfUsers = MockUserType.usernames.count

        for _ in 0..<numberOfUsers {
            sut.selectPreviousUser()
        }

        verify(matching: sut)
    }

    func testThatHighlightedItemStaysAtMiddleAfterSelectedAnUserAtTheMiddle() {
        createSUT()

        sut.users = mockSearchResultUsers()

        let numberOfUsers = MockUserType.usernames.count

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

        verify(matching: sut)
    }

    func testThatLowestItemIsNotHighlightedIfKeyboardIsNotCollapsed() {
        createSUT()
        sut.users = mockSearchResultUsers()

        // Post a mock show keyboard notification
        NotificationCenter.default.post(name: UIResponder.keyboardWillShowNotification, object: nil, userInfo: [
            UIResponder.keyboardFrameBeginUserInfoKey: CGRect(x: 0, y: 0, width: 0, height: 0),
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 0, height: 100),
            UIResponder.keyboardAnimationDurationUserInfoKey: TimeInterval(0.0)])

        verify(matching: sut)
    }

    func testThatItDoesNotCrashWithNoResults() {
        createSUT()
        // given
        let users: [UserType] = [selfUser, otherUser, serviceUser]
        sut.users = users.searchForMentions(withQuery: "u")

        // when
        sut.users = users.searchForMentions(withQuery: "362D00AE-B606-4680-BD47-F17749229E64")
    }

}
