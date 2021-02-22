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

import SnapshotTesting
import XCTest
@testable import Wire

final class MockConversationList: ConversationListHelperType {
    static var hasArchivedConversations: Bool = false
}

final class ConversationListViewControllerTests: XCTestCase {

    var sut: ConversationListViewController!

    override func setUp() {
        super.setUp()

        MockConversationList.hasArchivedConversations = false
        let selfUser = MockUserType.createSelfUser(name: "Johannes Chrysostomus Wolfgangus Theophilus Mozart", inTeam: UUID())
        let account = Account.mockAccount(imageData: mockImageData)
        let viewModel = ConversationListViewController.ViewModel(account: account, selfUser: selfUser, conversationListType: MockConversationList.self)
        sut = ConversationListViewController(viewModel: viewModel)
        viewModel.viewController = sut

        sut.view.backgroundColor = .black
    }

    override func tearDown() {
        sut = nil
        super.tearDown()

    }

    //MARK: - View controller

    func testForNoConversations() {
        verify(matching: sut)
    }

    func testForEverythingArchived() {
        MockConversationList.hasArchivedConversations = true
        sut.showNoContactLabel(animated: false)

        verify(matching: sut)
    }

    //MARK: - PermissionDeniedViewController
    func testForPremissionDeniedViewController() {
        sut.showPermissionDeniedViewController()

        verify(matching: sut)
    }
}
