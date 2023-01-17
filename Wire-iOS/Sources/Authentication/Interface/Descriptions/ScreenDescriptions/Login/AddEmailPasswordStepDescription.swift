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
import WireUtilities
import UIKit

class AddEmailPasswordStepDescription: DefaultValidatingStepDescription {

    let backButton: BackButtonDescription?
    var mainView: ViewDescriptor & ValueSubmission {
        emailPasswordFieldDescription
    }
    let headline: String
    let subtext: String?
    let secondaryView: AuthenticationSecondaryViewDescription?
    let initialValidation: ValueValidation
    let footerView: AuthenticationFooterViewDescription?

    private let emailPasswordFieldDescription = EmailPasswordFieldDescription(forRegistration: true, usePasswordDeferredValidation: true)

    init() {
        backButton = BackButtonDescription()
        headline = "registration.add_email_password.hero.title".localized
        subtext = "registration.add_email_password.hero.paragraph".localized
        initialValidation = .info(PasswordRuleSet.localizedErrorMessage)
        footerView = nil

        let loginDescription = LoginFooterDescription()
        secondaryView = loginDescription
        loginDescription.loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)

        emailPasswordFieldDescription.textField.delegate = self

        updateLoginButtonState(emailPasswordFieldDescription.textField)
    }

    @objc
    func loginButtonTapped(sender: Any) {
        if let passwordError = emailPasswordFieldDescription.textField.passwordValidationError {
            emailPasswordFieldDescription.valueValidated?(.error(passwordError, showVisualFeedback: true))
            return
        }

        let credentials = (emailPasswordFieldDescription.textField.emailField.input, emailPasswordFieldDescription.textField.passwordField.input)
        emailPasswordFieldDescription.valueSubmitted?(credentials)
    }

    private func updateLoginButtonState(_ textField: EmailPasswordTextField) {
        (secondaryView as? LoginFooterDescription)?.loginButton.isEnabled = textField.emailField.isInputValid && textField.passwordField.isInputValid
    }
}

extension AddEmailPasswordStepDescription: EmailPasswordTextFieldDelegate {

    func textFieldDidUpdateText(_ textField: EmailPasswordTextField) {
        (secondaryView as? LoginFooterDescription)?.loginButton.isEnabled = textField.emailField.isInputValid && textField.passwordField.isInputValid
    }

    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String)) {}

    func textFieldDidSubmitWithValidationError(_ textField: EmailPasswordTextField) {}
}

// MARK: - LoginFooterDescription

private class LoginFooterDescription: ViewDescriptor, AuthenticationSecondaryViewDescription {
    var views: [ViewDescriptor] {
        [self]
    }

    var actioner: AuthenticationActioner?

    let loginButton = Button(style: .accentColorTextButtonStyle,
                             cornerRadius: 16,
                             fontSpec: .buttonBigSemibold)

    init() {
        loginButton.setTitle(L10n.Localizable.Landing.Login.Button.title.capitalized, for: .normal)
    }

    func create() -> UIView {
        let containerView = UIView()
        containerView.addSubview(loginButton)

        loginButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loginButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 31),
            loginButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 31),
            loginButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -31),
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        return containerView
    }

    func display(on error: Error) -> ViewDescriptor? {
        return nil
    }
}
