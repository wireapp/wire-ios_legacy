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

@objc enum ConversationDegradedResult: UInt8 {
    case sendAnyway, showDetails, cancel
}

extension UIAlertController {
    @objc(controllerForUnknownClientsForUsers:completion:)
    static func unknownClients(for users: Set<ZMUser>, completion: @escaping (ConversationDegradedResult) -> Void) -> UIAlertController {
        let names = users.map { $0.displayName }.joined(separator: ", ")
        let keySuffix = users.count <= 1 ? "singular" : "plural"
        let title = "meta.degraded.degradation_reason_message.\(keySuffix)".localized(args: names)
        let message = "meta.degraded.dialog_message".localized
        
        let iPad = ZClientViewController.shared()?.traitCollection.userInterfaceIdiom == .pad
        let controller = UIAlertController(
            title: title + "\n" + message,
            message: nil,
            preferredStyle: iPad ? .alert : .actionSheet
        )
        let acceptAction = UIAlertAction(
            title: "meta.degraded.show_device_button".localized.localizedCapitalized,
            style: .default,
            handler: { _ in completion(.showDetails) }
        )
        let ignoreAction = UIAlertAction(
            title: "meta.degraded.send_anyway_button".localized.localizedCapitalized,
            style: .default,
            handler: { _ in completion(.sendAnyway) }
        )
        controller.addAction(acceptAction)
        controller.addAction(ignoreAction)
        controller.addAction(.cancel { completion(.cancel) })
        return controller
    }
}
