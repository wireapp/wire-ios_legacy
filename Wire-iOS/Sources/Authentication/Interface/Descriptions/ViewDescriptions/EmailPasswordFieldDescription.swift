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

import UIKit

final class EmailPasswordFieldDescription: ValueSubmission {
    let emailField: TextFieldDescription
    let passwordField: TextFieldDescription
    var prefilledEmail: String?

    var acceptsInput: Bool = true {
        didSet {
            emailField.acceptsInput = acceptsInput
            passwordField.acceptsInput = acceptsInput
        }
    }

    var valueSubmitted: ValueSubmitted?
    var valueValidated: ValueValidated?

    init(forRegistration: Bool, prefilledEmail: String? = nil) {
        self.prefilledEmail = prefilledEmail
        emailField = TextFieldDescription(placeholder: "email.placeholder".localized, actionDescription: "", kind: .email)
        emailField.showConfirmButton = false
        passwordField = TextFieldDescription(placeholder: "password.placeholder".localized, actionDescription: "", kind: .password(isNew: forRegistration))
    }

}

extension EmailPasswordFieldDescription: ViewDescriptor, EmailPasswordTextFieldDelegate {
    func create() -> UIView {
        let textField = EmailPasswordTextField()
        textField.delegate = self
        textField.prefill(email: prefilledEmail)
        textField.emailField.validateInput()
        return textField
    }

    func textFieldDidUpdateText(_ textField: EmailPasswordTextField) {
        // Reset the error message when the user changes the text
        valueValidated?(.none)
    }

    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String)) {
        valueSubmitted?(credentials)
    }

    func textField(_ textField: EmailPasswordTextField, didUpdateValidation isValid: Bool) {
        // no-op: we do not observe the validity of the input here
    }
}
