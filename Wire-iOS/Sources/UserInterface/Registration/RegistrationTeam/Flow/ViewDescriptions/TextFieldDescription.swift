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
    var placeholder: String
    var valueSubmitted: ValueSubmitted?

    init(placeholder: String) {
        self.placeholder = placeholder
        super.init()
    }
}

extension TextFieldDescription: ViewDescriptor {
    func create() -> UIView {
        let textField = UITextField()
        textField.enablesReturnKeyAutomatically = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = self.placeholder
        textField.delegate = self
        return textField
    }
}

extension TextFieldDescription: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true }
        self.valueSubmitted?(text)
        return true
    }
}
