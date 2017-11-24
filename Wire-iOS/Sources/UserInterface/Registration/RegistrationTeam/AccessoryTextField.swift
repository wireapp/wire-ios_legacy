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

class AccessoryTextField : UITextField {
    let textFieldValidator: TextFieldValidator

    static let enteredTextFont = FontSpec(.normal, .regular, .inputText).font!
    static let placeholderFont = FontSpec(.small, .semibold).font!
    static private let ConfirmButtonWidth: CGFloat = 32

    var textFieldType: TextFieldType = .unknown {
        didSet{
            setupTextFieldProperties()
        }
    }

    let confirmButton: IconButton = {
        let iconButton = IconButton.iconButtonCircularLight()
        iconButton.circular = true

        iconButton.setIcon(UIApplication.isLeftToRightLayout ? .chevronRight : .chevronLeft, with: ZetaIconSize.searchBar, for: .normal)
        iconButton.setIconColor(.textColor, for: .normal)
        iconButton.setIconColor(.textfieldColor, for: .disabled)

        iconButton.setBackgroundImageColor(.activeButtonColor, for: .normal)
        iconButton.setBackgroundImageColor(.inactiveButtonColor, for: .disabled)

        iconButton.accessibilityIdentifier = "AccessoryTextFieldConfirmButton"

        iconButton.isEnabled = false

        return iconButton
    }()

    let textInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 8)
    let placeholderInsets: UIEdgeInsets


    /// init with textFieldType for keyboard style and validator type
    ///
    /// - Parameter textFieldType: the type for text field. If not set, default value .unknown is applied.
    convenience init(textFieldType: TextFieldType?) {
        self.init()

        if let textFieldType = textFieldType {
            self.textFieldType = textFieldType
        }
    }

    init() {
        let leftInset: CGFloat = 24

        var topInset: CGFloat = 0
        if #available(iOS 11, *) {
            topInset = 0
        }
        else {
            /// Placeholder frame calculation is changed in iOS 11, therefore the TOP inset is not necessary
            topInset = 8
        }

        placeholderInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: 0, right: 16)
        textFieldValidator = TextFieldValidator()

        super.init(frame: .zero)

        self.rightView = self.confirmButton
        self.rightViewMode = .always

        self.font = AccessoryTextField.enteredTextFont
        self.textColor = .textColor

        autocorrectionType = .no
        contentVerticalAlignment = .center
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            layer.cornerRadius = 4
        default:
            break
        }
        layer.masksToBounds = true
        backgroundColor = .textfieldColor

        textFieldValidator.delegate = self

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        confirmButton.setNeedsLayout()
    }

    private func setupTextFieldProperties() {
        switch textFieldType {
        case .email:
            break
        case .password:
            isSecureTextEntry = true
        case .name:
            break
        case .unknown:
            break
        }
    }

    private func setup() {
        createConstraints()

        self.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
    }

    private func createConstraints() {
        constrain(confirmButton) { confirmButton in
            confirmButton.width == confirmButton.height

            confirmButton.width == AccessoryTextField.ConfirmButtonWidth
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let textRect = super.textRect(forBounds: bounds)

        return UIEdgeInsetsInsetRect(textRect, self.textInsets);
    }

    // MARK:- text validation

    func textFieldDidChange(textField: UITextField){
        textFieldValidator.textDidChange(text: textField.text, textFieldType: self.textFieldType)
    }

    // MARK:- placeholder

    func attributedPlaceholderString(placeholder: String) -> NSAttributedString {
        let attribute : [String : Any] = [NSForegroundColorAttributeName: UIColor.placeholderColor,
                                          NSFontAttributeName: AccessoryTextField.placeholderFont]
        return placeholder && attribute
    }

    override open var placeholder: String?  {
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

    // MARK:- right and left accessory

    func rightAccessoryViewRect(forBounds bounds: CGRect, leftToRight: Bool) -> CGRect {
        var rightViewRect: CGRect
        let newY = bounds.origin.y + (bounds.size.height -  AccessoryTextField.ConfirmButtonWidth) / 2
        let xOffset: CGFloat = 16

        if leftToRight {
            rightViewRect = CGRect(x: CGFloat(bounds.maxX - AccessoryTextField.ConfirmButtonWidth - xOffset), y: newY, width: AccessoryTextField.ConfirmButtonWidth, height: AccessoryTextField.ConfirmButtonWidth)
        }
        else {
            rightViewRect = CGRect(x: bounds.origin.x + xOffset, y: newY, width: AccessoryTextField.ConfirmButtonWidth, height: AccessoryTextField.ConfirmButtonWidth)
        }

        return rightViewRect
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let leftToRight: Bool = UIApplication.isLeftToRightLayout
        if leftToRight {
            return rightAccessoryViewRect(forBounds: bounds, leftToRight: leftToRight)
        }
        else {
            return .zero
        }
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        let leftToRight: Bool = UIApplication.isLeftToRightLayout
        if leftToRight {
            return .zero
        }
        else {
            return rightAccessoryViewRect(forBounds: bounds, leftToRight: leftToRight)
        }
    }
}

extension AccessoryTextField: TextFieldValidatorDelegate {
    func validationErrorDidOccur(sender: Any, error: TextFieldValidationError?) {
        self.confirmButton.isEnabled = false
    }

    func validationSucceed(sender: Any, length: Int?) {
        self.confirmButton.isEnabled = true
    }
}
