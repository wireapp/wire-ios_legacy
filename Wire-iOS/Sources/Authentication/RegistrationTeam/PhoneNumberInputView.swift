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

/// An object that receives notification about the phone number input view.
protocol PhoneNumberInputViewDelegate: class {
    func phoneNumberInputViewDidRequestCountryPicker(_ inputView: PhoneNumberInputView)
}

/**
 * A view providing an input field for phone numbers and a.
 */

class PhoneNumberInputView: UIView, UITextFieldDelegate {

    /// The object receiving notifications about events from this view.
    weak var delegate: PhoneNumberInputViewDelegate?

    /// The currently selected country.
    private(set) var country = Country.default

    // MARK: - Views

    private let countryPickerStack = UIStackView()
    private let countryPickerButton = UIButton()
    private let countryPickerIndicator = UIImageView()

    private let inputStack = UIStackView()
    private let countryCodeInputView = IconButton()
    private let textField = AccessoryTextField(kind: .phoneNumber)

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
        configureConstraints()
    }

    private func configureSubviews() {
        // countryPickerStack
        countryPickerStack.axis = .horizontal
        countryPickerStack.spacing = 0
        countryPickerStack.distribution = .fill
        addSubview(countryPickerStack)

        // countryPickerButton
        countryPickerButton.contentHorizontalAlignment = UIApplication.isLeftToRightLayout ? .left : .right
        countryPickerButton.setTitleColor(UIColor.from(scheme: .buttonFaded), for: .highlighted)
        countryPickerButton.titleLabel?.font = UIFont.normalLightFont
        countryPickerButton.accessibilityIdentifier = "CountryPickerButton"
        countryPickerButton.addTarget(self, action: #selector(handleCountryButtonTap), for: .touchUpInside)
        countryPickerButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        countryPickerStack.addArrangedSubview(countryPickerButton)

        // countryPickerIndicator
        countryPickerIndicator.contentMode = .scaleAspectFit
        countryPickerIndicator.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        countryPickerStack.addArrangedSubview(countryPickerIndicator)
        reloadIcon()

        // inputStack
        inputStack.axis = .horizontal
        inputStack.spacing = 0
        inputStack.distribution = .fill
        inputStack.alignment = .fill
        addSubview(inputStack)

        // countryCodeButton
        countryCodeInputView.setContentHuggingPriority(.required, for: .horizontal)
        countryCodeInputView.addTarget(self, action: #selector(handleCountryButtonTap), for: .touchUpInside)
        countryCodeInputView.setBackgroundImageColor(UIColor.Team.activeButtonColor, for: .normal)
        countryCodeInputView.setTitleColor(.white, for: .normal)
        countryCodeInputView.titleLabel?.font = UIFont.normalLightFont
        inputStack.addArrangedSubview(countryCodeInputView)

        // textField
        textField.placeholder = "registration.enter_phone_number.placeholder".localized(uppercased: true)
        textField.accessibilityLabel = "registration.enter_phone_number.placeholder".localized
        textField.accessibilityIdentifier = "PhoneNumberField"
        textField.tintColor = UIColor.Team.activeButtonColor
        textField.delegate = self

        inputStack.addArrangedSubview(textField)

        selectCountry(.default)
    }

    private func reloadIcon() {
        let iconType: ZetaIconType = UIApplication.isLeftToRightLayout ? .chevronRight : .chevronLeft
        countryPickerIndicator.image = UIImage(for: iconType, iconSize: .small, color: tintColor)
    }

    private func configureConstraints() {
        countryPickerStack.translatesAutoresizingMaskIntoConstraints = false
        inputStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // countryPickerStack
            countryPickerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            countryPickerStack.topAnchor.constraint(equalTo: topAnchor),
            countryPickerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            countryPickerStack.heightAnchor.constraint(equalToConstant: 28),

            // inputStack
            inputStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputStack.topAnchor.constraint(equalTo: countryPickerStack.bottomAnchor, constant: 16),
            inputStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            inputStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            // dimentions
            textField.heightAnchor.constraint(equalToConstant: 56),
            countryCodeInputView.widthAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - View Lifecycle

    override var tintColor: UIColor! {
        didSet {
            countryPickerButton.setTitleColor(tintColor, for: .normal)
            reloadIcon()
        }
    }

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    /**
     * Selects the specified country as the beginning of the phone number.
     * - parameter country: The country of the phone number,
     */

    func selectCountry(_ country: Country) {
        self.country = country
        countryPickerButton.setTitle(country.displayName, for: .normal)
        countryPickerButton.accessibilityValue = country.displayName
        countryPickerButton.accessibilityLabel = "registration.phone_country".localized
        countryPickerButton.accessibilityHint = "registration.phone_country.hint".localized
        countryCodeInputView.setTitle(country.e164PrefixString, for: .normal)
        countryCodeInputView.accessibilityValue = country.e164PrefixString
    }

    // MARK: - Events

    @objc private func handleCountryButtonTap() {
        delegate?.phoneNumberInputViewDidRequestCountryPicker(self)
    }

    @objc private func habdleConfirmButtonTap() {

    }

    /// Do not paste if we need to set the text manually.
    override open func paste(_ sender: Any?) {
        var shouldPaste = true

        if let pastedString = UIPasteboard.general.string {
            shouldPaste = shouldInsert(phoneNumber: pastedString)
        }

        if shouldPaste {
            super.paste(sender)
        }
    }

    /// Only insert text if we have a valid phone number.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let newString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else { return false }

        // If the textField is empty and a replacementString with a +, it is likely to insert from autoFill.
        if textField.text?.count == 0 && newString.contains("+") {
            return shouldInsert(phoneNumber: string)
        }

        let number = PhoneNumber(countryCode: country.e164.uintValue, numberWithoutCode: newString)

        switch number.validate() {
        case .containsInvalidCharacters, .tooLong:
            return false
        default:
            return true
        }
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

}
