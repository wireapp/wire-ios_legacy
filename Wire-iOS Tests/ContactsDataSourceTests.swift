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
import UIKit
import XCTest
@testable import Wire

final class ContactsDataSourceTests: XCTestCase {

    var dataSource: ContactsDataSource!

    override func setUp() {
        super.setUp()
        Thread.sleep(forTimeInterval: 0.5)
        dataSource = ContactsDataSource()
    }

    override func tearDown() {
        dataSource = nil
        super.tearDown()
    }

    func testThatDataSourceHasCorrectNumberOfSectionsForSmallNumberOfUsers() {
        // GIVEN
        let mockUsers = SwiftMockLoader.mockUsers()
        // WHEN
        dataSource.ungroupedSearchResults = mockUsers

        // THEN
        let sections: Int? = dataSource.numberOfSections(in: UITableView())
        XCTAssertFalse(dataSource.shouldShowSectionIndex)
        XCTAssertEqual(sections, 1, "Number of sections must be 1")
    }

    func testThatDataSourceHasCorrectNumberOfSectionsForLargeNumberOfUsers() {
        // GIVEN
        let mockUsers = SwiftMockLoader.mockUsers(fromResource: "a_lot_of_people.json")

        // WHEN
        dataSource?.ungroupedSearchResults = mockUsers

        // THEN
        let sections: Int? = dataSource.numberOfSections(in: UITableView())
        XCTAssertTrue(dataSource.shouldShowSectionIndex)
        XCTAssertEqual(sections, 27, "Number of sections")
    }

    func testThatDataSourceHasCorrectNumbersOfRowsInSectionsForLargeNumberOfUsers() {
        // GIVEN
        let mockUsers = SwiftMockLoader.mockUsers(fromResource: "a_lot_of_people.json")

        // WHEN
        dataSource?.ungroupedSearchResults = mockUsers

        // THEN
        let numberOfRawsInFirstSection: Int? = dataSource?.tableView(UITableView(), numberOfRowsInSection: 0)
        XCTAssertEqual(numberOfRawsInFirstSection, 20, "")

        let numberOfSections: Int? = dataSource?.numberOfSections(in: UITableView())
        let numberOfRawsInLastSection: Int? = dataSource?.tableView(UITableView(), numberOfRowsInSection: (numberOfSections ?? 0) - 2)
        XCTAssertEqual(numberOfRawsInLastSection, 3, "")
    }

    func testPerformanceExample() {
        // GIVEN
        let mockUsers = SwiftMockLoader.mockUsers(fromResource: "a_lot_of_people.json")

        measure({
            // WHEN
            self.dataSource?.ungroupedSearchResults = mockUsers
        })
    }

}
