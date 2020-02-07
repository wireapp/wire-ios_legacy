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
import SnapshotTesting

final class ContactsViewControllerSnapshotTests: XCTestCase {

    var sut: ContactsViewController!

    override func setUp() {
        super.setUp()
        ColorScheme.default.variant = .dark
        sut = ContactsViewController()
        sut.view.backgroundColor = .black
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForNoContacts() {
        // Given
        sut.dataSource.ungroupedSearchResults = []

        // When
        simulateSearch(withResults: false)

        // Then
        wrapInNavigationController()
        verify(matching: sut)
    }

    func testForNoSearchResult() {
        // Given
        sut.dataSource.searchQuery = "!!!"

        // When
        simulateSearch(withResults: false)

        // Then
        wrapInNavigationController()
        verify(matching: sut)
    }

    func testForContactsWithoutSections() {
        // Given
        sut.dataSource.ungroupedSearchResults = MockUser.mockUsers()

        // When
        simulateSearch(withResults: true)

        // Then
        wrapInNavigationController()
        verify(matching: sut)
    }

    ///TODO: restore this after fixed Alert tests in SwiftSnapshot
    /// CI server produce empty snapshot but it works on local machine. It seems the alert with type UIAlertControllerStyleAlert is not shown on CI server.
    /*
    func DISABLE_testForNoEmailClientAlert() {
        let contact = ZMAddressBookContact()

        guard let alert = sut.invite(contact, from: UIView()) else {
            return XCTFail("No alert generated for the contact.")
        }

        verifyAlertController(alert)
    }*/

    func testForContactsAndIndexSectionBarAreShown() {
        // Given
        let mockUsers = MockLoader.mockObjects(of: MockUser.self, fromFile: "people-15Sections.json") as? [MockUser]
        sut.dataSource.ungroupedSearchResults = mockUsers ?? []

        // When
        simulateSearch(withResults: true)

        // Then
        wrapInNavigationController()
        verify(matching: sut)
    }

    private func simulateSearch(withResults: Bool) {
        sut.updateEmptyResults(hasResults: withResults)
    }

    private func wrapInNavigationController() {
        let navigationController = UIViewController().wrapInNavigationController(ClearBackgroundNavigationController.self)
        navigationController.pushViewController(sut, animated: false)

        sut.viewWillAppear(false)
        sut.tableView.reloadData()
    }
}
