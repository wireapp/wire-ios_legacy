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
import WireDataModel

enum ClearContentResult {
    case delete(leave: Bool), cancel

    var title: String {
        return localizationKey.localized
    }

    private var localizationKey: String {
        switch self {
        case .cancel: return "general.cancel"
        case .delete(leave: true): return "meta.menu.delete_content.button_delete_and_leave"
        case .delete(leave: false): return "meta.menu.delete_content.button_delete"
        }
    }

    private var style: UIAlertAction.Style {
        guard case .cancel = self else { return .destructive }
        return .cancel
    }

    func action(_ handler: @escaping (ClearContentResult) -> Void) -> UIAlertAction {
        return .init(title: title, style: style) { _ in handler(self) }
    }

    static var title: String {
        return "meta.menu.delete_content.dialog_message".localized
    }

    static func options(for conversation: ZMConversation) -> [ClearContentResult] {
        if conversation.conversationType == .oneOnOne || !conversation.isSelfAnActiveMember {
            return [.delete(leave: false), .cancel]
        } else {
            return [.delete(leave: true), .delete(leave: false), .cancel]
        }
    }
}

extension ConversationActionController {

    func requestClearContentResult(for conversation: ZMConversation, handler: @escaping (ClearContentResult) -> Void) {
        let controller = UIAlertController(title: ClearContentResult.title, message: nil, preferredStyle: .actionSheet)
        ClearContentResult.options(for: conversation) .map { $0.action(handler) }.forEach(controller.addAction)
        present(controller)
    }

    func handleClearContentResult(_ result: ClearContentResult, for conversation: ZMConversation) {
        guard case .delete(leave: let leave) = result else { return }
        transitionToListAndEnqueue {
            conversation.clearMessageHistory()
            if leave {
                conversation.removeOrShowError(participant: SelfUser.current)
            }
        }
    }

}
