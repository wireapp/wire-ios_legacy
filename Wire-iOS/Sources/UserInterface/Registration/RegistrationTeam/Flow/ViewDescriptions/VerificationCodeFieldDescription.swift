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
    var valueValidated: ValueValidated?
    var acceptsInput: Bool = true
    var constraints: [NSLayoutConstraint] = []
}

fileprivate final class ResponderContainer: UIView {
    private let responder: UIView
    
    init(responder: UIView) {
        self.responder = responder
        super.init(frame: .zero)
        self.addSubview(self.responder)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var canBecomeFirstResponder: Bool {
        return self.responder.canBecomeFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        return self.responder.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return self.responder.resignFirstResponder()
    }
}

extension VerificationCodeFieldDescription: ViewDescriptor {
    func create() -> UIView {

        /// get the with from keyWindow for iPad non full screen modes.
        let width = UIApplication.shared.keyWindow?.frame.width ?? UIScreen.main.bounds.size.width
        let size = CGSize(width: width, height: TeamCreationStepController.mainViewHeight)

        let inputField = CharacterInputField(maxLength: 6, characterSet: .decimalDigits, size: size)
        inputField.keyboardType = .decimalPad
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.delegate = self
        inputField.accessibilityIdentifier = "VerificationCode"
        inputField.accessibilityLabel = "team.email_code.input_field.accessbility_label".localized

        let containerView = ResponderContainer(responder: inputField)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
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

    func shouldAcceptChanges(_ inputField: CharacterInputField) -> Bool {
        return acceptsInput
    }

    func didChangeText(_ inputField: CharacterInputField, to: String) {
        self.valueValidated?(.none)
    }

    func didFillInput(inputField: CharacterInputField) {
        self.valueSubmitted?(inputField.text)
    }
}
