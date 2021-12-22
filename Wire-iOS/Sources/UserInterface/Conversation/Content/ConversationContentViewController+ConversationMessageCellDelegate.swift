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
import UIKit
import WireDataModel

extension UIView {
    func targetView(for message: ZMConversationMessage!, dataSource: ConversationTableViewDataSource) -> UIView {

        /// if the view is a tableView, search for a visible cell that contains the message and the cell is a SelectableView
        guard let tableView: UITableView = self as? UITableView else {
            return self
        }

        var actionView: UIView = tableView

        let section = dataSource.section(for: message)

        for cell in tableView.visibleCells {
            let indexPath = tableView.indexPath(for: cell)
            if indexPath?.section == section,
                cell is SelectableView {
                actionView = cell
                break
            }
        }

        return actionView
    }
}

extension ConversationContentViewController: ConversationMessageCellDelegate {
    // MARK: - MessageActionResponder

    func perform(action: MessageAction,
                 for message: ZMConversationMessage!,
                 view: UIView) {
        let actionView = view.targetView(for: message, dataSource: dataSource)

        /// Do not dismiss Modal for forward since share VC is present in a popover
        let shouldDismissModal = action != .delete && action != .copy &&
            !(action == .forward && isIPadRegular())

        if messagePresenter.modalTargetController?.presentedViewController != nil &&
            shouldDismissModal {
            messagePresenter.modalTargetController?.dismiss(animated: true) {
                self.messageAction(actionId: action,
                                   for: message,
                                   view: actionView)
            }
        } else {
            messageAction(actionId: action,
                          for: message,
                          view: actionView)
        }
    }

    func conversationMessageWantsToOpenUserDetails(_ cell: UIView, user: UserType, sourceView: UIView, frame: CGRect) {
        delegate?.didTap(onUserAvatar: user, view: sourceView, frame: frame)
    }

    func conversationMessageShouldBecomeFirstResponderWhenShowingMenuForCell(_ cell: UIView) -> Bool {
        return delegate?.conversationContentViewController(self, shouldBecomeFirstResponderWhenShowMenuFromCell: cell) ?? false
    }

    func conversationMessageWantsToOpenMessageDetails(_ cell: UIView, messageDetailsViewController: MessageDetailsViewController) {
        parent?.present(messageDetailsViewController, animated: true)
    }

    func conversationMessageWantsToOpenGuestOptionsFromView(_ cell: UIView, sourceView: UIView) {
        delegate?.conversationContentViewController(self, presentGuestOptionsFrom: sourceView)
    }

    func conversationMessageWantsToOpenParticipantsDetails(_ cell: UIView, selectedUsers: [UserType], sourceView: UIView) {
        delegate?.conversationContentViewController(self, presentParticipantsDetailsWithSelectedUsers: selectedUsers, from: sourceView)
    }

    func conversationMessageShouldUpdate() {
        dataSource.loadMessages(forceRecalculate: true)
    }

}
