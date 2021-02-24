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

final class ConversationListViewControllerViewModelSnapshotTests: XCTestCase {
    var sut: ConversationListViewController.ViewModel!
    var mockView: UIView!
    fileprivate var mockViewController: MockConversationListContainer!

    var coreDataFixture: CoreDataFixture!

    override func setUp() {
        super.setUp()
        
        coreDataFixture = CoreDataFixture()
        
        let account = Account.mockAccount(imageData: Data())
        let selfUser = MockUserType.createSelfUser(name: "Bob")
        sut = ConversationListViewController.ViewModel(account: account, selfUser: selfUser)
        
        mockViewController = MockConversationListContainer(viewModel: sut)
        
        sut.viewController = mockViewController
    }
    
    override func tearDown() {
        sut = nil
        mockView = nil
        mockViewController = nil
        coreDataFixture = nil

        super.tearDown()
    }
    
    //MARK: - Action menu
    func testForActionMenu() {
        coreDataFixture.teamTest {
            sut.showActionMenu(for: coreDataFixture.otherUserConversation, from: mockViewController.view)
            verify(matching: (sut?.actionsController?.alertController)!)
        }
    }

    func testForActionMenu_archive() {
        coreDataFixture.teamTest {
            coreDataFixture.otherUserConversation.isArchived = true
            sut.showActionMenu(for: coreDataFixture.otherUserConversation, from: mockViewController.view)
            verify(matching: (sut?.actionsController?.alertController)!)
        }
    }

    func testForActionMenu_NoTeam() {
        coreDataFixture.nonTeamTest {
            sut.showActionMenu(for: coreDataFixture.otherUserConversation, from: mockViewController.view)
            verify(matching: (sut?.actionsController?.alertController)!)
        }
    }
}
