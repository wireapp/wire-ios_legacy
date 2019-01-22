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
    var groupConversation: ZMConversation!
    
    override func setUp() {
        super.setUp()
        
        // Note, we explicitly don't add participants. Why? The participants
        // list in the group details requires the shared user session, which
        // isn't configured in these tests. As such, the participants list
        // is missing from these snapshots.
        // TODO: include participants list.
        groupConversation = ZMConversation.insertNewObject(in: uiMOC)
        groupConversation.remoteIdentifier = UUID.create()
        groupConversation.conversationType = .group
        groupConversation.userDefinedName = "iOS Team"
    }
    
    override func tearDown() {
        sut = nil
        groupConversation = nil
        super.tearDown()
    }
    
    func testForOptionsForTeamUserInNonTeamConversation() {
        teamTest {
            selfUser.membership?.setTeamRole(.member)
            sut = GroupDetailsViewController(conversation: groupConversation)
            verify(view: sut.view)
        }
    }
    
    func testForOptionsForTeamUserInNonTeamConversation_Partner() {
        teamTest {
            selfUser.membership?.setTeamRole(.collaborator)
            sut = GroupDetailsViewController(conversation: groupConversation)
            verify(view: sut.view)
        }
    }
    
    func testForOptionsForTeamUserInTeamConversation() {
        teamTest {
            selfUser.membership?.setTeamRole(.member)
            groupConversation.team =  selfUser.team
            groupConversation.teamRemoteIdentifier = selfUser.team?.remoteIdentifier
            sut = GroupDetailsViewController(conversation: groupConversation)
            verify(view: sut.view)
        }
    }
    
    func testForOptionsForTeamUserInTeamConversation_Partner() {
        teamTest {
            selfUser.membership?.setTeamRole(.collaborator)
            groupConversation.team =  selfUser.team
            groupConversation.teamRemoteIdentifier = selfUser.team?.remoteIdentifier
            sut = GroupDetailsViewController(conversation: groupConversation)
            verify(view: sut.view)
        }
    }

    func testForOptionsForNonTeamUser() {
        nonTeamTest {
            sut = GroupDetailsViewController(conversation: groupConversation)
            verify(view: self.sut.view)
        }
    }

    func testForActionMenu() {
        // TODO: the menu is missing "mark unread" option at top
        teamTest {
            sut = GroupDetailsViewController(conversation: groupConversation)
            sut.detailsView(GroupDetailsFooterView(), performAction: .more)
            verifyAlertController((sut?.actionController?.alertController)!)
        }
    }
    
    func testForActionMenu_NonTeam() {
        // TODO: the menu is missing "mark unread" option at top
        nonTeamTest {
            sut = GroupDetailsViewController(conversation: groupConversation)
            sut.detailsView(GroupDetailsFooterView(), performAction: .more)
            verifyAlertController((sut?.actionController?.alertController)!)
        }
    }
}
