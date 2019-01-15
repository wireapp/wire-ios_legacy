//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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


extension ConversationContentViewController {
    @objc(cellForMessage:)
    func cell(for message: ZMConversationMessage) -> UITableViewCell? {
        guard let indexPath = conversationMessageWindowTableViewAdapter.indexPath(for: message) else {
            return nil
        }

        // Notice: if the cell is not full visible in the table view, UITableView.cellForRow() may returns nil.
        // To handle this case, get the cell from the tableView's dataSource delegate method.
        var cell = tableView.cellForRow(at: indexPath)

        if cell == .none {
            cell = tableView.dataSource?.tableView(tableView, cellForRowAt: indexPath)
        }

        return cell
    }
}

extension ConversationContentViewController: ConversationMessageCellDelegate {
    var cellTappedForMenu: (UIView & SelectableView)? {
        get {
            return _cellTappedForMenu
        }
        set {
            _cellTappedForMenu = newValue
        }
    }

//    @objc(wantsToPerformAction:forMessage:)
    public func wants(toPerform action: MessageAction, for message: ZMConversationMessage!) {
//    func wants(toPerform action: MessageAction, for message: ZMConversationMessage) {
        guard let cell = cellTappedForMenu else { return }

        wants(toPerform: action, for: message, cell: cell)
    }

    func conversationMessageShouldBecomeFirstResponderWhenShowingMenuForCell(_ cell: UIView) -> Bool {
        return delegate.conversationContentViewController(self, shouldBecomeFirstResponderWhenShowMenuFromCell: cell)
    }

    func conversationMessageWantsToOpenUserDetails(_ cell: UIView, user: UserType, sourceView: UIView, frame: CGRect) {
        delegate.didTap?(onUserAvatar: user, view: sourceView, frame: frame)
    }

    func conversationMessageWantsToOpenMessageDetails(_ cell: UIView, messageDetailsViewController: MessageDetailsViewController) {
        parent?.present(messageDetailsViewController, animated: true)
    }

    func conversationMessageWantsToOpenGuestOptionsFromView(_ cell: UIView, sourceView: UIView) {
        delegate.conversationContentViewController(self, presentGuestOptionsFrom: sourceView)
    }

    func conversationMessageWantsToOpenParticipantsDetails(_ cell: UIView, selectedUsers: [ZMUser], sourceView: UIView) {
        delegate.conversationContentViewController(self, presentParticipantsDetailsWithSelectedUsers: selectedUsers, from: sourceView)
    }
}
