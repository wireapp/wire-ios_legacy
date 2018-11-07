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
 * A base test class for section-based messages. Use the section property to build
 * your layout and call `verifySectionSnapshots` to record and verify the snapshot.
 */

class ConversationCellSnapshotTests: CoreDataSnapshotTestCase {

    var section: ConversationMessageSectionController!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        section = nil
        super.tearDown()
    }

    /**
     * Performs a snapshot test for the current section controller.
     */

    func verifySectionSnapshots() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 0))
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 0

        tableView.dataSource = self.section
        tableView.delegate = self.section
        section.cellDescriptions.forEach { $0.register(in: tableView) }

        tableView.backgroundColor = .from(scheme: .contentBackground)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.widthAnchor.constraint(equalToConstant: 375).isActive = true

        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableView.bounds = CGRect(x: 0, y: 0, width: 375, height: tableView.contentSize.height)
        tableView.heightAnchor.constraint(equalToConstant: tableView.contentSize.height).isActive = true
        tableView.layoutIfNeeded()
        tableView.updateConstraints()

        verify(view: tableView)
    }

}

extension ConversationMessageSectionController: UITableViewDataSource, UITableViewDelegate {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfCells
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.makeCell(for: tableView, at: indexPath)
    }

}
