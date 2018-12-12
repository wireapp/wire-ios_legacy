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

final class InviteContactsViewControllerSnapshotTests: ZMSnapshotTestCase {

    var sut: InviteContactsViewController!

    override func setUp() {
        super.setUp()
        sut = InviteContactsViewController()
        sut.shouldShowShareContactsViewController = false
        sut.view.backgroundColor = .black
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    fileprivate func wrapInNavigationControllerWithDummyPerviousViewController() {

        let navigationController = UIViewController().wrapInNavigationController(ClearBackgroundNavigationController.self)

        navigationController.pushViewController(sut, animated: false)

        sut.viewWillAppear(false)

        sut.tableView?.reloadData()
        sut.updateEmptyResults()
    }

    fileprivate func snapshotWithNavigationBarWithBackButton(file: StaticString = #file, line: UInt = #line) {
        wrapInNavigationControllerWithDummyPerviousViewController()

        verify(view: sut.view)
    }

    func testForNoContacts() {
        snapshotWithNavigationBarWithBackButton()
    }

    func testForNoSearchResult() {
        sut.searchResultsReceived = true

        snapshotWithNavigationBarWithBackButton()
    }

    func testForContactsWithoutSectionBar() {
        let mockUsers = MockUser.mockUsers()
        sut.dataSource?.ungroupedSearchResults = mockUsers

        snapshotWithNavigationBarWithBackButton()
    }

    /// CI server produce empty snapshot but it works on local machine. It seems the alert with type UIAlertControllerStyleAlert is not shown on CI server.
    func DISABLE_testForNoEmailClientAlert() {
        let contact = ZMAddressBookContact()

        let alert = sut.invite(contact, from: UIView())

        verifyAlertController(alert)
    }

    func testForContactsAndIndexSectionBarAreShown() {
        let mockUsers = MockLoader.mockObjects(of: MockUser.self, fromFile: "people-15Sections.json")
        sut.dataSource?.ungroupedSearchResults = mockUsers

        snapshotWithNavigationBarWithBackButton()
    }
}

