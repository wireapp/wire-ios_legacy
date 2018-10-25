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

class RequestPasswordViewController: UIAlertController {
    
    var callback: ((Result<String>) -> ())? = .none
    
    var okAction: UIAlertAction? = .none
    
    static func requestPasswordController(_ callback: @escaping (Result<String>) -> ()) -> RequestPasswordViewController {
        
        let title = NSLocalizedString("self.settings.account_details.remove_device.title", comment: "")
        let message = NSLocalizedString("self.settings.account_details.remove_device.message", comment: "")
        
        let controller = RequestPasswordViewController(title: title, message: message, preferredStyle: .alert)
        controller.callback = callback
        
        controller.addTextField { (textField: UITextField) -> Void in
            textField.placeholder = NSLocalizedString("self.settings.account_details.remove_device.password", comment: "")
            textField.isSecureTextEntry = true
            textField.addTarget(controller, action: #selector(RequestPasswordViewController.passwordTextFieldChanged(_:)), for: .editingChanged)
        }
        
        let okTitle = NSLocalizedString("general.ok", comment: "")
        let cancelTitle = NSLocalizedString("general.cancel", comment: "")
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
