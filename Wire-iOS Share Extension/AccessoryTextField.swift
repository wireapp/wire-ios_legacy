//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

protocol AccessoryTextFieldDelegate: class {
    func buttonPressed(_ sender: UIButton)
}

final class AccessoryTextField: UITextField {

    weak var accessoryTextFieldDelegate: AccessoryTextFieldDelegate?

    // MARK: - UI constants

    static let enteredTextFont = UIFont.systemFont(ofSize: 26)
    static let placeholderFont = UIFont.systemFont(ofSize: 18)
    static let ConfirmButtonWidth: CGFloat = 32
    static let GuidanceDotWidth: CGFloat = 8

    var overrideButtonIcon: StyleKitIcon? {
        didSet {
            updateButtonIcon()
        }
    }

    var input: String {
        return text ?? ""
    }

    /// Whether to display the confirm button.
    var showConfirmButton: Bool = true {
        didSet {
            confirmButton.isHidden = !showConfirmButton
        }
    }

    /// The other text field that needs to be valid in order to enable the confirm button.
    private weak var boundTextField: AccessoryTextField?

    /**
     * Binds the state of the confirmation button to the validity of another text field.
     * The button will be enabled when both the current and bound fields are valid.
     */

    func bindConfirmationButton(to textField: AccessoryTextField) {
        assert(boundTextField == nil, "A text field cannot be bound to another text field more than once.")
        self.boundTextField = textField
        textField.boundTextField = self
    }

    var enableConfirmButton: (() -> Bool)?

    lazy var confirmButton: UIButton = {
        let iconButton = UIButton()
        iconButton.accessibilityIdentifier = "RevealButton"
        iconButton.accessibilityLabel = "Reveal passcode".localized
        iconButton.isEnabled = true
        return iconButton
    }()
    
    private let accessoryStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    let accessoryContainer = UIView()
    var textInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    let placeholderInsets: UIEdgeInsets

    let accessoryTrailingInset: CGFloat

    convenience override init(frame: CGRect) {
        self.init(leftInset: 8)
    }

    /// Init with kind for keyboard style and validator type. Default is .unknown
    /// - Parameters:
    ///   - leftInset: placeholder left inset
    ///   - cornerRadius: optional corner radius override
    init(leftInset: CGFloat = 8,
         accessoryTrailingInset: CGFloat = 16,
         cornerRadius: CGFloat? = nil) {
        var topInset: CGFloat = 0
        if #available(iOS 11, *) {
            topInset = 0
        } else {
            /// Placeholder frame calculation is changed in iOS 11, therefore the TOP inset is not necessary
            topInset = 8
        }

        placeholderInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: 0, right: 16)

        self.accessoryTrailingInset = accessoryTrailingInset

        super.init(frame: .zero)
        self.setupTextFieldProperties()

        self.rightView = accessoryContainer
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

        if let cornerRadius = cornerRadius {
            layer.cornerRadius = cornerRadius
        }

        layer.masksToBounds = true
        backgroundColor = UIColor.Team.textfieldColor

        setup()
        setupTextFieldProperties()
        updateButtonIcon()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    private func setupTextFieldProperties() {
        returnKeyType = .next
        
        isSecureTextEntry = true
        accessibilityIdentifier = "PasswordField"
        autocapitalizationType = .none
        if #available(iOS 12, *) {
            textContentType = .password
        }
    }

    private var buttonIcon: StyleKitIcon {
        return overrideButtonIcon ?? (UIApplication.isLeftToRightLayout ? .forwardArrow : .backArrow)
    }

    private var iconSize: StyleKitIcon.Size {
        return .tiny
    }

    private func updateButtonIcon() {
       confirmButton.setIcon(buttonIcon, size: iconSize, for: .normal)
        
        confirmButton.tintColor = UIColor.Team.textColor
        confirmButton.setBackgroundImage(UIImage.singlePixelImage(with: .clear), for: state)
        
        confirmButton.adjustsImageWhenDisabled = false
    }

    private func setup() {
        accessoryStack.addArrangedSubview(confirmButton)

        confirmButton.addTarget(self, action: #selector(confirmButtonTapped(button:)), for: .touchUpInside)
        addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        accessoryStack.translatesAutoresizingMaskIntoConstraints = false
        accessoryContainer.addSubview(accessoryStack)

        NSLayoutConstraint.activate([
            // dimensions
            confirmButton.widthAnchor.constraint(equalToConstant: AccessoryTextField.ConfirmButtonWidth),
            confirmButton.heightAnchor.constraint(equalToConstant: AccessoryTextField.ConfirmButtonWidth),

            // spacing
            accessoryStack.topAnchor.constraint(equalTo: accessoryContainer.topAnchor),
            accessoryStack.bottomAnchor.constraint(equalTo: accessoryContainer.bottomAnchor),
            accessoryStack.leadingAnchor.constraint(equalTo: accessoryContainer.leadingAnchor, constant: 0),
            accessoryStack.trailingAnchor.constraint(equalTo: accessoryContainer.trailingAnchor, constant: -accessoryTrailingInset)])
    }

    // MARK: - custom edge insets

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let textRect = super.textRect(forBounds: bounds)

        return textRect.inset(by: textInsets.directionAwareInsets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let editingRect: CGRect = super.editingRect(forBounds: bounds)
        return editingRect.inset(by: textInsets.directionAwareInsets)
    }

    @objc
    func textFieldDidChange(textField: UITextField) {
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
        accessoryTextFieldDelegate?.buttonPressed(button)
        validateInput()
    }

    func validateInput() {
        updateConfirmButton()
    }

    // MARK: - placeholder

    func attributedPlaceholderString(placeholder: String) -> NSAttributedString {
        let attribute: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.Team.placeholderColor,
                                                        .font: AccessoryTextField.placeholderFont]
        return placeholder && attribute
    }

    override var placeholder: String? {
        set {
            if let newValue = newValue {
                attributedPlaceholder = attributedPlaceholderString(placeholder: newValue)
            }
        }
        get {
            return super.placeholder
        }
    }

    override func drawPlaceholder(in rect: CGRect) {
        super.drawPlaceholder(in: rect.inset(by: placeholderInsets.directionAwareInsets))
    }

    // MARK: - right and left accessory

    func rightAccessoryViewRect(forBounds bounds: CGRect, leftToRight: Bool) -> CGRect {
        let contentSize = accessoryContainer.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        var rightViewRect: CGRect
        let newY = bounds.origin.y + (bounds.size.height -  contentSize.height) / 2

        if leftToRight {
            rightViewRect = CGRect(x: CGFloat(bounds.maxX - contentSize.width), y: newY, width: contentSize.width, height: contentSize.height)
        } else {
            rightViewRect = CGRect(x: bounds.origin.x, y: newY, width: contentSize.width, height: contentSize.height)
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

extension UIButton {

    /// set icon to a new icon or no icon
    ///
    /// - Parameters:
    ///   - iconType: the StyleKitIcontype
    ///   - size: StyleKitIcon.Size
    ///   - state: UIControl state
    func setIcon(_ iconType: StyleKitIcon?,
                 size: StyleKitIcon.Size,
                 for state: UIControl.State) {
        guard let iconType = iconType else {
            setImage(nil, for: state)
            return
        }
        
        let image = UIImage.imageForIcon(iconType, size: size.rawValue, color: .black)
        let renderingMode: UIImage.RenderingMode = UIImage.RenderingMode.alwaysTemplate
        
        setImage(image.withRenderingMode(renderingMode), for: state)
    }
}
