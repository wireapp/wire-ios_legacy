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

    fileprivate var currentValue: String = ""

    init(placeholder: String, actionDescription: String, kind: AccessoryTextField.Kind) {
        self.placeholder = placeholder
        self.actionDescription = actionDescription
        self.kind = kind
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
        self.valueSubmitted?(currentValue)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldValue = textField.text as NSString?
        let result = oldValue?.replacingCharacters(in: range, with: string)
        currentValue = (result as String?) ?? ""
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true }
        self.valueSubmitted?(text)
        return true
    }
}

extension TextFieldDescription: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError) {
        ///
    }
}

