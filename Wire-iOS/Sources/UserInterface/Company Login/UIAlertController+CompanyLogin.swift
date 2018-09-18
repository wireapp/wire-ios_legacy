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

extension UIAlertController {
    
    /// Creates an `UIAlertController` with a textfield to get a SSO login code from the user.
    /// - parameter prefilledCode: A code which should be used to prefill the textfield of the controller (or `nil`).
    /// - parameter validator: A validation closure which will be used to enable / disable the textfield.
    /// - parameter completion: The completion closure which will be called with the provided code or nil if cancelled.
    @objc static func companyLogin(
        prefilledCode: String?,
        validator: @escaping (String) -> Bool,
        completion: @escaping (String?) -> Void
        ) -> UIAlertController {

        var token: Any?

        func complete(_ result: String?) {
            token.apply(NotificationCenter.default.removeObserver)
            completion(result)
        }
        
        let controller = UIAlertController(
            title: "login.sso.alert.title".localized,
            message: "login.sso.alert.message".localized,
            preferredStyle: .alert
        )

        let loginAction = UIAlertAction(title: "login.sso.alert.action".localized, style: .default) { [controller] _ in
            complete(controller.textFields?.first?.text)
        }
        
        controller.addTextField { textField in
            textField.text = prefilledCode
            textField.accessibilityIdentifier = "textfield.sso.code"
            textField.placeholder = "login.sso.alert.text_field.placeholder".localized
            token = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { _ in
                loginAction.isEnabled = textField.text.map(validator) ?? false
            }

            // Enable the login button initially if the prefilled code is valid.
            loginAction.isEnabled = prefilledCode.map(validator) ?? false
        }
        
        controller.addAction(.cancel { complete(nil) })
        controller.addAction(loginAction)
        return controller
    }

    /// Creates an `UIAlertController` with a generic error title, a single OK button and the provided message.
    /// - parameter message: The error message that should be used as the message of the controller.
    static func companyLoginError(_ message: String) -> UIAlertController {
        let controller = UIAlertController(
            title: "login.sso.error.alert.title".localized,
            message: message,
            preferredStyle: .alert
        )
        
        controller.addAction(.ok())
        return controller
    }

    /// Creates an `UIAlertController` warning about no network connection.
    static func noInternetError() -> UIAlertController {
        let controller = UIAlertController(
            title: "team.invite.error.no_internet".localized,
            message: "login.sso.error.offline.alert.message".localized,
            preferredStyle: .alert
        )

        controller.addAction(.ok())
        return controller
    }

    static func invalidCodeError() -> UIAlertController {
        let controller = UIAlertController(
            title: "login.sso.error.alert.invalid_code.title".localized,
            message: "login.sso.error.alert.invalid_code.message".localized,
            preferredStyle: .alert
        )

        controller.addAction(.ok())
        return controller
    }
    
}
