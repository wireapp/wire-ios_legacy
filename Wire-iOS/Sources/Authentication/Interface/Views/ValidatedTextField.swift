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
import WireCommonComponents

protocol TextFieldValidationDelegate: class {

    /// Delegate for validation. It is called when every time .editingChanged event fires
    ///
    /// - Parameters:
    ///   - sender: the sender is the textfield needs to validate
    ///   - error: An error object that indicates why the request failed, or nil if the request was successful.
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?)
}

protocol ValidatedTextFieldDelegate: class {
    func buttonPressed(_ sender: UIButton)
}

final class ValidatedTextField: AccessoryTextField, TextContainer, Themeable {
    enum Kind: Equatable {
        case email
        case name(isTeam: Bool)
        case password(isNew: Bool)
        case passcode(isNew: Bool)
        case phoneNumber
        case unknown
    }

    let textFieldValidator: TextFieldValidator
    weak var textFieldValidationDelegate: TextFieldValidationDelegate?
    weak var validatedTextFieldDelegate: ValidatedTextFieldDelegate?

    // MARK: - UI constants

    static let enteredTextFont = FontSpec(.normal, .regular, .inputText).font!
    static let placeholderFont = FontSpec(.small, .regular).font!
    static let ConfirmButtonWidth: CGFloat = 32
    static let GuidanceDotWidth: CGFloat = 8

    var isLoading = false {
        didSet {
            updateLoadingState()
        }
    }

    var kind: Kind {
        didSet {
            setupTextFieldProperties()
        }
    }

    var overrideButtonIcon: StyleKitIcon? {
        didSet {
            updateButtonIcon()
        }
    }

    /// Whether to display the confirm button.
    var showConfirmButton: Bool = true {
        didSet {
            confirmButton.isHidden = !showConfirmButton
        }
    }

    @objc
    dynamic var colorSchemeVariant: ColorSchemeVariant = .light {
        didSet {
            applyColorScheme(colorSchemeVariant)
        }
    }

    /// The other text field that needs to be valid in order to enable the confirm button.
    private weak var boundTextField: ValidatedTextField?

    /**
     * Binds the state of the confirmation button to the validity of another text field.
     * The button will be enabled when both the current and bound fields are valid.
     */

    func bindConfirmationButton(to textField: ValidatedTextField) {
        assert(boundTextField == nil, "A text field cannot be bound to another text field more than once.")
        self.boundTextField = textField
        textField.boundTextField = self
    }

    var enableConfirmButton: (() -> Bool)?

    lazy var confirmButton: IconButton = {
        let iconButton: IconButton
        switch kind {
        case .passcode:
            iconButton = IconButton(style: .default, variant: .light)
            iconButton.accessibilityIdentifier = "RevealButton"
            iconButton.accessibilityLabel = "Reveal passcode"
            iconButton.isEnabled = true
        default:
            iconButton = IconButton(style: .circular, variant: .dark)
            iconButton.accessibilityIdentifier = "ConfirmButton"
            iconButton.accessibilityLabel = "general.next".localized
            iconButton.isEnabled = false
        }
        return iconButton
    }()

    let guidanceDot: RoundedView = {
        let indicator = RoundedView()
        indicator.shape = .circle
        indicator.isHidden = true
        return indicator
    }()

    let accessoryContainer = UIView()

    /// Init with kind for keyboard style and validator type. Default is .unknown
    /// - Parameters:
    ///   - kind: the type of text field
    ///   - leftInset: placeholder left inset
    ///   - cornerRadius: optional corner radius override
    init(kind: Kind = .unknown,
         leftInset: CGFloat = 8,
         accessoryTrailingInset: CGFloat = 16,
         cornerRadius: CGFloat? = nil) {
        
        textFieldValidator = TextFieldValidator()
        self.kind = kind

        let textFieldAttributes = AccessoryTextField.Attributes(textFont: ValidatedTextField.enteredTextFont,
                                                                    textColor: UIColor.Team.textColor,
                                                                    placeholderFont: ValidatedTextField.placeholderFont,
                                                                    placeholderColor: UIColor.Team.placeholderColor,
                                                                    backgroundColor: UIColor.Team.textfieldColor,
                                                                    cornerRadius: cornerRadius ?? 0)
        super.init(leftInset: leftInset,
                   accessoryTrailingInset: accessoryTrailingInset,
                   textFieldAttributes: textFieldAttributes)
        self.setupTextFieldProperties()

        setup()
        setupTextFieldProperties()
        updateButtonIcon()
        applyColorScheme(colorSchemeVariant)
    }

