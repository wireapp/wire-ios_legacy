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

final class CountryCodeTableViewControllerTests: ZMSnapshotTestCase {
    
    var sut: CountryCodeTableViewController!
    
    override func setUp() {
        super.setUp()
        sut = CountryCodeTableViewController()
        sut.viewDidLoad()

        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }


    func testForRowKosovo(){
        // GIVEN

        // WHEN
        var kosovoIndexPath: IndexPath!

        for section in 0..<sut.tableView.numberOfSections {
            let numberOfRows = sut.tableView.numberOfRows(inSection: section)
            for row in 0..<numberOfRows {
                let indexPath = IndexPath(row: row, section: section)
                if let cell = sut.tableView.cellForRow(at: indexPath), cell.textLabel?.text == "Kosovo" {
                    kosovoIndexPath = indexPath
                    break
                }
            }

            if kosovoIndexPath != nil {
                break
            }
        }

        sut.tableView.scrollToRow(at: kosovoIndexPath, at: .middle, animated: false)

        // THEN
        verify(view: sut.view)
    }
}
