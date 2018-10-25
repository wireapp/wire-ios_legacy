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

import UIKit

extension UIAlertController {
    
    static func requestRestorePassword(completion: @escaping (String?) -> Void) -> UIAlertController {
        let controller = UIAlertController(
            title: "registration.no_history.restore_backup.password.title".localized,
            message: nil,
            preferredStyle: .alert
        )
        
        var token: Any?
        
        func complete(_ result: String?) {
            token.apply(NotificationCenter.default.removeObserver)
            completion(result)
        }
        
        let okAction = UIAlertAction(title: "general.ok".localized, style: .default) { [controller] _ in
            complete(controller.textFields?.first?.text)
        }
        
        okAction.isEnabled = false
    
        controller.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "registration.no_history.restore_backup.password.placeholder".localized
            token = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { _ in
                okAction.isEnabled = textField.text?.count ?? 0 >= Password.minimumCharacters
            }
        }
    
        controller.addAction(.cancel { complete(nil) })
        controller.addAction(okAction)
        return controller
    }
    
    static func importWrongPasswordError(completion: @escaping () -> Void) -> UIAlertController {
        let controller = UIAlertController(
            title: "registration.no_history.restore_backup.password_error.title".localized,
            message: nil,
            preferredStyle: .alert
        )
        
        controller.addAction(.ok(completion))
        return controller
    }

}
