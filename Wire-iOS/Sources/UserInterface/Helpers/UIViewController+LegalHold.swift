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

import UIKit

struct LegalHoldRequestAlertViewModel {
    let deviceFingerprint: String
    let onIgnore: () -> Void
    let onAccept: (String) -> Void
}

extension UIAlertController {

    static func makeLegalHoldRequestAlert(for viewModel: LegalHoldRequestAlertViewModel) -> UIAlertController {
        let alert = UIAlertController(
            title: "legal_hold.activation_requested.title".localized,
            message: "legal_hold.activation_requested.message".localized(args: viewModel.deviceFingerprint),
            preferredStyle: .alert)

        var token: Any?

        let tearDown: () -> Void = {
            token.apply(NotificationCenter.default.removeObserver)
        }

        let notNowAction = UIAlertAction(title: "legal_hold.activation_requested.ignore_button".localized, style: .cancel) { _ in
            tearDown()
            viewModel.onIgnore()
        }

        let acceptAction = UIAlertAction(title: "legal_hold.activation_requested.ignore_button".localized, style: .default) { _ in
            tearDown()
            viewModel.onAccept(alert.textFields![0].normalizedInput)
        }

        acceptAction.isEnabled = false

        alert.addTextField { textField in
            textField.placeholder = "password.placeholder".localized
            textField.isSecureTextEntry = true

            if #available(iOS 11, *) {
                textField.textContentType = .password
            }

            token = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { _ in
                acceptAction.isEnabled = !textField.normalizedInput.isEmpty
            }
        }

        alert.addAction(notNowAction)
        alert.addAction(acceptAction)
        alert.preferredAction = acceptAction

        return alert
    }

}
