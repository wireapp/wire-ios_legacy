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

class GroupDetailsViewControllerSnapshotTests: CoreDataSnapshotTestCase {
    
    var sut: GroupDetailsViewController!
    
    override func setUp() {
        super.setUp()
        sut = GroupDetailsViewController(conversation: otherUserConversation)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForInitState(){
        verify(view: sut.view)
    }

    func testForActionMenu() {
        sut.detailsView(GroupDetailsFooterView(), performAction: .more)
        verifyAlertController((sut?.actionController?.alertController)!)
    }
    
    func testForInitState_NonTeam() {
        nonTeamTest {
            verify(view: self.sut.view)
        }
    }
    
    func testForActionMenu_NonTeam() {
        nonTeamTest {
            self.sut.detailsView(GroupDetailsFooterView(), performAction: .more)
            verifyAlertController((self.sut?.actionController?.alertController)!)
        }
    }
    
    private func nonTeamTest(_ block: () -> Void) {
        let mockSelf = MockUser.mockSelf()
        mockSelf?.isTeamMember = false
        block()
        mockSelf?.isTeamMember = true
    }
}
