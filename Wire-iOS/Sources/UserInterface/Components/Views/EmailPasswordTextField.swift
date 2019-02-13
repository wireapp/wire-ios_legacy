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

protocol EmailPasswordTextFieldDelegate: class {
    func textFieldDidUpdateText(_ textField: EmailPasswordTextField)
    func textField(_ textField: EmailPasswordTextField, didUpdateValidation isValid: Bool)
    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String))
}

class EmailPasswordTextField: UIView, MagicTappable {

    let emailField = AccessoryTextField(kind: .email)
    let passwordField = AccessoryTextField(kind: .password(isNew: false))
    let contentStack = UIStackView()
    let separatorContainer: ContentInsetView

    var hasPrefilledValue: Bool = false

    weak var delegate: EmailPasswordTextFieldDelegate?

    private var emailValidationError: TextFieldValidator.ValidationError = .tooShort(kind: .email)
    private var passwordValidationError: TextFieldValidator.ValidationError = .tooShort(kind: .email)

    // MARK: - Initialization

    override init(frame: CGRect) {
        let separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        separatorContainer = ContentInsetView(UIView(), inset: separatorInset)
        super.init(frame: frame)

        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        let separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        separatorContainer = ContentInsetView(UIView(), inset: separatorInset)
        super.init(coder: aDecoder)

        configureSubviews()
        configureConstraints()
    }

    private func configureSubviews() {
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        addSubview(contentStack)

        emailField.delegate = self
        emailField.textFieldValidationDelegate = self
        emailField.placeholder = "email.placeholder".localized(uppercased: true)
        emailField.showConfirmButton = false
        emailField.addTarget(self, action: #selector(textInputDidChange), for: .editingChanged)

        emailField.enableConfirmButton = { [weak self] in
            self?.emailValidationError == TextFieldValidator.ValidationError.none
        }

        contentStack.addArrangedSubview(emailField)

        separatorContainer.view.backgroundColor = .white
        separatorContainer.view.backgroundColor = UIColor.from(scheme: .separator)
        contentStack.addArrangedSubview(separatorContainer)

        passwordField.delegate = self
        passwordField.textFieldValidationDelegate = self
        passwordField.placeholder = "password.placeholder".localized(uppercased: true)
        passwordField.bindConfirmationButton(to: emailField)
        passwordField.addTarget(self, action: #selector(textInputDidChange), for: .editingChanged)
        passwordField.confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)

        passwordField.enableConfirmButton = { [weak self] in
            self?.passwordValidationError == TextFieldValidator.ValidationError.none
        }

        contentStack.addArrangedSubview(passwordField)
    }

    private func configureConstraints() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.fitInSuperview()
        separatorContainer.heightAnchor.constraint(equalToConstant: CGFloat.hairline).isActive = true
    }

    /// Pre-fills the e-mail text field.
    func prefill(email: String?) {
        hasPrefilledValue = email != nil
        emailField.text = email
    }

    // MARK: - Appearance

    func setTextColor(_ color: UIColor) {
        emailField.textColor = color
        passwordField.textColor = color
    }

    func setBackgroundColor(_ color: UIColor) {
        emailField.backgroundColor = color
        passwordField.backgroundColor = color
    }

    func setSeparatorColor(_ color: UIColor) {
        separatorContainer.view.backgroundColor = color
    }

    // MARK: - Responder

    override var isFirstResponder: Bool {
        return emailField.isFirstResponder || passwordField.isFirstResponder
    }

    override var canBecomeFirstResponder: Bool {
        return logicalFirstResponder.canBecomeFirstResponder
    }

    override func becomeFirstResponder() -> Bool {
        return logicalFirstResponder.becomeFirstResponder()
    }

    override var canResignFirstResponder: Bool {
        return emailField.canResignFirstResponder || passwordField.canResignFirstResponder
    }

    @discardableResult override func resignFirstResponder() -> Bool {
        if emailField.isFirstResponder {
            return emailField.resignFirstResponder()
        } else if passwordField.isFirstResponder {
            return passwordField.resignFirstResponder()
        } else {
            return false
        }
    }

    /// Returns the text field that should be used to become first responder.
    private var logicalFirstResponder: UITextField {
        // If we have a pre-filled email and the password field is empty, start with the password field
        if hasPrefilledValue && (passwordField.text ?? "").isEmpty {
            return passwordField
        } else {
            return emailField
        }
    }

    // MARK: - Submission

    @objc private func confirmButtonTapped() {
        delegate?.textField(self, didConfirmCredentials: (emailField.input, passwordField.input))
    }

    func performMagicTap() -> Bool {
        guard emailField.isInputValid && passwordField.isInputValid else {
            return false
        }

        confirmButtonTapped()
        return true
    }

    @objc private func textInputDidChange(sender: UITextField) {
        if sender == emailField {
            emailField.validateInput()
        } else if sender == passwordField {
            passwordField.validateInput()
        }

        delegate?.textFieldDidUpdateText(self)

        let isValid = emailField.isInputValid && passwordField.isInputValid
        delegate?.textField(self, didUpdateValidation: isValid)
    }

}

extension EmailPasswordTextField: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
            return true
        } else if textField == passwordField {
            emailField.validateInput()
            passwordField.validateInput()

            if emailField.isInputValid && passwordField.isInputValid {
                confirmButtonTapped()
            } else {
                return false
            }
        }

        return true
    }

}

extension EmailPasswordTextField: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError) {
        if sender == emailField {
            emailValidationError = error
        } else {
            passwordValidationError = error
        }
    }
}

