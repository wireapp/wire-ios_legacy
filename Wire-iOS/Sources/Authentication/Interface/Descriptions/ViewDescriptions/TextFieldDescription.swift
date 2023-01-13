//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

final class TextFieldDescription: NSObject, ValueSubmission {
    let placeholder: String
    let actionDescription: String
    let kind: ValidatedTextField.Kind
    var valueSubmitted: ValueSubmitted?
    var valueValidated: ValueValidated?
    var acceptsInput: Bool = true
    var validationError: TextFieldValidator.ValidationError?
    var showConfirmButton: Bool = true
    var canSubmit: (() -> Bool)?
    var textField: ValidatedTextField?
    var useDeferredValidation: Bool = false

    init(placeholder: String, actionDescription: String, kind: ValidatedTextField.Kind) {
        self.placeholder = placeholder
        self.actionDescription = actionDescription
        self.kind = kind
        validationError = .tooShort(kind: kind)
        super.init()

        canSubmit = { [weak self] in
            return (self?.acceptsInput == true) && (self?.validationError == nil)
        }
    }
}

extension TextFieldDescription: ViewDescriptor {
    func create() -> UIView {
        let textField = ValidatedTextField(kind: kind, style: .default)
        textField.enablesReturnKeyAutomatically = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = self.placeholder
        textField.delegate = self
        textField.textFieldValidationDelegate = self
        textField.confirmButton.addTarget(self, action: #selector(TextFieldDescription.confirmButtonTapped(_:)), for: .touchUpInside)
        textField.addTarget(self, action: #selector(TextFieldDescription.editingChanged), for: .editingChanged)
        textField.confirmButton.accessibilityLabel = self.actionDescription
        textField.showConfirmButton = showConfirmButton
        textField.accessibilityHint = PasswordRuleSet.localizedErrorMessage

        textField.enableConfirmButton = { [weak self] in
            if self?.useDeferredValidation == true {
                return !textField.input.isEmpty
            } else {
                return self?.canSubmit?() == true
            }
        }

        self.textField = textField

        let textfieldContainer = UIView()
        textfieldContainer.addSubview(textField)
        textfieldContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: textfieldContainer.topAnchor),
            textField.bottomAnchor.constraint(equalTo: textfieldContainer.bottomAnchor),
            textField.centerXAnchor.constraint(equalTo: textfieldContainer.centerXAnchor),
            textField.leadingAnchor.constraint(equalTo: textfieldContainer.leadingAnchor, constant: 31),
            textField.leadingAnchor.constraint(equalTo: textfieldContainer.trailingAnchor, constant: -31)
        ])

        return textfieldContainer
    }
}

extension TextFieldDescription: UITextFieldDelegate {

    @objc func confirmButtonTapped(_ sender: AnyObject) {
        guard let textField = self.textField, acceptsInput else { return }
        submitValue(with: textField.input)
    }

    @objc func editingChanged(sender: ValidatedTextField) {
        // If we use deferred validation, remove the error when the text changes
        guard useDeferredValidation else { return }
        self.valueValidated?(nil)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return acceptsInput
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let textField = self.textField, acceptsInput else { return false }

        textField.validateInput()

        if validationError == .none || useDeferredValidation {
            submitValue(with: textField.input)
            return true
        } else {
           return false
        }
    }

    func submitValue(with text: String) {
        if let error = validationError {
            self.valueValidated?(.error(error, showVisualFeedback: textField?.input.isEmpty == false))
        } else {
            self.valueValidated?(nil)
            self.valueSubmitted?(text)
        }
    }
}

extension TextFieldDescription: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        self.validationError = error
    }
}
