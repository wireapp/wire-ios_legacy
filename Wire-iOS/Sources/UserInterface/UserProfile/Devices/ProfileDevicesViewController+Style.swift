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

extension ProfileDevicesViewController {
    @objc func setupStyle() {
        tableView.separatorColor = .from(scheme: .separator)

        view.backgroundColor = UIColor.from(scheme: .contentBackground)
    }
}

// MARK: - refresh table header size when frame size changes

extension ProfileDevicesViewController {
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTableHeaderView()
    }

    @objc
    func updateTableHeaderView() {
        if tableView.bounds.equalTo(CGRect.zero) {
            return
        }

        guard let headerView = tableView.tableHeaderView as? ParticipantDeviceHeaderView else { return }
        headerView.showUnencryptedLabel = user.clients.count == 0

        headerView.size(fittingWidth: tableView.bounds.width)

        tableView.tableHeaderView = headerView
    }
}
