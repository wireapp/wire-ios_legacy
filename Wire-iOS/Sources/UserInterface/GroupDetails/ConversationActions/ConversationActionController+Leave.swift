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

enum LeaveResult: AlertResultConfiguration {
    case leave(delete: Bool), cancel

    var title: String {
        return localizationKey.localized
    }

    private var localizationKey: String {
        switch self {
        case .cancel: return "general.cancel"
        case .leave(delete: true): return "meta.leave_conversation_button_leave_and_delete"
        case .leave(delete: false): return "meta.leave_conversation_button_leave"
        }
    }

    private var style: UIAlertAction.Style {
        guard case .cancel = self else { return .destructive }
        return .cancel
    }

    func action(_ handler: @escaping (LeaveResult) -> Void) -> UIAlertAction {
        return .init(title: title, style: style) { _ in handler(self) }
    }

    static var title: String {
        return "meta.leave_conversation_dialog_message".localized
    }

    static var all: [LeaveResult] {
        return [.leave(delete: true), .leave(delete: false), .cancel]
    }
}

extension ConversationActionController {

    func handleLeaveResult(_ result: LeaveResult, for conversation: ZMConversation) {
        guard case .leave(delete: let delete) = result else { return }
        transitionToListAndEnqueue {
            if delete {
                conversation.clearMessageHistory()
            }

            conversation.removeOrShowError(participant: SelfUser.current)
        }
    }

}
