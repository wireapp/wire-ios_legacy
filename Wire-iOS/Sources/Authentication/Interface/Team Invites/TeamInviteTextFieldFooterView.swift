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

import UIKit

final class TeamInviteTextFieldFooterView: UIView {

    private let textFieldDescriptor = TextFieldDescription(
        placeholder: "team.invite.textfield.placeholder".localized,
        actionDescription: "team.invite.textfield.accesibility".localized,
        kind: .email,
        uppercasePlaceholder: true
    )

    var isLoading = false {
        didSet {
            updateLoadingState()
        }
    }

    let errorButton = Button(fontSpec: .mediumSemiboldFont)
    private let textField: ValidatedTextField
    private let errorLabel = UILabel()

    var shouldConfirm: ((String) -> Bool)? {
        didSet {
            textField.textFieldValidator.customValidator = { [weak self] email in
                (self?.shouldConfirm?(email) ?? true) ? nil : .custom("team.invite.error.already_invited".localized(uppercased: true))
            }
        }
    }

    var onConfirm: ((Any) -> Void)? {
        didSet {
            textFieldDescriptor.valueSubmitted = onConfirm
        }
    }

    var errorMessage: String? {
        didSet {
            errorLabel.text = errorMessage
        }
    }

    @discardableResult override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    init() {
        textField = textFieldDescriptor.create() as! ValidatedTextField
        super.init(frame: .zero)
        setupViews()
        createConstraints()
        isAccessibilityElement = false
        accessibilityElements = [textField, errorLabel, errorButton]
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        errorButton.isHidden = true
        errorLabel.textAlignment = .center
        errorLabel.font = AuthenticationStepController.errorMessageFont
        errorLabel.textColor = UIColor.from(scheme: .errorIndicator, variant: .light)
        textField.overrideButtonIcon = .send
        textFieldDescriptor.valueValidated = { [weak self] validation in
            if case .error(let error, let showVisualFeedback)? = validation, showVisualFeedback {
                self?.errorMessage = error.errorDescription?.localizedUppercase
            } else {
                self?.errorButton.isHidden = true
            }
        }

        errorButton.setTitle("team.invite.learn_more.title".localized(uppercased: true), for: .normal)
        errorButton.setTitleColor(.black, for: .normal)
        errorButton.setTitleColor(.darkGray, for: .highlighted)
        errorButton.accessibilityIdentifier = "LearnMoreButton"
        errorButton.addTarget(self, action: #selector(showLearnMorePage), for: .touchUpInside)
        textField.accessibilityLabel = "EmailInputField"
        [textField, errorLabel, errorButton].forEach(addSubview)
        backgroundColor = .clear
    }

    private func createConstraints() {
        [textField, errorLabel, errorButton].prepareForLayout()

        NSLayoutConstraint.activate([
          textField.leadingAnchor.constraint(equalTo: leadingAnchor),
          textField.trailingAnchor.constraint(equalTo: trailingAnchor),
          textField.topAnchor.constraint(equalTo: topAnchor, constant: 4),
          textField.heightAnchor.constraint(equalToConstant: 56),
          errorLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
          errorLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
          errorLabel.heightAnchor.constraint(equalToConstant: 20),

          errorButton.centerXAnchor.constraint(equalTo: centerXAnchor),
          errorButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
          errorButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)])
    }

    func clearInput() {
        textField.text = ""
        textField.textFieldDidChange(textField: textField)
    }

    @objc private func showLearnMorePage() {
        let url = URL.wr_emailAlreadyInUseLearnMore
        UIApplication.shared.open(url)
    }

    private func updateLoadingState() {
        textField.isLoading = isLoading
        textFieldDescriptor.acceptsInput = !isLoading
    }
}
