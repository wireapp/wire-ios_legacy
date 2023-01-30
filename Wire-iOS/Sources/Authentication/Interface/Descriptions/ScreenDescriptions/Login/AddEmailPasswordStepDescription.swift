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

        let loginDescription = CTAFooterDescription()
        secondaryView = loginDescription
        loginDescription.ctaButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)

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
        (secondaryView as? CTAFooterDescription)?.ctaButton.isEnabled = textField.emailField.isInputValid && textField.passwordField.isInputValid
    }
}

extension AddEmailPasswordStepDescription: EmailPasswordTextFieldDelegate {

    func textFieldDidUpdateText(_ textField: EmailPasswordTextField) {
        (secondaryView as? CTAFooterDescription)?.ctaButton.isEnabled = textField.emailField.isInputValid && textField.passwordField.isInputValid
    }

    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String)) {}

    func textFieldDidSubmitWithValidationError(_ textField: EmailPasswordTextField) {}
}

// MARK: - CTAFooterDescription

private class CTAFooterDescription: ViewDescriptor, AuthenticationSecondaryViewDescription {
    var views: [ViewDescriptor] {
        [self]
    }

    var actioner: AuthenticationActioner?

    let ctaButton = Button(style: .accentColorTextButtonStyle,
                             cornerRadius: 16,
                             fontSpec: .buttonBigSemibold)

    init() {
        ctaButton.setTitle(L10n.Localizable.AddEmailPasswordStep.CtaButton.title.capitalized, for: .normal)
    }

    func create() -> UIView {
        let containerView = UIView()
        containerView.addSubview(ctaButton)

        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ctaButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 31),
            ctaButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 31),
            ctaButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -31),
            ctaButton.heightAnchor.constraint(equalToConstant: 48),
            ctaButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
        ])

        return containerView
    }

    func display(on error: Error) -> ViewDescriptor? {
        return nil
    }
}
