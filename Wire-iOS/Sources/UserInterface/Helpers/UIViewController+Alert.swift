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

    // MARK: - Legal Hold

    func presentLegalHoldDeactivatedAlert() {
        let alert = UIAlertController.legalHoldDeactivated()
        present(alert, animated: true)
    }

    func presentLegalHoldActivatedAlert(for user: ZMUser) {
        let alert = UIAlertController(
            title: "legalhold_active.alert.title".localized,
            message: "legalhold.header.self_description".localized,
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: "general.ok".localized, style: .default) { _ in
            user.acceptLegalHoldChangeAlert()
        }

        alert.addAction(okAction)

        let detailsAction = UIAlertAction(title: "legalhold_active.alert.learn_more".localized, style: .default) { _ in
            user.acceptLegalHoldChangeAlert()

            guard let legalHoldDetailsViewController = LegalHoldDetailsViewController(user: user)?.wrapInNavigationController() else { return }
            legalHoldDetailsViewController.modalPresentationStyle = .formSheet
            self.present(legalHoldDetailsViewController, animated: true, completion: nil)
        }

        alert.addAction(detailsAction)
        alert.preferredAction = okAction

        present(alert, animated: true)
    }

    func presentLegalHoldActivationAlert(for request: LegalHoldRequest, user: SelfUserType, animated: Bool = true) {
        func handleLegalHoldActivationResult(_ error: LegalHoldActivationError?) {
            UIApplication.shared.wr_topmostViewController()?.showLoadingView = false

            switch error {
            case .invalidPassword?:
                user.acceptLegalHoldChangeAlert()

                let alert = UIAlertController.alertWithOKButton(
                    title: "legalhold_request.alert.error_wrong_password".localized,
                    message: "legalhold_request.alert.error_wrong_password".localized
                )

                present(alert, animated: true)

            case .some:
                user.acceptLegalHoldChangeAlert()

                let alert = UIAlertController.alertWithOKButton(
                    title: "general.failure".localized,
                    message: "general.failure.try_again".localized
                )

                present(alert, animated: true)

            case .none:
                user.handleLegalHoldActivationSuccess(for: request)
            }
        }

        let request = user.makeLegalHoldInputRequest(for: request) { password in
            UIApplication.shared.wr_topmostViewController()?.showLoadingView = true

            ZMUserSession.shared()?.acceptLegalHold(password: password) { error in
                DispatchQueue.main.async {
                    handleLegalHoldActivationResult(error)
                }
            }
        }

        let alert = UIAlertController(inputRequest: request)
        present(alert, animated: animated)
    }

    // MARK: - user profile deep link

    @discardableResult
    func presentInvalidUserProfileLinkAlert(okActionHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        return presentAlertWithOKButton(title: "url_action.invalid_user.title".localized,
                                        message: "url_action.invalid_user.message".localized,
                                        okActionHandler: okActionHandler)
    }
    
}

// MARK: - SelfLegalHoldSubject + Accepting Alert

extension SelfLegalHoldSubject {

    fileprivate func acceptLegalHoldChangeAlert() {
        ZMUserSession.shared()?.performChanges {
            self.acknowledgeLegalHoldStatus()
        }
    }

    fileprivate func handleLegalHoldActivationSuccess(for request: LegalHoldRequest) {
        ZMUserSession.shared()?.performChanges {
            self.acknowledgeLegalHoldStatus()
            self.userDidAcceptLegalHoldRequest(request)
        }
    }

}
