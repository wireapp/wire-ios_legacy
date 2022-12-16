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
    let textField = RevisedEmailPasswordTextField()

    var forRegistration: Bool
    var prefilledEmail: String?
    var usePasswordDeferredValidation: Bool
    var acceptsInput: Bool = true

    var valueSubmitted: ValueSubmitted?
    var valueValidated: ValueValidated?

    init(forRegistration: Bool, prefilledEmail: String? = nil, usePasswordDeferredValidation: Bool = false) {
        self.forRegistration = forRegistration
        self.usePasswordDeferredValidation = usePasswordDeferredValidation
    }

}

extension EmailPasswordFieldDescription: ViewDescriptor, EmailPasswordTextFieldDelegate {
    func create() -> UIView {
        textField.passwordField.kind = .password(isNew: forRegistration)
        textField.delegate = self
        textField.prefill(email: prefilledEmail)
        textField.emailField.validateInput()
        return textField
    }

    func textFieldDidUpdateText(_ textField: EmailPasswordTextField) {
        // Reset the error message when the user changes the text and we use deferred validation
        guard usePasswordDeferredValidation else { return }
        valueValidated?(nil)
    }

    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String)) {
        valueSubmitted?(credentials)
    }

    func textFieldDidSubmitWithValidationError(_ textField: EmailPasswordTextField) {
        if let passwordError = textField.passwordValidationError {
            valueValidated?(.error(passwordError, showVisualFeedback: true))
        }
    }
}
