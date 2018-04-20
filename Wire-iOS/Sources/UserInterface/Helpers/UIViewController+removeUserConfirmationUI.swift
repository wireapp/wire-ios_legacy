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
    ///   - participant: user to remove
    ///   - conversation: the current converation contains that user
    ///   - viewControllerDismissable: a ViewControllerDismissable to call when this UIViewController is dismissed
    @objc(presentRemoveDialogueForParticipant:fromConversation:dismissable:)
    func presentRemoveDialogue(
        for participant: ZMUser,
        from conversation: ZMConversation,
        dismissable: ViewControllerDismissable? = nil
        ) {

        let controller = UIAlertController.remove(participant) { [weak self] remove in
            guard remove, let `self` = self, let session = ZMUserSession.shared() else { return }
            
            conversation.removeParticipant(participant, userSession: session, completion: { (result) in
                switch result {
                case .success:
                    dismissable?.viewControllerWants(toBeDismissed: self, completion: nil)
                case .failure(_):
                    break
                }
            })
        }
        
        present(controller, animated: true)
        MediaManagerPlayAlert()
    }
}
