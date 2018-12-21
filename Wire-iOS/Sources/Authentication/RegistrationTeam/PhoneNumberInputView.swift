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

protocol PhoneNumberInputViewDelegate: class {
    func phoneNumberInputViewDidRequestCountryPicker(_ inputView: PhoneNumberInputView)
}

class PhoneNumberInputView: UIView {

    weak var delegate: PhoneNumberInputViewDelegate?

    let countryPickerStack = UIStackView()
    let countryPickerButton = UIButton()
    let countryPickerIndicator = UIImageView()

    let inputStack = UIStackView()
    let countryCodeInputView = IconButton()
    let textField = AccessoryTextField(kind: .phoneNumber)

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

    override var tintColor: UIColor! {
        didSet {
            countryPickerButton.setTitleColor(tintColor, for: .normal)
            reloadIcon()
        }
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
        inputStack.addArrangedSubview(textField)
        // textField.delegate = self

        selectCountry(.default)
    }

    func selectCountry(_ country: Country) {
        countryPickerButton.setTitle(country.displayName, for: .normal)
        countryPickerButton.accessibilityValue = country.displayName
        countryPickerButton.accessibilityLabel = "registration.phone_country".localized
        countryPickerButton.accessibilityHint = "registration.phone_country.hint".localized
        countryCodeInputView.setTitle(country.e164PrefixString, for: .normal)
        countryCodeInputView.accessibilityValue = country.e164PrefixString
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

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    @objc private func handleCountryButtonTap() {
        delegate?.phoneNumberInputViewDidRequestCountryPicker(self)
    }

}
