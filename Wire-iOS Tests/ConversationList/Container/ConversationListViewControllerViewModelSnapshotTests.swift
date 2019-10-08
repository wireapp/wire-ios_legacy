//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class ConversationListViewControllerViewModelSnapshotTests: CoreDataSnapshotTestCase {
    var sut: ConversationListViewController.ViewModel!
    var mockView: UIView!
    fileprivate var mockViewController: MockConversationListContainer!
    
    override func setUp() {
        super.setUp()
        
        let account = Account.mockAccount(imageData: Data())
        sut = ConversationListViewController.ViewModel(account: account, selfUser: MockUser.mockSelf())
        
        mockViewController = MockConversationListContainer(viewModel: sut)
        
        sut.viewController = mockViewController

        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        mockView = nil
        mockViewController = nil
        
        super.tearDown()
    }
    
    //MARK: - Action menu
    func testForActionMenu() {
        teamTest {
            sut.showActionMenu(for: otherUserConversation, from: mockViewController.view)
            verifyAlertController((sut?.actionsController?.alertController)!)
        }
    }

    func testForActionMenu_archive() {
        teamTest {
            otherUserConversation.isArchived = true
            sut.showActionMenu(for: otherUserConversation, from: mockViewController.view)
            verifyAlertController((sut?.actionsController?.alertController)!)
        }
    }

    func testForActionMenu_removeFolder() {
        teamTest {
            let mockLabel = Label()
            mockLabel.name = "Test Folder"
            otherUserConversation.labels = [mockLabel]

            sut.showActionMenu(for: otherUserConversation, from: mockViewController.view)
            verifyAlertController((sut?.actionsController?.alertController)!)
        }
    }

    func testForActionMenu_NoTeam() {
        nonTeamTest {
            sut.showActionMenu(for: otherUserConversation, from: mockViewController.view)
            verifyAlertController((sut?.actionsController?.alertController)!)
        }
    }
}
