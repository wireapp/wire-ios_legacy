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
import WireDataModel
import WireCommonComponents

/// An object that receives notification about the phone number input view.
protocol PhoneNumberInputViewDelegate: AnyObject {
    func phoneNumberInputView(_ inputView: PhoneNumberInputView, didPickPhoneNumber phoneNumber: PhoneNumber)
    func phoneNumberInputView(_ inputView: PhoneNumberInputView, didValidatePhoneNumber phoneNumber: PhoneNumber, withResult validationError: TextFieldValidator.ValidationError?)
    func phoneNumberInputViewDidRequestCountryPicker(_ inputView: PhoneNumberInputView)
}

/**
 * A view providing an input field for phone numbers and a button for choosing the country.
 */

class PhoneNumberInputView: UIView, UITextFieldDelegate, TextFieldValidationDelegate, TextContainer {

    typealias RegistrationEnterPhoneNumber = L10n.Localizable.Registration.EnterPhoneNumber

    /// The object receiving notifications about events from this view.
    weak var delegate: PhoneNumberInputViewDelegate?

    /// The currently selected country.
    private(set) var country = Country.defaultCountry

    /// The validation error for the current input.
    private(set) var validationError: TextFieldValidator.ValidationError? = .tooShort(kind: .phoneNumber)

    var hasPrefilledValue: Bool = false
    var allowEditingPrefilledValue: Bool = true {
        didSet {
            updatePhoneNumberInputFieldIsEnabled()
        }
    }
    var allowEditing: Bool {
        return !hasPrefilledValue || allowEditingPrefilledValue
    }

    /// Whether to show the confirm button.
    var showConfirmButton: Bool = true {
        didSet {
            textField.showConfirmButton = showConfirmButton
        }
    }

    /// The value entered by the user.
    var input: String {
        return textField.input
    }

    var text: String? {
        get { return textField.text }
        set {
            hasPrefilledValue = newValue != nil
            textField.text = newValue
            updatePhoneNumberInputFieldIsEnabled()
        }
    }

    // MARK: - Views

    private let countryPickerButton = IconButton()

