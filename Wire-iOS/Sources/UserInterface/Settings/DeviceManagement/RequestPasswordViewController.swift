// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

enum RequestPasswordContext {
    case removeDevice
    case legalHold(fingerprint: Data)
}

final class RequestPasswordViewController: UIAlertController {
    
    var callback: ((Result<String>) -> ())? = .none
    
    var okAction: UIAlertAction? = .none
    
    static func requestPasswordController(context: RequestPasswordContext,
                                          callback: @escaping (Result<String>) -> ()) -> RequestPasswordViewController {

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
        case .legalHold(let fingerprint):
            title = "legalhold_request.alert.title".localized

            let fingerprintString = (fingerprint as NSData).fingerprintString

            message = "legalhold_request.alert.detail".localized(args: fingerprintString)

            okTitle = "general.skip".localized
            cancelTitle = "general.accept".localized
        }

        let controller = RequestPasswordViewController(title: title, message: message, preferredStyle: .alert)
        controller.callback = callback
        
        controller.addTextField { (textField: UITextField) -> Void in
            textField.placeholder = "self.settings.account_details.remove_device.password".localized
            textField.isSecureTextEntry = true
            textField.addTarget(controller, action: #selector(RequestPasswordViewController.passwordTextFieldChanged(_:)), for: .editingChanged)
        }
        
        let okAction = UIAlertAction(title: okTitle, style: .default) { [unowned controller] (action: UIAlertAction) -> Void in
            if let passwordField = controller.textFields?[0] {
                let password = passwordField.text ?? ""
                controller.callback?(.success(password))
            }
        }
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { [unowned controller] (action: UIAlertAction) -> Void in
            controller.callback?(.failure(NSError(domain: "\(type(of: controller))", code: 0, userInfo: [NSLocalizedDescriptionKey: "User cancelled input"])))
        }
        
        controller.okAction = okAction
        
        controller.addAction(okAction)
        controller.addAction(cancelAction)
        
        return controller
    }
    
    @objc func passwordTextFieldChanged(_ textField: UITextField) {
        if let passwordField = self.textFields?[0] {
            self.okAction?.isEnabled = (passwordField.text ?? "").count > 6;
        }
    }
}
