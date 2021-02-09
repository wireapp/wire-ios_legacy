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
    func textFieldDidSubmitWithValidationError(_ textField: EmailPasswordTextField)
    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String))
}

class EmailPasswordTextField: UIView, MagicTappable {

    let emailField = ValidatedTextField(kind: .email)
    let passwordField = ValidatedTextField(kind: .password(isNew: false))
    let contentStack = UIStackView()
    let separatorContainer: ContentInsetView

    var hasPrefilledValue: Bool = false
    var allowEditingPrefilledValue: Bool = true {
        didSet {
            updateEmailFieldisEnabled()
        }
    }

    weak var delegate: EmailPasswordTextFieldDelegate?

    private(set) var emailValidationError: TextFieldValidator.ValidationError? = .tooShort(kind: .email)
    private(set) var passwordValidationError: TextFieldValidator.ValidationError? = .tooShort(kind: .email)

    // MARK: - Helpers

    var colorSchemeVariant: ColorSchemeVariant = .light {
        didSet {
            passwordField.colorSchemeVariant = colorSchemeVariant
            emailField.colorSchemeVariant = colorSchemeVariant
        }
    }

    var isPasswordEmpty: Bool {
        return passwordField.input.isEmpty
    }

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
        emailField.colorSchemeVariant = colorSchemeVariant
        emailField.enableConfirmButton = { [weak self] in
            self?.emailValidationError == nil
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
        passwordField.colorSchemeVariant = colorSchemeVariant

        passwordField.enableConfirmButton = { [weak self] in
            self?.isPasswordEmpty == false
        }

        contentStack.addArrangedSubview(passwordField)
    }

    private func configureConstraints() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // dimensions
            passwordField.heightAnchor.constraint(equalToConstant: 56),
            emailField.heightAnchor.constraint(equalToConstant: 56),
            separatorContainer.heightAnchor.constraint(equalToConstant: CGFloat.hairline),

            // contentStack
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    /// Pre-fills the e-mail text field.
    func prefill(email: String?) {
        hasPrefilledValue = email != nil
        emailField.text = email
        updateEmailFieldisEnabled()
    }
    
    func updateEmailFieldisEnabled() {
        emailField.isEnabled = !hasPrefilledValue || allowEditingPrefilledValue
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
        guard emailValidationError == nil && passwordValidationError == nil else {
            delegate?.textFieldDidSubmitWithValidationError(self)
            return
        }
        
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
    }

}

extension EmailPasswordTextField: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            emailField.validateInput()
            passwordField.validateInput()
            confirmButtonTapped()
        }

        return true
    }

}

extension EmailPasswordTextField: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        if sender == emailField {
            emailValidationError = error
        } else {
            passwordValidationError = error
        }
    }
}

