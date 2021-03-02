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

final class RequestPasswordController {

    typealias Callback = (_ password: String?) -> Void

    enum RequestPasswordContext {
        case removeDevice
        case logout
        case unlock(message: String)
        case wiping
    }

    var alertController: UIAlertController

    typealias InputValidation = (String?) -> Bool

    private let callback: Callback
    private let inputValidation: InputValidation?
    private weak var okAction: UIAlertAction?
    weak var passwordTextField: UITextField?

    init(context: RequestPasswordContext,
         callback: @escaping Callback,
         inputValidation: InputValidation? = nil) {

        self.callback = callback
        self.inputValidation = inputValidation

        let okTitle: String
        switch context {
        case .wiping:
            okTitle = "wipe_database.alert.confirm".localized
        default:
            okTitle = "general.ok".localized
        }

        let cancelTitle: String = "general.cancel".localized
        let title: String
        let message: String
        let placeholder: String
        let okActionStyle: UIAlertAction.Style

        switch context {
        case .removeDevice:
            title = "self.settings.account_details.remove_device.title".localized
            message = "self.settings.account_details.remove_device.message".localized
            placeholder = "self.settings.account_details.remove_device.password".localized
            okActionStyle = .destructive
        case .logout:
            title = "self.settings.account_details.log_out.alert.title".localized
            message = "self.settings.account_details.log_out.alert.message".localized
            placeholder = "self.settings.account_details.log_out.alert.password".localized
            okActionStyle = .destructive
        case .unlock(let unlockMessage):
            title = "self.settings.privacy_security.lock_app.description".localized
            message = unlockMessage
            placeholder = "self.settings.account_details.log_out.alert.password".localized
            okActionStyle = .default
        case .wiping:
            title = "wipe_database.alert.description".localized
            message = "wipe_database.alert.message".localized
            placeholder = "wipe_database.alert.placeholder".localized
            okActionStyle = .destructive
        }

        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = placeholder

            switch context {
            case .wiping:
                textField.isSecureTextEntry = false
                textField.autocapitalizationType = .words
            default:
                textField.isSecureTextEntry = true
                if #available(iOS 11.0, *) {
                    textField.textContentType = .password
                }
            }

            textField.addTarget(self, action: #selector(RequestPasswordController.passwordTextFieldChanged(_:)), for: .editingChanged)

            self.passwordTextField = textField
        }

        let okAction = UIAlertAction(title: okTitle, style: okActionStyle) { [weak self] _ in
            if let passwordField = self?.alertController.textFields?[0] {
                self?.callback(passwordField.text)
            }
        }

        okAction.isEnabled = false

        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { [weak self] _ in
            self?.callback(nil)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        alertController.preferredAction = okAction

        self.okAction = okAction
    }

    @objc
    func passwordTextFieldChanged(_ textField: UITextField) {
        guard let passwordField = alertController.textFields?[0] else { return }

        okAction?.isEnabled = passwordField.text?.isEmpty == false

        if let inputValidation = inputValidation {
            okAction?.isEnabled = inputValidation(passwordField.text)
        }
    }
}
