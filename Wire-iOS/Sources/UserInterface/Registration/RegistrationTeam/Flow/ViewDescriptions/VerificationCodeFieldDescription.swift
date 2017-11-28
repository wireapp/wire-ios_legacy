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

final class VerificationCodeFieldDescription: NSObject, ValueSubmission {
    var valueSubmitted: ValueSubmitted?
    var constraints: [NSLayoutConstraint] = []
}

extension VerificationCodeFieldDescription: ViewDescriptor {
    func create() -> UIView {
        let containerView = UIView()

        containerView.translatesAutoresizingMaskIntoConstraints = false
        let inputField = CharacterInputField(maxLength: 6, characterSet: .decimalDigits)
        inputField.keyboardType = .decimalPad
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.delegate = self
        inputField.accessibilityIdentifier = "VerificationCode"
        inputField.accessibilityLabel = "team.email_code.input_field.accessbility_label".localized
        containerView.addSubview(inputField)

        inputField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        inputField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        inputField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true

        return containerView
    }

    func constrainsToActivate() -> [NSLayoutConstraint] {
        return constraints
    }
}

extension VerificationCodeFieldDescription: CharacterInputFieldDelegate {
    func didChangeText(_ inputField: CharacterInputField, to: String) {

    }

    func didFillInput(inputField: CharacterInputField) {
        self.valueSubmitted?(inputField.text)
    }
}
