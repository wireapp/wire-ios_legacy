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

extension ConversationContentViewController: ConversationMessageCellDelegate {
    public func perform(action: MessageAction, for message: ZMConversationMessage!) {
        guard let cell = dataSource.cell(for: message) as? UIView & SelectableView else { return }

        wants(toPerform: action, for: message, view: cell)
    }

    func conversationMessageWantsToOpenUserDetails(_ cell: UIView, user: UserType, sourceView: UIView, frame: CGRect) {
        delegate.didTap?(onUserAvatar: user, view: sourceView, frame: frame)
    }

    func conversationMessageShouldBecomeFirstResponderWhenShowingMenuForCell(_ cell: UIView) -> Bool {
        return delegate.conversationContentViewController(self, shouldBecomeFirstResponderWhenShowMenuFromCell: cell)
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

