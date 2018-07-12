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

extension ConversationContentViewController {
    var headerHeight: CGFloat {
        var height: CGFloat = 20
        if messageWindow.messages.count == 1,
            let message = messageWindow.messages.firstObject as? ZMConversationMessage,
            let cell = self.cell(for:message) {

            height += cell.bounds.height
        }

        if tableView.bounds.size.height <= 0 {
            tableView.setNeedsLayout()
            tableView.layoutIfNeeded()
        }

        return tableView.bounds.size.height - height
    }

    @objc func headerViewFrame(view: UIView) -> CGRect {
        let fittingSize = CGSize(width: tableView.bounds.size.width, height: headerHeight)
        let requiredSize = view.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.defaultLow)

        return CGRect(origin: .zero, size: requiredSize)
    }

    @objc func updateHeaderHeight() {
        guard let headerView = tableView.tableHeaderView else { return }

        headerView.frame = headerViewFrame(view: headerView)
        tableView.tableHeaderView = headerView
    }
}
