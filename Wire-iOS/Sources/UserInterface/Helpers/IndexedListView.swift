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

import UIKit

/**
 * A view that displays a list of cells that can be accessed by their index.
 */
protocol IndexedListView {
    /// The number of sections in the list.
    var numberOfSections: Int { get }
    /// The number of cells in the specified section of the list.
    func numberOfCells(inSection section: Int) -> Int
}

extension IndexedListView {

    /**
     * Checks whether the indexed list view contains an item at the given index path.
     * - parameter indexPath: The index path to check.
     */

    func containsCell(at indexPath: IndexPath) -> Bool {
        if indexPath.section < 0 || indexPath.section >= numberOfSections {
            return false
        }
        if indexPath.row < 0 || indexPath.row >= numberOfCells(inSection: indexPath.section) {
            return false
        }
        return true
    }

}

extension UITableView: IndexedListView {
    func numberOfCells(inSection section: Int) -> Int {
        return numberOfRows(inSection: section)
    }
}

extension UICollectionView: IndexedListView {
    func numberOfCells(inSection section: Int) -> Int {
        return numberOfItems(inSection: section)
    }
}
