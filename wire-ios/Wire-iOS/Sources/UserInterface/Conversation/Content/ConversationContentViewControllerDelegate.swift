// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireDataModel
import UIKit

protocol ConversationContentViewControllerDelegate: AnyObject {

    func conversationContentViewController(_ contentViewController: ConversationContentViewController, willDisplayActiveMediaPlayerFor message: ZMConversationMessage?)

    func conversationContentViewController(_ contentViewController: ConversationContentViewController, didEndDisplayingActiveMediaPlayerFor message: ZMConversationMessage)

    func conversationContentViewController(_ contentViewController: ConversationContentViewController, didTriggerResending message: ZMConversationMessage)

    func conversationContentViewController(_ contentViewController: ConversationContentViewController, didTriggerEditing message: ZMConversationMessage)

    func conversationContentViewController(_ contentViewController: ConversationContentViewController, didTriggerReplyingTo message: ZMConversationMessage)

    func conversationContentViewController(_ contentViewController: ConversationContentViewController, performImageSaveAnimation snapshotView: UIView?, sourceRect: CGRect)

    func conversationContentViewController(_ controller: ConversationContentViewController, shouldBecomeFirstResponderWhenShowMenuFromCell cell: UIView) -> Bool

    func conversationContentViewControllerWants(toDismiss controller: ConversationContentViewController)

    func conversationContentViewController(_ controller: ConversationContentViewController, presentGuestOptionsFrom sourceView: UIView)

    func conversationContentViewController(_ controller: ConversationContentViewController,
                                           presentServicesOptionFrom sourceView: UIView)
    func conversationContentViewController(_ controller: ConversationContentViewController, presentParticipantsDetailsWithSelectedUsers selectedUsers: [UserType], from sourceView: UIView)

    func didTap(onUserAvatar user: UserType, view: UIView, frame: CGRect)
}
