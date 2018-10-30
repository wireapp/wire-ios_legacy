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

import Foundation

/**
 * An object that provides an interface to build list sections for a single message.
 *
 * A message will be represented as a table/collection section, and the components that make
 * the view of the message (timestamp, reply, content...) will be displayed as individual cells,
 * to reduce the number of cells that are instanciated at a given time.
 *
 * To achieve this, each section controller is assigned a cell description, that is responsible dequeing
 * the cells from the table or collection view and configure them with a message.
 */

@objc class ConversationMessageSectionController: NSObject {

    /// The view descriptor of the section.
    @objc var cellDescriptions: [AnyConversationMessageCellDescription] = []

    /// Whether we need to use inverted indices. This is `true` when the table view is upside down.
    @objc var useInvertedIndices = false

    /// The delegate for cells injected by the list adapter.
    @objc var delegate: ConversationCellDelegate?

    /// The object that controls actions for the cell.
    @objc var actionController: ConversationCellActionController?

    /// The message that is being presented.
    @objc var message: ZMConversationMessage?

    /**
     * Adds a cell description to the section.
     * - parameter description: The cell to add to the message section.
     */

    func add<T: ConversationMessageCellDescription>(description: T) {
        cellDescriptions.append(AnyConversationMessageCellDescription(description))
    }


    /// The number of child cells in the section that compose the message.
    var numberOfCells: Int {
        return cellDescriptions.count
    }

    /**
     * Create the cell for the child cell at the given index path.
     * It is the responsibility of the section description to determine what the `row` represents,
     * to dequeue the appropriate cell, and to configure it with a message.
     * - parameter tableView: The table view where the cell will be displayed.
     * - parameter indexPath: The index path of the child cell that will be displayed. Use the `row` property
     * to determine the type of child cell that needs to be displayed.
     */

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let description = cellDescription(at: indexPath.row)
        description.delegate = self.delegate
        description.message = self.message

        let cell = description.makeCell(for: tableView, at: indexPath)
        return cell
    }

    /**
     * Returns the cell description at the specified index, taking the upside down table into account.
     * - parameter row: The raw row index as specified by the table.
     */

    func cellDescription(at row: Int) -> AnyConversationMessageCellDescription {
        if useInvertedIndices {
            return cellDescriptions[(numberOfCells - 1) - row]
        } else {
            return cellDescriptions[row]
        }
    }

}
