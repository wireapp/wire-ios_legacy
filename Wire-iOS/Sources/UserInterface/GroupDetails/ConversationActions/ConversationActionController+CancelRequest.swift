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
import UIKit
import WireDataModel

enum CancelConnectionRequestResult {
    case cancelRequest, cancel

    var title: String {
        return localizationKey.localized
    }

    private var localizationKey: String {
        switch self {
        case .cancel: return "profile.cancel_connection_request_dialog.button_no"
        case .cancelRequest: return "profile.cancel_connection_request_dialog.button_yes"
        }
    }

    private var style: UIAlertAction.Style {
        guard case .cancel = self else { return .destructive }
        return .cancel
    }

    func action(_ handler: @escaping (CancelConnectionRequestResult) -> Void) -> UIAlertAction {
        return .init(title: title, style: style) { _ in handler(self) }
    }

    static func title(for user: UserType) -> String {
        return "profile.cancel_connection_request_dialog.message".localized(args: user.name ?? "")
    }

    static var all: [CancelConnectionRequestResult] {
        return [.cancelRequest, .cancel]
    }

    static func controller(for user: UserType, handler: @escaping (CancelConnectionRequestResult) -> Void) -> UIAlertController {
        let controller = UIAlertController(title: title(for: user), message: nil, preferredStyle: .actionSheet)
        all.map { $0.action(handler) }.forEach(controller.addAction)
        return controller
    }
}

extension UIAlertController {
    static func cancelConnectionRequest(for user: UserType, completion: @escaping (Bool) -> Void) -> UIAlertController {
        return CancelConnectionRequestResult.controller(for: user) { result in
            completion(result == .cancel)
        }
    }
}

extension ConversationActionController {

    func requestCancelConnectionRequestResult(for user: UserType, handler: @escaping (CancelConnectionRequestResult) -> Void) {
        let controller = CancelConnectionRequestResult.controller(for: user, handler: handler)
        present(controller)
    }

    func handleConnectionRequestResult(_ result: CancelConnectionRequestResult, for conversation: ZMConversation) {
        guard case .cancelRequest = result else { return }
        enqueue {
            conversation.connectedUser?.cancelConnectionRequest()
        }
    }

}
