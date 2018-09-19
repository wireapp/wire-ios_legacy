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

extension ContactsViewController {
    @objc func setupStyle() {
        titleLabel?.textAlignment = .center
        titleLabel?.font = .smallLightFont
        titleLabel?.textTransform = .upper

        bottomContainerView.backgroundColor = .background

        noContactsLabel.font = .normalLightFont
        noContactsLabel.textColor = UIColor(scheme: .textForeground, variant: .dark)
    }

    var numTableRows: UInt {
        if let tableView = tableView {
            return tableView.numberOfTotalRows()
        } else {
            return 0
        }
    }
}
