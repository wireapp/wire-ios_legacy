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

extension ContactsViewController: UITableViewDelegate {
    func headerTitle(section: Int) -> String? {
        guard let tableView = tableView else { return nil }

        return dataSource?.tableView(tableView, titleForHeaderInSection: section)
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = headerTitle(section: section), title.count > 0 else {
            return nil
        }

        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ContactsViewControllerSectionHeaderID) as? ContactsSectionHeaderView
        headerView?.label.text = title

        return headerView
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let title = headerTitle(section: section), title.count > 0 else {
            return 0
        }

        return ContactsSectionHeaderView.height
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat.StartUI.CellHeight
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let user = dataSource?.user(at: indexPath) {
            dataSource?.select(user)
        }
    }

    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let user = dataSource?.user(at: indexPath) else { return nil }

        if let shouldSelect = contentDelegate?.contactsViewController?(self, shouldSelect: user),
            shouldSelect{
            return indexPath
        } else {
            if let cell = tableView.cellForRow(at: indexPath) as? ContactsCell {
                contentDelegate?.contactsViewController?(self, didSelect: cell, for: user)
            }
        }

        return nil
    }

    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let user = dataSource?.user(at: indexPath) {
            dataSource?.deselect(user)
        }
    }
}
