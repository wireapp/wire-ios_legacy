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
import UIKit
import WireSyncEngine

extension UIAlertController {

  fileprivate enum CompanyLoginCopy: String {
        case ssoAndEmail = "sso_and_email"
        case ssoOnly = "sso_only"
        typealias SSOAlert = L10n.Localizable.Login.Sso.Alert
        init(ssoOnly: Bool) {
            self = ssoOnly ? .ssoOnly : .ssoAndEmail
        }

        var action: String {
            return SSOAlert.action
        }

        var title: String {
            return SSOAlert.title
        }

        var message: String {
            return "login.sso.alert.message.\(self.rawValue)".localized
        }

        var placeholder: String {
            return "login.sso.alert.text_field.placeholder.\(self.rawValue)".localized
        }
    }

    enum CompanyLoginError {
        /// Input doesn't match an email or SSO code format
        case invalidFormat
        /// SSO code is invalid
        case invalidCode
        /// SSO code validation failed
        case invalidStatus(StatusCode)
        /// Domain is not registered
        case domainNotRegistered
        //// Domain is associated with a different server than the already signed in account
        case domainAssociatedWithWrongServer
        /// Unknown error
        case unknown

        fileprivate func description(for copy: CompanyLoginCopy) -> String {
            switch self {
            case .invalidFormat:
                return "login.sso.error.alert.invalid_format.message.\(copy.rawValue)".localized
            case .domainNotRegistered:
                return L10n.Localizable.Login.Sso.Error.Alert.DomainNotRegistered.message
            case .domainAssociatedWithWrongServer:
                return L10n.Localizable.Login.Sso.Error.Alert.DomainAssociatedWithWrongServer.message
            case .invalidCode:
                return L10n.Localizable.Login.Sso.Error.Alert.InvalidCode.message
            case .invalidStatus(let status):
                return L10n.Localizable.Login.Sso.Error.Alert.InvalidStatus.message(String(status)).uppercased()
            case .unknown:
                return L10n.Localizable.Login.Sso.Error.Alert.Unknown.message
            }
        }
    }

    /// Creates an `UIAlertController` with a textfield to get a SSO login code from the user.
    /// - parameter prefilledInput: Input which should be used to prefill the textfield of the controller (optional).
    /// - parameter ssoOnly: A boolean defining if the alert's copy should be for SSO only. default: false.
    /// - parameter error: An (optional) error to display above the textfield
    /// - parameter completion: The completion closure which will be called with the provided code or nil if cancelled.
    static func companyLogin(
        prefilledInput: String? = nil,
        ssoOnly: Bool = false,
        error: CompanyLoginError? = nil,
        completion: @escaping (_ ssoCode: String?) -> Void) -> UIAlertController {

        let copy = CompanyLoginCopy(ssoOnly: ssoOnly)

        let controller = UIAlertController(
            title: copy.title,
            message: "\n\(copy.message)",
            preferredStyle: .alert
        )

        if let error = error {
            let attributedString = NSAttributedString.companyLoginString(
                withMessage: copy.message,
                error: error.description(for: copy)
            )
            controller.setValue(attributedString, forKey: "attributedMessage")
        }

        let loginAction = UIAlertAction(title: copy.action, style: .default) { [controller] _ in
            completion(controller.textFields?.first?.text)
        }

        controller.addTextField { textField in
            textField.text = prefilledInput
            textField.accessibilityIdentifier = "textfield.sso.code"
            textField.placeholder = copy.placeholder
        }

        controller.addAction(.cancel { completion(nil) })
        controller.addAction(loginAction)
        return controller
    }

    /// Creates an `UIAlertController` warning about no network connection.
    static func noInternetError() -> UIAlertController {
        let controller = UIAlertController(
            title: L10n.Localizable.Team.Invite.Error.noInternet,
            message: L10n.Localizable.Login.Sso.Error.Offline.Alert.message,
            preferredStyle: .alert
        )

        controller.addAction(.ok())
        return controller
    }
}