    private let inputStack = UIStackView()
    let loginButton = Button(style: .accentColorTextButtonStyle,
                             cornerRadius: 16,
                             fontSpec: .normalSemiboldFont)
    private let countryCodeInputView = IconButton()
    private let textField = ValidatedTextField(kind: .phoneNumber, leftInset: 8, style: .default)

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
        configureValidation()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        // countryPickerButton
        countryPickerButton.accessibilityIdentifier = "CountryPickerButton"
        countryPickerButton.titleLabel?.font = FontSpec.normalLightFont.font!
        countryPickerButton.contentHorizontalAlignment = UIApplication.isLeftToRightLayout ? .left : .right
        countryPickerButton.addTarget(self, action: #selector(handleCountryButtonTap), for: .touchUpInside)
        countryPickerButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addSubview(countryPickerButton)

        // countryCodeButton
        countryCodeInputView.setContentHuggingPriority(.required, for: .horizontal)
        countryCodeInputView.setTitleColor(SemanticColors.Label.textDefault, for: .normal)
        countryCodeInputView.titleLabel?.font = FontSpec.normalRegularFontWithInputTextStyle.font!
        countryCodeInputView.titleEdgeInsets.top = -1
        countryCodeInputView.isUserInteractionEnabled = false
        countryCodeInputView.accessibilityTraits = [.staticText]
        inputStack.addArrangedSubview(countryCodeInputView)

        // inputStack
        inputStack.axis = .horizontal
        inputStack.spacing = 0
        inputStack.distribution = .fill
        inputStack.alignment = .fill
        addSubview(inputStack)

        // textField
        textField.textInsets.left = 10
        textField.placeholder = RegistrationEnterPhoneNumber.placeholder.capitalized
        textField.accessibilityLabel = RegistrationEnterPhoneNumber.placeholder.capitalized
        textField.accessibilityIdentifier = "PhoneNumberField"
        textField.addDoneButtonOnKeyboard()
        textField.showConfirmButton = false

        textField.delegate = self
        textField.textFieldValidationDelegate = self
        inputStack.addArrangedSubview(textField)

        selectCountry(.defaultCountry)

        // loginButton
        loginButton.setTitle(L10n.Localizable.Landing.Login.Button.title.capitalized, for: .normal)
        loginButton.addTarget(self, action: #selector(handleLoginButtonTap), for: .touchUpInside)

        if let text = textField.text, text.isEmpty {
            loginButton.isEnabled = false
        }

        addSubview(loginButton)

        backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func configureConstraints() {
        [inputStack, countryPickerButton, loginButton].prepareForLayout()

        NSLayoutConstraint.activate([
            // countryPickerStack
            countryPickerButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            countryPickerButton.topAnchor.constraint(equalTo: topAnchor),
            countryPickerButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            countryPickerButton.heightAnchor.constraint(equalToConstant: 28),

            // inputStack
            inputStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputStack.topAnchor.constraint(equalTo: countryPickerButton.bottomAnchor, constant: 20),
            inputStack.trailingAnchor.constraint(equalTo: trailingAnchor),

            // dimensions
            textField.heightAnchor.constraint(equalToConstant: 48),
            countryCodeInputView.widthAnchor.constraint(equalToConstant: 60),

            // loginButton
            loginButton.topAnchor.constraint(equalTo: inputStack.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 48),
            loginButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func configureValidation() {

        textField.textFieldValidator.customValidator = { input in
            let phoneNumber = self.country.e164PrefixString + input
            let normalizedNumber = UnregisteredUser.normalizedPhoneNumber(phoneNumber)

            switch normalizedNumber {
            case .invalid(let errorCode):
                switch errorCode {
                case .tooLong: return .tooLong(kind: .phoneNumber)
                case .tooShort: return .tooShort(kind: .phoneNumber)
                default: return .invalidPhoneNumber
                }
            case .unknownError:
                return .invalidPhoneNumber
            case .valid:
                return .none
            }
        }
    }

    // MARK: - Customization

    var textColor: UIColor = SemanticColors.Label.textDefault {
        didSet {
            countryCodeInputView.setTitleColor(textColor, for: .normal)
            updateCountryButtonLabel()
        }
    }

    // MARK: - View Lifecycle

    override var canBecomeFirstResponder: Bool {
        return textField.canBecomeFirstResponder
    }

    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    override var canResignFirstResponder: Bool {
        return textField.canResignFirstResponder
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    /**
     * Selects the specified country as the beginning of the phone number.
     * - parameter country: The country of the phone number,
     */

    func selectCountry(_ country: Country) {
        self.country = country
        updateCountryButtonLabel()

        countryPickerButton.accessibilityValue = country.displayName
        countryPickerButton.accessibilityLabel = L10n.Localizable.Registration.phoneCountry

        countryCodeInputView.setTitle(country.e164PrefixString, for: .normal)
        countryCodeInputView.accessibilityLabel = L10n.Localizable.Registration.phoneCode
        countryCodeInputView.accessibilityValue = country.e164PrefixString
    }

    private func updateCountryButtonLabel() {
        let title = country.displayName
        let color = textColor
        let selectedColor = textColor.withAlphaComponent(0.4)

        tintColor = color
        let icon = NSTextAttachment.downArrow(color: color)
        let selectedIcon = NSTextAttachment.downArrow(color: selectedColor)

        let normalLabel = title.addingTrailingAttachment(icon, verticalOffset: 1) && color
        countryPickerButton.setAttributedTitle(normalLabel, for: .normal)

        let selectedLabel = title.addingTrailingAttachment(selectedIcon, verticalOffset: 1) && selectedColor
        countryPickerButton.setAttributedTitle(selectedLabel, for: .highlighted)
    }

    /// Sets the phone number to display.
    func setPhoneNumber(_ phoneNumber: PhoneNumber) {
        hasPrefilledValue = true
        selectCountry(phoneNumber.country)
        textField.updateText(phoneNumber.numberWithoutCode)
        updatePhoneNumberInputFieldIsEnabled()
    }

    func updatePhoneNumberInputFieldIsEnabled() {
        countryPickerButton.isEnabled = allowEditing
    }

    // MARK: - Text Update

    /// Returns whether the text should be updated.
    func shouldChangeCharacters(in range: NSRange, replacementString: String) -> Bool {
        guard
            allowEditing,
            let replacementRange = Range(range, in: input)
        else {
            return false
        }

        let updatedString = input.replacingCharacters(in: replacementRange, with: replacementString)
        return shouldUpdatePhoneNumber(updatedString)
    }

    /// Updates the phone number with a new value.
    private func shouldUpdatePhoneNumber(_ updatedString: String?) -> Bool {
        guard let updatedString = updatedString else { return false }

        // If the textField is empty and a replacementString with a +, it is likely to insert from autoFill.
        if textField.text?.count == 0 && updatedString.contains("+") {
            return shouldInsert(phoneNumber: updatedString)
        }

        var number = PhoneNumber(countryCode: country.e164, numberWithoutCode: updatedString)

        switch number.validate() {
        case .containsInvalidCharacters, .tooLong:
            return false
        default:
            return true
        }
    }

    // MARK: - Events

    @objc
    private func handleCountryButtonTap() {
        delegate?.phoneNumberInputViewDidRequestCountryPicker(self)
    }

    @objc
    private func handleLoginButtonTap() {
        submitValue()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return UIPasteboard.general.hasStrings
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }

    /// Do not paste if we need to set the text manually.
    override func paste(_ sender: Any?) {
        var shouldPaste = true

        if UIPasteboard.general.hasStrings {
            shouldPaste = shouldInsert(phoneNumber: UIPasteboard.general.string ?? "")
        }

        if shouldPaste {
            textField.paste(sender)
        }
    }

    /// Only insert text if we have a valid phone number.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return shouldChangeCharacters(in: range, replacementString: string)
    }

    /**
     * Checks whether the inserted text contains a phone number. If it does, we overtake the paste / text change mechanism and
     * update the country and text field manually.
     * - parameter phoneNumber: The text that is being inserted.
     * - returns: Whether the text should be inserted by the text field or if we need to insert it manually.
     */

    private func shouldInsert(phoneNumber: String) -> Bool {
        guard let (country, phoneNumberWithoutCountryCode) = phoneNumber.shouldInsertAsPhoneNumber(presetCountry: country) else {
            return true
        }

        selectCountry(country)
        textField.updateText(phoneNumberWithoutCountryCode)
        return false
    }

    // MARK: - Value Submission

    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        self.validationError = error
        let phoneNumber = PhoneNumber(countryCode: country.e164, numberWithoutCode: input)
        delegate?.phoneNumberInputView(self, didValidatePhoneNumber: phoneNumber, withResult: validationError)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textField.validateInput()

        if self.validationError == .none {
            submitValue()
            return true
        } else {
            return false
        }
    }

    func submitValue() {
        var phoneNumber = PhoneNumber(countryCode: country.e164, numberWithoutCode: textField.input)
        let validationResult = phoneNumber.validate()

        delegate?.phoneNumberInputView(self, didValidatePhoneNumber: phoneNumber, withResult: validationError)

        if validationError == nil && validationResult == .valid {
            delegate?.phoneNumberInputView(self, didValidatePhoneNumber: phoneNumber, withResult: nil)
            delegate?.phoneNumberInputView(self, didPickPhoneNumber: phoneNumber)
        }
    }

}
