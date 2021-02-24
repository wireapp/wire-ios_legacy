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
import WireDataModel
import WireSyncEngine

extension ConversationActionController {

    func requestDeleteGroupResult(completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController.confirmController(
            title: "conversation.delete_request_dialog.title".localized,
            message: "conversation.delete_request_dialog.message".localized,
            confirmTitle: "conversation.delete_request_error_dialog.button_delete_group".localized,
            completion: completion
        )
        present(alertController)
    }

    func handleDeleteGroupResult(_ result: Bool, conversation: ZMConversation, in userSession: ZMUserSession) {
        guard result else { return }

        transitionToListAndEnqueue {
            conversation.delete(in: userSession) { (result) in
                switch result {
                case .success:
                    break
                case .failure(_):
                    let alert = UIAlertController.alertWithOKButton(title: "error.conversation.title".localized,
                                                                    message: "conversation.delete_request_error_dialog.title".localized(args: conversation.displayName))
                    UIApplication.shared.topmostViewController(onlyFullScreen: false)?.present(alert, animated: true)
                }
            }
        }
    }
}
