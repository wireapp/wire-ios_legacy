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

final class GroupDetailsViewControllerSnapshotTests: CoreDataSnapshotTestCase {
    
    var sut: GroupDetailsViewController!
    
    override func setUp() {
        super.setUp()


//        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()

        MockUser.mockSelf()?.teamRole = .member
    }

    func testForOptionsForTeamUserInNonTeamConversation() {
        teamTest {
            sut = GroupDetailsViewController(conversation: otherUserConversation)
            verify(view: sut.view)
        }
    }
    
    func testForOptionsForTeamUserInTeamConversation() {
        teamTest {
            otherUserConversation.team = selfUser.team
            sut = GroupDetailsViewController(conversation: otherUserConversation)
            verify(view: sut.view)
        }
    }

    func testForOptionsForNonTeamUser() {
        nonTeamTest {
            sut = GroupDetailsViewController(conversation: otherUserConversation)
            verify(view: self.sut.view)
        }
    }

    func testForActionMenu() {
        teamTest {
            sut = GroupDetailsViewController(conversation: otherUserConversation)
            sut.detailsView(GroupDetailsFooterView(), performAction: .more)
            verifyAlertController((sut?.actionController?.alertController)!)
        }
    }
    
    func testForActionMenu_NonTeam() {
        nonTeamTest {
            sut = GroupDetailsViewController(conversation: otherUserConversation)
            sut.detailsView(GroupDetailsFooterView(), performAction: .more)
            verifyAlertController((sut?.actionController?.alertController)!)
        }
    }
}
