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
            title: L10n.Localizable.Conversation.DeleteRequestDialog.title,
            message: L10n.Localizable.Conversation.DeleteRequestDialog.message,
            confirmTitle: L10n.Localizable.Conversation.DeleteRequestErrorDialog.buttonDeleteGroup,
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
                case .failure:
                    let alert = UIAlertController.alertWithOKButton(
                        title: L10n.Localizable.Error.Conversation.title,
                        message: L10n.Localizable.Conversation.DeleteRequestErrorDialog.title(conversation.displayName))
                    UIApplication.shared.topmostViewController(onlyFullScreen: false)?.present(alert, animated: true)
                }
            }
        }
    }
}
