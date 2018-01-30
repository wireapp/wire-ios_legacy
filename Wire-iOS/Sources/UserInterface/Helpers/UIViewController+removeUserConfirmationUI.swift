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

    /// Present a action sheet for user removal confirmation
    ///
    /// - Parameters:
    ///   - user: user to remove
    ///   - conversation: the current converation contains that user
    ///   - profileViewControllerDelegate: a ProfileViewControllerDelegate to call when this UIViewController is dismissed
    @objc func presentRemoveFromConversationDialogue(user: ZMUser,
                                                     conversation: ZMConversation,
                                                     profileViewControllerDelegate: ProfileViewControllerDelegate?) {
        if let actionSheetController = ActionSheetController.dialog(forRemoving: user, from: conversation, style: ActionSheetController.defaultStyle(), completion: {(_ canceled: Bool) -> Void in
            self.dismiss(animated: true, completion: {() -> Void in
                if canceled {
                    return
                }
                ZMUserSession.shared()?.enqueueChanges({() -> Void in
                    conversation.removeParticipant(user)
                }, completionHandler: {() -> Void in
                    if user.isServiceUser {
                        Analytics.shared().tagDidRemoveService(user)
                    }
                    profileViewControllerDelegate?.profileViewControllerWants(toBeDismissed: self, completion: nil)
                })
            })
        }) {
            present(actionSheetController, animated: true)
        }
        MediaManagerPlayAlert()
    }
}
