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

extension UIViewController {

    /// Present an action sheet for user removal confirmation
    ///
    /// - Parameters:
    ///   - user: user to remove
    ///   - conversation: the current converation contains that user
    ///   - viewControllerDismissable: a ViewControllerDismissable to call when this UIViewController is dismissed
    @objc func presentRemoveFromConversationDialogue(
        user: ZMUser,
        conversation: ZMConversation?,
        viewControllerDismissable: ViewControllerDismissable?
        ) {

        let controller = UIAlertController.remove(user) { [weak self] remove in
            guard remove, let `self` = self else { return }
            ZMUserSession.shared()?.enqueueChanges({
                conversation?.removeParticipant(user)
            }, completionHandler: {
                if user.isServiceUser {
                    Analytics.shared().tagDidRemoveService(user)
                }
                viewControllerDismissable?.viewControllerWants(toBeDismissed: self, completion: nil)
            })
        }
        
        present(controller, animated: true)
        MediaManagerPlayAlert()
    }
}
