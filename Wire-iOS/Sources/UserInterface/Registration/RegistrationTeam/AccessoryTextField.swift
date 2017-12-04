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
import Cartography

protocol TextFieldValidationDelegate: class {

    /// Delegate for validation. It is called when every time .editingChanged event fires
    ///
    /// - Parameters:
    ///   - sender: the sender is the textfield needs to validate
    ///   - error: An error object that indicates why the request failed, or nil if the request was successful.
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError)
}

class AccessoryTextField: UITextField {
    enum Kind {
        case email
        case name
        case password
        case unknown
    }

    let textFieldValidator: TextFieldValidator
    public var textFieldValidationDelegate: TextFieldValidationDelegate?

    // MARK:- UI constants

    static let enteredTextFont = FontSpec(.normal, .regular, .inputText).font!
    static let placeholderFont = FontSpec(.small, .regular).font!
    static private let ConfirmButtonWidth: CGFloat = 32

    var kind: Kind {
        didSet {
            setupTextFieldProperties()
        }
    }

    let confirmButton: IconButton = {
        let iconButton = IconButton.iconButtonCircularLight()
        iconButton.circular = true

        iconButton.setIcon(UIApplication.isLeftToRightLayout ? .chevronRight : .chevronLeft, with: ZetaIconSize.tiny, for: .normal)
        iconButton.setIconColor(UIColor.Team.textColor, for: .normal)
        iconButton.setIconColor(UIColor.Team.textfieldColor, for: .disabled)
        iconButton.adjustsImageWhenDisabled = false
        iconButton.setBackgroundImageColor(UIColor.Team.activeButtonColor, for: .normal)
        iconButton.setBackgroundImageColor(UIColor.Team.inactiveButtonColor, for: .disabled)

        iconButton.accessibilityIdentifier = "AccessoryTextFieldConfirmButton"
        iconButton.isEnabled = false

        return iconButton
    }()

    let textInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 8)
    let placeholderInsets: UIEdgeInsets

    /// Init with kind for keyboard style and validator type. Default is .unknown
    ///
    /// - Parameter kind: the type of text field
    init(kind: Kind = .unknown) {
        let leftInset: CGFloat = 8

        var topInset: CGFloat = 0
        if #available(iOS 11, *) {
            topInset = 0
        } else {
            /// Placeholder frame calculation is changed in iOS 11, therefore the TOP inset is not necessary
            topInset = 8
        }

        placeholderInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: 0, right: 16)
        textFieldValidator = TextFieldValidator()

        self.kind = kind

        super.init(frame: .zero)
        self.setupTextFieldProperties()

        self.rightView = self.confirmButton
        self.rightViewMode = .always

        self.font = AccessoryTextField.enteredTextFont
        self.textColor = UIColor.Team.textColor

        autocorrectionType = .no
        contentVerticalAlignment = .center
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            layer.cornerRadius = 4
        default:
            break
        }
        layer.masksToBounds = true
        backgroundColor = UIColor.Team.textfieldColor

        setup()
        setupTextFieldProperties()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        confirmButton.setNeedsLayout()
    }

    private func setupTextFieldProperties() {
        self.returnKeyType = .next

        switch kind {
        case .email:
            keyboardType = .emailAddress
            autocorrectionType = .no
            autocapitalizationType = .none
            accessibilityIdentifier = "EmailField"
        case .password:
            isSecureTextEntry = true
            accessibilityIdentifier = "PasswordField"
        case .name:
            autocapitalizationType = .words
            accessibilityIdentifier = "NameField"
        case .unknown:
            keyboardType = .asciiCapable
        }
    }

    private func setup() {
        self.confirmButton.addTarget(self, action: #selector(confirmButtonTapped(button:)), for: .touchUpInside)
        self.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let textRect = super.textRect(forBounds: bounds)

        return UIEdgeInsetsInsetRect(textRect, self.textInsets)
    }

    func textFieldDidChange(textField: UITextField) {
        /// enable button if we have some text entered
        let text = textField.text ?? ""
        confirmButton.isEnabled = !text.isEmpty
    }

    // MARK: - text validation

    func confirmButtonTapped(button: UIButton) {
        let error = textFieldValidator.validate(text: text, kind: kind)
        textFieldValidationDelegate?.validationUpdated(sender: self, error: error)
    }

    // MARK: - placeholder

    func attributedPlaceholderString(placeholder: String) -> NSAttributedString {
        let attribute: [String: Any] = [NSForegroundColorAttributeName: UIColor.Team.placeholderColor,
                                        NSFontAttributeName: AccessoryTextField.placeholderFont]
        return placeholder && attribute
    }

    override open var placeholder: String? {
        set {
            if let newValue = newValue {
                attributedPlaceholder = attributedPlaceholderString(placeholder: newValue.uppercased())
            }
        }
        get {
            return super.placeholder
        }
    }

    override func drawPlaceholder(in rect: CGRect) {
        super.drawPlaceholder(in: UIEdgeInsetsInsetRect(rect, placeholderInsets))
    }

    // MARK: - right and left accessory

    func rightAccessoryViewRect(forBounds bounds: CGRect, leftToRight: Bool) -> CGRect {
        var rightViewRect: CGRect
        let newY = bounds.origin.y + (bounds.size.height -  AccessoryTextField.ConfirmButtonWidth) / 2
        let xOffset: CGFloat = 16

        if leftToRight {
            rightViewRect = CGRect(x: CGFloat(bounds.maxX - AccessoryTextField.ConfirmButtonWidth - xOffset), y: newY, width: AccessoryTextField.ConfirmButtonWidth, height: AccessoryTextField.ConfirmButtonWidth)
        } else {
            rightViewRect = CGRect(x: bounds.origin.x + xOffset, y: newY, width: AccessoryTextField.ConfirmButtonWidth, height: AccessoryTextField.ConfirmButtonWidth)
        }

        return rightViewRect
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let leftToRight: Bool = UIApplication.isLeftToRightLayout
        if leftToRight {
            return rightAccessoryViewRect(forBounds: bounds, leftToRight: leftToRight)
        } else {
            return .zero
        }
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        let leftToRight: Bool = UIApplication.isLeftToRightLayout
        if leftToRight {
            return .zero
        } else {
            return rightAccessoryViewRect(forBounds: bounds, leftToRight: leftToRight)
        }
    }
}
