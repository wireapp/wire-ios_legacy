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
    
    let callback: ((Result<String>) -> ())
    var okAction: UIAlertAction!
    let alertController: UIAlertController

    enum RequestPasswordContext {
        case removeDevice
    }

    init(context: RequestPasswordContext,
         callback: @escaping (Result<String>) -> ()) {

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
        }

        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        switch context {
        case .removeDevice:
            alertController.addTextField {(textField: UITextField) -> Void in
                textField.placeholder = "self.settings.account_details.remove_device.password".localized
                textField.isSecureTextEntry = true
                textField.addTarget(self,
                                    action: #selector(RequestPasswordController.passwordTextFieldChanged(_:)),
                                    for: .editingChanged)
            }
        }

        okAction = UIAlertAction(title: okTitle, style: .default) {
            [weak self, unowned alertController] (action: UIAlertAction) -> Void in
            if let passwordField = alertController.textFields?[0] {
                let password = passwordField.text ?? ""
                self?.callback(.success(password))
            }
        }
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) {
            [weak self, unowned alertController] (action: UIAlertAction) -> Void in
            self?.callback(.failure(NSError(domain: "\(type(of: alertController))", code: 0, userInfo: [NSLocalizedDescriptionKey: "User cancelled input"])))
        }

        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
    }
    
    @objc
    func passwordTextFieldChanged(_ textField: UITextField) {
        guard let passwordField = alertController.textFields?[0] else { return }

        ///TODO: update with password requirement
        okAction.isEnabled = (passwordField.text ?? "").count > 6
    }
}
