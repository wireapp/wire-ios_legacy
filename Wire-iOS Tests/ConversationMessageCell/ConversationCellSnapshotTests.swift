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

/**
 * A base test class for . Use tge
 */

class ConversationCellSnapshotTests: CoreDataSnapshotTestCase {

    var section: ConversationMessageSectionController!

    override func setUp() {
        super.setUp()
        section = ConversationMessageSectionController()
    }

    override func tearDown() {
        section = nil
        super.tearDown()
    }

    /**
     * Performs a snapshot test for the current section controller.
     */

    func verifySectionSnapshots() {
        let container = UIView()
        let tableView = UITableView()

        container.backgroundColor = .contentBackground

        var lastTopAnchor = container.topAnchor

        for (index, section) in section.cellDescriptions.enumerated() {
            section.register(in: tableView)
            let indexPath = IndexPath(row: index, section: 0)
            let cell = section.makeCell(for: tableView, at: indexPath)

            container.addSubview(cell)

            NSLayoutConstraint.activate([
                cell.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                cell.topAnchor.constraint(equalTo: lastTopAnchor),
                cell.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            ])

            lastTopAnchor = cell.bottomAnchor
        }

        container.bottomAnchor.constraint(equalTo: lastTopAnchor)
        verifyInAllPhoneWidths(view: container)
    }

}
