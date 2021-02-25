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
import UIKit

extension UpsideDownTableView {

    func scrollToBottom(animated: Bool) {
        // upside-down tableview's bottom is rightside-up tableview's top
        super.scrollToTop(animated: animated)
    }

    func scroll(toIndex indexToShow: Int, completion: ((UIView)->())? = .none) {
        guard numberOfSections > 0 else { return }

        let rowIndex = numberOfCells(inSection: indexToShow) - 1
        guard rowIndex >= 0 && indexToShow < numberOfSections else { return }
        let cellIndexPath = IndexPath(row: rowIndex, section: indexToShow)

        scrollToRow(at: cellIndexPath, at: .top, animated: false)
        if let cell = cellForRow(at: cellIndexPath) {
            completion?(cell)
        }
    }

}

private extension UITableView {
    func scrollToTop(animated: Bool) {
        // kill existing scrolling animation
        self.setContentOffset(self.contentOffset, animated: false)

        // scroll completely to top
        self.setContentOffset(CGPoint(x: 0, y: -self.contentInset.top), animated: animated)
    }
}
