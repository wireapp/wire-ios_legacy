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

final class MockConversationListDelegate: ConversationListTabBarControllerDelegate {
    func didChangeTab(with type: TabBarItemType) {
        switch type {
        case .archive:
            self.archiveTabCallCount += 1
        case .startUI:
            self.startUITabCallCount += 1
        case .list:
            self.listTabCallCount += 1
        case .folder:
            self.folderTabCallCount += 1
        }
    }

    var startUITabCallCount: Int = 0
    var archiveTabCallCount: Int = 0
    var listTabCallCount: Int = 0
    var folderTabCallCount: Int = 0
}

final class ConversationListViewControllerTests: ZMSnapshotTestCase {

    var sut: ConversationListViewController!
    var mockDelegate: MockConversationListDelegate!

    override func setUp() {
        super.setUp()
        accentColor = .strongBlue

        MockConversationList.hasArchivedConversations = false
        let selfUser = MockUserType.createSelfUser(name: "Johannes Chrysostomus Wolfgangus Theophilus Mozart", inTeam: UUID())
        let account = Account.mockAccount(imageData: mockImageData)
        let viewModel = ConversationListViewController.ViewModel(account: account, selfUser: selfUser, conversationListType: MockConversationList.self)
        sut = ConversationListViewController(viewModel: viewModel)
        viewModel.viewController = sut
        sut.onboardingHint.arrowPointToView = sut.tabBar
        sut.overrideUserInterfaceStyle = .dark
        sut.view.backgroundColor = .black
        mockDelegate = MockConversationListDelegate()
        sut.delegate = self.mockDelegate
    }

    override func tearDown() {
        sut = nil
        mockDelegate = nil

        super.tearDown()

    }

    // MARK: - View controller

    func testForNoConversations() {
        verify(matching: sut)
    }

    func testForEverythingArchived() {
        MockConversationList.hasArchivedConversations = true
        sut.showNoContactLabel(animated: false)

        verify(matching: sut)
    }

    // MARK: - PermissionDeniedViewController
    func testForPremissionDeniedViewController() {
        sut.showPermissionDeniedViewController()

        verify(matching: sut)
    }

    // MARK: - TabBar actions
    func testThatItCallsTheDelegateWhenTheContactsTabIsTapped() {
        // when
        let item = UITabBarItem(type: .startUI)
        sut.tabBar(sut.tabBar, didSelect: item)

        // then
        XCTAssertEqual(mockDelegate.startUITabCallCount, 1)
    }

    func testThatItCallsTheDelegateWhenTheArchivedTabIsTapped() {
        // when
        let item = UITabBarItem(type: .archive)
        sut.tabBar(sut.tabBar, didSelect: item)

        // then
        XCTAssertEqual(mockDelegate.archiveTabCallCount, 1)
    }

    func testThatItCallsTheDelegateWhenTheListTabIsTapped() {
        // when
        let item = UITabBarItem(type: .list)
        sut.tabBar(sut.tabBar, didSelect: item)

        // then
        XCTAssertEqual(mockDelegate.listTabCallCount, 1)
    }

    func testThatItCallsTheDelegateWhenTheFolderTabIsTapped() {
        // when
        let item = UITabBarItem(type: .folder)
        sut.tabBar(sut.tabBar, didSelect: item)

        // then
        XCTAssertEqual(mockDelegate.folderTabCallCount, 1)
    }

}
