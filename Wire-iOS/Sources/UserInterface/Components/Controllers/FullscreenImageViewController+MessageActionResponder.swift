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

extension FullscreenImageViewController {
    private func perform(action: MessageAction) {
        let sourceView: UIView
        
        /// iPad popover points to delete button of container is availible. The scrollView occupies most of the screen area and the popover is compressed.
        if action == .delete,
            let conversationImagesViewController = delegate as? ConversationImagesViewController {
            sourceView = conversationImagesViewController.deleteButton
        } else if action == .forward,
            let shareButton = (delegate as? ConversationImagesViewController)?.shareButton {
            sourceView = shareButton
        } else {
            sourceView = scrollView
        }
        
        (delegate as? MessageActionResponder)?.perform(action: action, for: message, view: sourceView)
    }
}

extension FullscreenImageViewController: MessageActionResponder {
    func perform(action: MessageAction, for message: ZMConversationMessage!, view: UIView) {
        switch action {
        case .forward:
            perform(action: action)
        case .showInConversation,
             .reply:
            dismiss(animated: true) {
                self.perform(action: action)
            }
        case .openDetails:
            let detailsViewController = MessageDetailsViewController(message: message)
            present(detailsViewController, animated: true)
        default:
            perform(action: action)
        }
    }
}
