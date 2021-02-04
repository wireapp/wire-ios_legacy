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
    func textFieldValueChanged(_ value: String?)
}

class AccessoryTextField: BaseAccessoryTextField {
    
    // MARK: - Constants
    
    private let revealButtonWidth: CGFloat = 32
    
    // MARK: - Properties
    
    weak var accessoryTextFieldDelegate: AccessoryTextFieldDelegate?
    
    var revealButtonIcon: StyleKitIcon? {
        didSet {
            updateButtonIcon()
        }
    }
    
    lazy var revealButton: UIButton = {
        let iconButton = UIButton()
        
        iconButton.tintColor = UIColor.Team.textColor
        iconButton.setBackgroundImage(UIImage.singlePixelImage(with: .clear), for: state)
        
        iconButton.adjustsImageWhenDisabled = false
        
        iconButton.accessibilityIdentifier = "passcode_text_field.button.reveal"
        iconButton.accessibilityLabel = "Reveal passcode".localized
        iconButton.isEnabled = true
        return iconButton
    }()
    
    // MARK: - Life cycle
    
    override init(leftInset: CGFloat,
                  accessoryTrailingInset: CGFloat,
                  textFieldAttributes: Attributes) {
        
        super.init(leftInset: leftInset,
                   accessoryTrailingInset: accessoryTrailingInset,
                   textFieldAttributes: textFieldAttributes)
        
        setupTextFieldProperties()
        setup()
    }
    
    private func setup() {
        accessoryStack.addArrangedSubview(revealButton)
        revealButton.addTarget(self, action: #selector(revealButtonTapped(button:)), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // dimensions
            revealButton.widthAnchor.constraint(equalToConstant: revealButtonWidth),
            revealButton.heightAnchor.constraint(equalToConstant: revealButtonWidth)
        ])
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
    
    @objc
    override func textFieldDidChange(textField: UITextField) {
        accessoryTextFieldDelegate?.textFieldValueChanged(input)
    }
    
    @objc
    private func revealButtonTapped(button: UIButton) {
        isSecureTextEntry = !isSecureTextEntry
        revealButtonIcon = isSecureTextEntry ? StyleKitIcon.AppLock.reveal : StyleKitIcon.AppLock.hide
    }
}

// MARK: - Private methods

extension AccessoryTextField {
    
    private func updateButtonIcon() {
        revealButton.setIcon(revealButtonIcon, size: .tiny, for: .normal)
    }
    
}

// MARK: - Helpers

extension AccessoryTextField {
    
    static func createPasscodeTextField(delegate: AccessoryTextFieldDelegate?) -> AccessoryTextField {
        let textFieldAttributes = BaseAccessoryTextField.Attributes(textFont: UIFont.systemFont(ofSize: 12),
                                                                    textColor: UIColor.Team.textColor,
                                                                    placeholderFont: UIFont.systemFont(ofSize: 12),
                                                                    placeholderColor: UIColor.Team.placeholderColor,
                                                                    backgroundColor: UIColor.Team.textfieldColor,
                                                                    cornerRadius: 4)
        
        let textField = AccessoryTextField(leftInset: 0,
                                           accessoryTrailingInset: 0,
                                           textFieldAttributes: textFieldAttributes)

        textField.revealButtonIcon = StyleKitIcon.AppLock.reveal
        textField.accessoryTextFieldDelegate = delegate

        textField.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.textFieldHeight).isActive = true

        return textField
    }
    
}
