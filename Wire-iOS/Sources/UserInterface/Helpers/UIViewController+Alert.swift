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
        
    /// Create an alert with a OK button
    ///
    /// - Parameters:
    ///   - title: title of the alert
    ///   - message: message of the alert
    ///   - okActionHandler: a nullable closure for the OK button
    /// - Returns: the alert presented
    static func alertWithOKButton(title: String,
                                  message: String,
                                  okActionHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)

        let okAction =  UIAlertAction.ok(style: .cancel, handler: okActionHandler)
        alert.addAction(okAction)

        return alert
    }

    //MARK: - legal hold
    static func legalHoldDeactivated() -> UIAlertController {
        return UIAlertController.alertWithOKButton(title: "legal_hold.deactivated.title".localized,
                                    message: "legal_hold.deactivated.message".localized)
    }
}

extension UIViewController {
    
    /// Present an alert with a OK button
    ///
    /// - Parameters:
    ///   - title: title of the alert
    ///   - message: message of the alert
    ///   - animated: present the alert animated or not
    ///   - okActionHandler: a nullable closure for the OK button
    /// - Returns: the alert presented
    @discardableResult
    func presentAlertWithOKButton(title: String,
                                  message: String,
                                  animated: Bool = true,
                                  okActionHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {

        let alert = UIAlertController.alertWithOKButton(title: title,
                                         message: message,
                                         okActionHandler: okActionHandler)

        present(alert, animated: animated, completion: nil)

        return alert
    }

    //MARK: - legal hold
    @discardableResult
    func presentLegalHoldDeactivatedAlert(animated: Bool = true) -> UIAlertController {

        let alert = UIAlertController.legalHoldDeactivated()

        present(alert, animated: animated)

        return alert
    }

    @discardableResult
    func presentLegalHoldActivatedAlert(animated: Bool = true, completion: @escaping (String?)->()) -> UIAlertController {

        /// password input for SSO user
        let hasPasswordInput = ZMUser.selfUser().usesCompanyLogin != true

        let passwordRequest = RequestPasswordController(context: .legalHold(fingerprint: nil, hasPasswordInput: hasPasswordInput)) { (result: Result<String?>) -> () in
            switch result {
            case .success(let passwordString):
                completion(passwordString)
            case .failure(let error):
                zmLog.error("Error: \(error)")
                completion(nil)
            }
        }

        present(passwordRequest.alertController, animated: animated)

        return passwordRequest.alertController
    }

    //MARK: - user profile deep link
    @discardableResult
    func presentInvalidUserProfileLinkAlert(okActionHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        return presentAlertWithOKButton(title: "url_action.invalid_user.title".localized,
                                        message: "url_action.invalid_user.message".localized,
                                        okActionHandler: okActionHandler)
    }
    
}

