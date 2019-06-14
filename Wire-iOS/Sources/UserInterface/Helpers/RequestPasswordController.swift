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


final class RequestPasswordController {
    
    let callback: ((Result<String?>) -> ())
    private weak var okAction: UIAlertAction!
    var alertController: UIAlertController!
    weak var passwordTextField: UITextField?

    enum RequestPasswordContext {
        case removeDevice
        case legalHold(fingerprint: Data?, hasPasswordInput: Bool)
    }

    init(context: RequestPasswordContext,
         callback: @escaping (Result<String?>) -> ()) {

        self.callback = callback

        let title: String
        let message: String
        let okTitle: String
        let cancelTitle: String

        switch context {
        case .removeDevice:
            title = "self.settings.account_details.remove_device.title".localized
            message = "self.settings.account_details.remove_device.message".localized

            okTitle = "general.ok".localized
            cancelTitle = "general.cancel".localized

        case .legalHold(let fingerprint, let hasPasswordInput):
            title = "legalhold_request.alert.title".localized

            let fingerprintString: String
            if let fingerprint = fingerprint {
                fingerprintString = fingerprint.fingerprintString
            } else {
                fingerprintString = ""
            }

            var legalHoldMessage = "legalhold_request.alert.detail".localized(args: fingerprintString)
            if hasPasswordInput {
                legalHoldMessage += "\n"
                legalHoldMessage += "legalhold_request.alert.detail.enter_password".localized
            }
            message = legalHoldMessage

            okTitle = "general.skip".localized
            cancelTitle = "general.accept".localized
        }

        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        switch context {
        case .removeDevice,
             .legalHold(_, true):
            alertController.addTextField { textField in
                textField.placeholder = "self.settings.account_details.remove_device.password".localized
                textField.isSecureTextEntry = true
                if #available(iOS 11.0, *) {
                    textField.textContentType = .password
                }

                textField.addTarget(self,
                                    action: #selector(RequestPasswordController.passwordTextFieldChanged(_:)),
                                    for: .editingChanged)

                self.passwordTextField = textField
            }
        case .legalHold(_, false):
            break
        }

        let okAction = UIAlertAction(title: okTitle, style: .default) { action in
            if let passwordField = self.alertController.textFields?[0] {
                let password = passwordField.text ?? ""
                self.callback(.success(password))
            }
        }

        okAction.isEnabled = false
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { action in
            self.callback(.failure(NSError(domain: "\(type(of: self.alertController))", code: NSUserCancelledError, userInfo: nil)))
        }

        alertController.addAction(okAction)
        alertController.addAction(cancelAction)

        self.okAction = okAction
    }

    @objc
    func passwordTextFieldChanged(_ textField: UITextField) {
        guard let passwordField = alertController.textFields?[0] else { return }

        okAction.isEnabled = passwordField.text?.isEmpty == false
    }
}
