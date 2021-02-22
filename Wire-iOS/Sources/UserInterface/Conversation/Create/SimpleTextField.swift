////
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

protocol SimpleTextFieldDelegate: class {
    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value)
    func textFieldReturnPressed(_ textField: SimpleTextField)
    func textFieldDidEndEditing(_ textField: SimpleTextField)
    func textFieldDidBeginEditing(_ textField: SimpleTextField)
}

extension Optional where Wrapped == String {
    var value: SimpleTextField.Value? {
        guard let value = self else { return nil }
        if let error = SimpleTextFieldValidator().validate(text: value) {
            return .error(error)
        }
        return .valid(value)
    }
}

final class SimpleTextField: UITextField, Themeable {

    var colorSchemeVariant: ColorSchemeVariant  = ColorScheme.default.variant {
        didSet {
            guard colorSchemeVariant != oldValue else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    enum Value {
        case valid(String)
        case error(SimpleTextFieldValidator.ValidationError)
    }

    fileprivate let textFieldValidator = SimpleTextFieldValidator()

    weak var textFieldDelegate: SimpleTextFieldDelegate?

    public var value: Value? {
        return text.value
    }

    // MARK:- UI constants

    static let enteredTextFont = FontSpec(.normal, .regular, .inputText).font!
    static let placeholderFont = FontSpec(.small, .regular).font!


    var textInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 8)
    var placeholderInsets: UIEdgeInsets

    /// Init with kind for keyboard style and validator type. Default is .unknown
    ///
    /// - Parameter kind: the type of text field
    init() {
        let leftInset: CGFloat = 8

        var topInset: CGFloat = 0
        if #available(iOS 11, *) {
            topInset = 0
        } else {
            /// Placeholder frame calculation is changed in iOS 11, therefore the TOP inset is not necessary
            topInset = 8
        }
        placeholderInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: 0, right: 16)

        super.init(frame: .zero)

        setupTextFieldProperties()
        applyColorScheme(colorSchemeVariant)

        tintColor = .accent()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTextFieldProperties() {
        returnKeyType = .next
        autocapitalizationType = .words
        accessibilityIdentifier = "NameField"
        autocorrectionType = .no
        contentVerticalAlignment = .center
        font = ValidatedTextField.enteredTextFont
        delegate = textFieldValidator
        textFieldValidator.delegate = self
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        keyboardAppearance = ColorScheme.keyboardAppearance(for: colorSchemeVariant)
        textColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        backgroundColor = UIColor.from(scheme: .barBackground, variant: colorSchemeVariant)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let textRect = super.textRect(forBounds: bounds)

        return textRect.inset(by: self.textInsets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let editingRect: CGRect = super.editingRect(forBounds: bounds)
        return editingRect.inset(by: textInsets)
    }

    // MARK: - Placeholder

    func attributedPlaceholderString(placeholder: String) -> NSAttributedString {
        let attribute: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.Team.placeholderColor,
                                        .font: ValidatedTextField.placeholderFont]
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
        super.drawPlaceholder(in: rect.inset(by: placeholderInsets))
    }
}

extension SimpleTextField: SimpleTextFieldValidatorDelegate {
    func textFieldValueChanged(_ value: String?) {
        textFieldDelegate?.textField(self, valueChanged: value.value ?? .error(.empty))
    }

    func textFieldValueSubmitted(_ value: String) {
        textFieldDelegate?.textFieldReturnPressed(self)
    }

    func textFieldDidEndEditing() {
        textFieldDelegate?.textFieldDidEndEditing(self)
    }

    func textFieldDidBeginEditing() {
        textFieldDelegate?.textFieldDidBeginEditing(self)
    }

}

