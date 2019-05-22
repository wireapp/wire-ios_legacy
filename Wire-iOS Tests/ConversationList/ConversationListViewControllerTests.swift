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

final class ConversationListViewControllerTests: CoreDataSnapshotTestCase {
    
    var sut: ConversationListViewController!
    
    override func setUp() {
        super.setUp()

        MockUser.mockSelf()?.name = "Johannes Chrysostomus Wolfgangus Theophilus Mozart"

        sut = ConversationListViewController()
        sut.account = Account.mockAccount(imageData: mockImageData)

        sut.view.backgroundColor = .black
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    //MARK: - View controller

    func testForNoConversations() {
        verify(view: sut.view)
    }

    //MARK: - PermissionDeniedViewController
    func testForPremissionDeniedViewController() {
        sut.showPermissionDeniedViewController()

        verify(view: sut.view)
    }

    //MARK: - Action menu
    func testForActionMenu() {
        teamTest {
            sut.showActionMenu(for: otherUserConversation, from: sut.view)
            verifyAlertController((sut?.actionsController?.alertController)!)
        }
    }

    func testForActionMenu_NoTeam() {
        nonTeamTest {
            sut.showActionMenu(for: otherUserConversation, from: sut.view)
            verifyAlertController((sut?.actionsController?.alertController)!)
        }
    }
}
