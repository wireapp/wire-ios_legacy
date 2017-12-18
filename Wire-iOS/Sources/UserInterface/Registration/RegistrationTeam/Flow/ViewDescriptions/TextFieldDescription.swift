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

final class TextFieldDescription: NSObject, ValueSubmission {
    let placeholder: String
    let actionDescription: String
    let kind: AccessoryTextField.Kind
    var valueSubmitted: ValueSubmitted?
    var valueValidated: ValueValidated?
    var acceptsInput: Bool = true
    var validationError: TextFieldValidator.ValidationError

    fileprivate var currentValue: String = ""

    init(placeholder: String, actionDescription: String, kind: AccessoryTextField.Kind) {
        self.placeholder = placeholder
        self.actionDescription = actionDescription
        self.kind = kind
        validationError = .tooShort(kind: kind)
        super.init()
    }
}

extension TextFieldDescription: ViewDescriptor {
    func create() -> UIView {
        let textField = AccessoryTextField(kind: kind)
        textField.enablesReturnKeyAutomatically = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = self.placeholder
        textField.delegate = self
        textField.textFieldValidationDelegate = self
        textField.confirmButton.addTarget(self, action: #selector(TextFieldDescription.confirmButtonTapped(_:)), for: .touchUpInside)
        textField.confirmButton.accessibilityLabel = self.actionDescription
        return textField
    }
}

extension TextFieldDescription: UITextFieldDelegate {

    func confirmButtonTapped(_ sender: AnyObject) {
        submitValue(with: currentValue)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard acceptsInput else { return false }
        let oldValue = textField.text as NSString?
        let result = oldValue?.replacingCharacters(in: range, with: string)
        currentValue = (result as String?) ?? ""
        self.valueValidated?(.none)
        self.validationError = .none
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard acceptsInput else { return false }
        guard let text = textField.text else { return true }
        submitValue(with: text)
        return true
    }

    func submitValue(with text: String) {
        switch validationError {
        case .none:
            self.valueValidated?(.none)
            self.valueSubmitted?(text)
        default:
            self.valueValidated?(validationError)
        }
    }
}

extension TextFieldDescription: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError) {
        self.validationError = error
    }
}