    private func setupTextFieldProperties() {
        returnKeyType = .next

        switch kind {
        case .email:
            keyboardType = .emailAddress
            autocorrectionType = .no
            autocapitalizationType = .none
            accessibilityIdentifier = "EmailField"
            textContentType = .emailAddress
        case .password(let isNew):
            isSecureTextEntry = true
            accessibilityIdentifier = "PasswordField"
            autocapitalizationType = .none
            if #available(iOS 12, *) {
                textContentType = isNew ? .newPassword : .password
                passwordRules = textFieldValidator.passwordRules
            }
        case .name(let isTeam):
            autocapitalizationType = .words
            accessibilityIdentifier = "NameField"
            textContentType = isTeam ? .organizationName : .name
        case .phoneNumber:
            textContentType = .telephoneNumber
            keyboardType = .numberPad
            accessibilityIdentifier = "PhoneNumberField"
        case .unknown:
            keyboardType = .asciiCapable
            textContentType = nil
        case .passcode(let isNew):
            keyboardType = .asciiCapable
            isSecureTextEntry = true
            accessibilityIdentifier = "PasscodeField"
            autocapitalizationType = .none
            returnKeyType = isNew ? .default : .continue
            if #available(iOS 12, *) {
                //Hack: disable auto fill passcode
                textContentType = .oneTimeCode                
                passwordRules = textFieldValidator.passwordRules
            } else {
                textContentType = .init(rawValue: "")
            }
            
        }
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        guidanceDot.backgroundColor = UIColor.from(scheme: .errorIndicator, variant: colorSchemeVariant)
    }

    private func updateLoadingState() {
        updateButtonIcon()
        let animationKey = "rotation_animation"
        if isLoading {
            let animation = CABasicAnimation(rotationSpeed: 1.4, beginTime: 0)
            confirmButton.layer.add(animation, forKey: animationKey)
        } else {
            confirmButton.layer.removeAnimation(forKey: animationKey)
        }
    }

    private var buttonIcon: StyleKitIcon {
        return isLoading
            ? .spinner
            : overrideButtonIcon ?? (UIApplication.isLeftToRightLayout ? .forwardArrow : .backArrow)
    }

    private var iconSize: StyleKitIcon.Size {
        return isLoading ? .medium : .tiny
    }

    private func updateButtonIcon() {
        confirmButton.setIcon(buttonIcon, size: iconSize, for: .normal)

        if isLoading {
            confirmButton.setIconColor(UIColor.Team.inactiveButtonColor, for: .normal)
            confirmButton.setBackgroundImageColor(.clear, for: .normal)
            confirmButton.setBackgroundImageColor(.clear, for: .disabled)
        } else {

            switch kind {
            case .passcode:
                confirmButton.setIconColor(UIColor.Team.textColor, for: .normal)
                confirmButton.setIconColor(UIColor.Team.textColor, for: .disabled)
                confirmButton.setBackgroundImageColor(.clear, for: .normal)
                confirmButton.setBackgroundImageColor(.clear, for: .disabled)
            default:
                confirmButton.setIconColor(UIColor.Team.textfieldColor, for: .normal)
                confirmButton.setIconColor(UIColor.Team.textfieldColor, for: .disabled)
                confirmButton.setBackgroundImageColor(UIColor.Team.activeButtonColor, for: .normal)
                confirmButton.setBackgroundImageColor(UIColor.Team.inactiveButtonColor, for: .disabled)
            }
        }

        confirmButton.adjustsImageWhenDisabled = false
    }

    private func setup() {
        accessoryStack.addArrangedSubview(guidanceDot)
        accessoryStack.addArrangedSubview(confirmButton)

        confirmButton.addTarget(self, action: #selector(confirmButtonTapped(button:)), for: .touchUpInside)
        addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        NSLayoutConstraint.activate([
            confirmButton.widthAnchor.constraint(equalToConstant: ValidatedTextField.ConfirmButtonWidth),
            confirmButton.heightAnchor.constraint(equalToConstant: ValidatedTextField.ConfirmButtonWidth),
            guidanceDot.widthAnchor.constraint(equalToConstant: ValidatedTextField.GuidanceDotWidth),
            guidanceDot.heightAnchor.constraint(equalToConstant: ValidatedTextField.GuidanceDotWidth)
        ])
    }

    @objc
    override func textFieldDidChange(textField: UITextField) {
        updateText(input)
    }

    /// Whether the input is valid.
    var isInputValid: Bool {
        return enableConfirmButton?() ?? !input.isEmpty
    }

    func updateText(_ text: String) {
        self.text = text
        validateInput()
        boundTextField?.validateInput()
    }

    private func updateConfirmButton() {
        if let boundTextField = boundTextField {
            confirmButton.isEnabled = boundTextField.isInputValid && self.isInputValid
        } else {
            confirmButton.isEnabled = isInputValid
        }
    }

    // MARK: - text validation

    @objc
    private func confirmButtonTapped(button: UIButton) {
        validatedTextFieldDelegate?.buttonPressed(button)
        validateInput()
    }

    func validateInput() {
        let error = textFieldValidator.validate(text: text, kind: kind)
        textFieldValidationDelegate?.validationUpdated(sender: self, error: error)
        updateConfirmButton()
    }

    func showGuidanceDot() {
        guidanceDot.isHidden = false
    }

    func hideGuidanceDot() {
        guidanceDot.isHidden = true
    }
}
