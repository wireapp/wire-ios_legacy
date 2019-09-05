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
private let zmLog = ZMSLog(tag: "Alert")

extension UIAlertController {

    @objc(alertWithCancelButton:message:)
    static func alertWithCancelButton(title: String,
                                      message: String) -> UIAlertController {
        return UIAlertController.alert(title: title, message: message, alertAction: .cancel())
    }

    static func alertWithCancelButton(title: String,
                                      message: String,
                                      cancelButtonTitle: String? = "general.cancel".localized) -> UIAlertController {
        let cancelAction =  UIAlertAction.cancel(cancelButtonTitle: cancelButtonTitle)

        return UIAlertController.alert(title: title, message: message, alertAction: cancelAction)
    }

    @objc(alertWithOKButton:message:)
    static func alertWithOKButton(title: String,
                                  message: String) -> UIAlertController {
        return UIAlertController.alertWithOKButton(title: title,
                                                   message: message,
                                                   okActionHandler: nil)
    }

    /// Create an alert with a OK button
    ///
    /// - Parameters:
    ///   - title: optional title of the alert
    ///   - message: message of the alert
    ///   - okActionHandler: a nullable closure for the OK button
    /// - Returns: the alert presented
    static func alertWithOKButton(title: String? = nil,
                                  message: String,
                                  okActionHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {

        let okAction =  UIAlertAction.ok(style: .cancel, handler: okActionHandler)

        return UIAlertController.alert(title: title, message: message, alertAction: okAction)
    }

    static func alert(title: String? = nil,
                      message: String,
                      alertAction: UIAlertAction) -> UIAlertController {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)

        alert.addAction(alertAction)

        return alert
    }

}

extension UIViewController {
    
    /// Present an alert with a OK button
    ///
    /// - Parameters:
    ///   - title: optional title of the alert
    ///   - message: message of the alert
    ///   - animated: present the alert animated or not
    ///   - okActionHandler: optional closure for the OK button
    /// - Returns: the alert presented
    @discardableResult
    func presentAlertWithOKButton(title: String? = nil,
                                  message: String,
                                  animated: Bool = true,
                                  okActionHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {

        let alert = UIAlertController.alertWithOKButton(title: title,
                                                        message: message,
                                                        okActionHandler: okActionHandler)

        present(alert, animated: animated, completion: nil)

        return alert
    }

    // MARK: - user profile deep link

    @discardableResult
    func presentInvalidUserProfileLinkAlert(okActionHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        return presentAlertWithOKButton(title: "url_action.invalid_user.title".localized,
                                        message: "url_action.invalid_user.message".localized,
                                        okActionHandler: okActionHandler)
    }
    
}
