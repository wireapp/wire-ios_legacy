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
import WireCommonComponents

protocol SimpleTextFieldDelegate: AnyObject {
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

final class SimpleTextField: UITextField, DynamicTypeCapable {

    // MARK: - Properties
    var attribute: [NSAttributedString.Key: Any] = [.foregroundColor: SemanticColors.SearchBar.textInputViewPlaceholder,
                                                    .font: FontSpec.smallRegularFont.font!]
    enum Value {
        case valid(String)
        case error(SimpleTextFieldValidator.ValidationError)
    }

    fileprivate let textFieldValidator = SimpleTextFieldValidator()

    weak var textFieldDelegate: SimpleTextFieldDelegate?

    public var value: Value? {
        return text.value
    }

    // MARK: - UI constants

    static let enteredTextFont = FontSpec(.normal, .regular, .inputText)
    static let placeholderFont = FontSpec(.small, .regular)

    var textInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 8)
    var placeholderInsets: UIEdgeInsets

    // MARK: Initialization
    /// Init with kind for keyboard style and validator type. Default is .unknown
    ///
    /// - Parameter kind: the type of text field
    init() {
        let leftInset: CGFloat = 8

        let topInset: CGFloat = 0
        placeholderInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: 0, right: 16)

        super.init(frame: .zero)

        setupTextFieldProperties()

        tintColor = .accent()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods
    private func setupTextFieldProperties() {
        returnKeyType = .next
        autocapitalizationType = .words
        accessibilityIdentifier = "NameField"
        autocorrectionType = .no
        contentVerticalAlignment = .center
        font = ValidatedTextField.enteredTextFont.font
        delegate = textFieldValidator
        textFieldValidator.delegate = self

        keyboardAppearance = .default
        textColor = SemanticColors.SearchBar.textInputView
        backgroundColor = SemanticColors.SearchBar.backgroundInputView
    }

    // MARK: - Methods

    func redrawFont() {
        font = ValidatedTextField.enteredTextFont.font
        attribute[.font] = FontSpec.smallRegularFont.font
    }

    // MARK: - Override methods
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

        return placeholder && attribute
    }

    func updatePlaceholderAttributedText(attributes: [NSAttributedString.Key: Any]) {
        attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "", attributes: attributes)
    }

    override var placeholder: String? {
        get {
            return super.placeholder
        }

        set {
            if let newValue = newValue {
                attributedPlaceholder = attributedPlaceholderString(placeholder: newValue)
            }
        }
    }

    override func drawPlaceholder(in rect: CGRect) {
        super.drawPlaceholder(in: rect.inset(by: placeholderInsets))
    }
}

// MARK: SimpleTextField Extension
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
