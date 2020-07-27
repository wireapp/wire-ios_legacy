
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

protocol PasscodeSetupUserInterface: class {
    var createButtonEnabled: Bool { get set }
}

///TODO: move to VM
enum ErrorReason: CaseIterable {
    case tooShort
    case noLowercaseChar
    case noUppercaseChar
    case noNumber
    case noSpecialChar
    
    var message: String {
        switch self {
            
        case .tooShort:
            return "create_passcode.validation.too_short".localized
        case .noLowercaseChar:
            return "create_passcode.validation.no_lowercase_char".localized
        case .noUppercaseChar:
            return "create_passcode.validation.no_uppercase_char".localized
        case .noSpecialChar:
            return "create_passcode.validation.no_special_char".localized
        case .noNumber:
            return "create_passcode.validation.no_number".localized
        }
    }
    
    var descriptionWithInvalidIcon: NSAttributedString {
        
        //TODO paint code icon
        let attributedString = NSAttributedString(string: "❌" + message)
        
        return attributedString
    }
    
    //TODO paint code icon
    var descriptionWithPassedIcon: NSAttributedString {
        
        let attributedString: NSAttributedString = NSAttributedString(string: "✅" + message)
        
        return attributedString
    }
}

final class PasscodeSetupViewController: UIViewController {
    
    private lazy var presenter: PasscodeSetupPresenter = {
        return PasscodeSetupPresenter(userInterface: self)
    }()

    private let stackView: UIStackView = UIStackView.verticalStackView()
    
    private let contentView: UIView = UIView()
    
    private lazy var createButton: Button = {
        let button = Button(style: .full)
        
        button.setTitle("create_passcode.create_button.title".localized(uppercased: true), for: .normal)
        button.isEnabled = false
        
        button.addTarget(self, action: #selector(onCreateCodeButtonPressed(sender:)), for: .touchUpInside)
        
        return button
    }()
    
    ///TODO: factory method
    lazy var passcodeTextField: AccessoryTextField = {
        let textField = AccessoryTextField(kind: .passcode,
                                           leftInset: 0,
                                           accessoryTrailingInset: 0,
                                           cornerRadius: 4)
        textField.placeholder = "create_passcode.textfield.placeholder".localized
        
        textField.overrideButtonIcon = StyleKitIcon.AppLock.reveal
        textField.accessoryTextFieldDelegate = self
        textField.textFieldValidationDelegate = self
        
        textField.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.textFieldHeight).isActive = true
        
        return textField
    }()

    private let titleLabel: UILabel = {
        let label = UILabel.createTitleLabel()
        label.text = "create_passcode.title_label".localized
        
        return label
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.configMultipleLineLabel()
        label.textAlignment = .center

        let textColor = UIColor.from(scheme: .textForeground)
        
        let headingText =  NSAttributedString(string: "create_passcode.info_label".localized) && UIFont.normalRegularFont && textColor
        let highlightText = NSAttributedString(string: "create_passcode.info_label.highlighted".localized) && FontSpec(.normal, .bold).font!  && textColor
        
        label.text = " "
        label.attributedText = headingText + highlightText
        
        return label
    }()
    
    private let validationLabels: [ErrorReason:UILabel] = {
        
        let myDictionary = ErrorReason.allCases.reduce([ErrorReason: UILabel]()) { (dict, errorReason) -> [ErrorReason: UILabel] in
            var dict = dict
            dict[errorReason] = UILabel()
            return dict
        }
        
        return myDictionary
    }()


    convenience init() {
        self.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = ColorScheme.default.color(named: .contentBackground)
        
        [contentView].forEach {
            view.addSubview($0)
        }
        
        stackView.distribution = .fill
        
        contentView.addSubview(stackView)
        
        [titleLabel,
         SpacingView(24),
         infoLabel,
         passcodeTextField,
         SpacingView(16)].forEach {
            stackView.addArrangedSubview($0)
        }
        
        ErrorReason.allCases.forEach() {
            if let label = validationLabels[$0] {
                label.font = UIFont.smallRegularFont
                label.textColor = UIColor.Team.subtitleColor
                label.numberOfLines = 0
                
                label.attributedText = $0.descriptionWithInvalidIcon
                stackView.addArrangedSubview(label)
            }
        }

        stackView.addArrangedSubview(createButton)

        
        createConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        passcodeTextField.becomeFirstResponder()
    }
    
    private func createConstraints() {
        
        [contentView,
         stackView].disableAutoresizingMaskTranslation()

        //TODO: factory
        let widthConstraint = contentView.widthAnchor.constraint(equalToConstant: 375)
        widthConstraint.priority = .defaultHigh
        
        let contentPadding: CGFloat = 24
        let textFieldPadding: CGFloat = 19
        
        NSLayoutConstraint.activate([
            // content view
            widthConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 375),
            contentView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: contentPadding),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -contentPadding),
            
            // stack view
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // passcode text field
            passcodeTextField.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: textFieldPadding),
            passcodeTextField.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -textFieldPadding),
            
            // create Button
            createButton.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.buttonHeight),
            createButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            createButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
    }

    @objc
    func onCreateCodeButtonPressed(sender: AnyObject?) {
        //TODO
        
    }

}

// MARK: - AccessoryTextFieldDelegate

///TODO share with Unlock VC
extension PasscodeSetupViewController: AccessoryTextFieldDelegate {
    func buttonPressed(_ sender: UIButton) {
        passcodeTextField.isSecureTextEntry = !passcodeTextField.isSecureTextEntry
        
        passcodeTextField.overrideButtonIcon = passcodeTextField.isSecureTextEntry ? StyleKitIcon.AppLock.reveal : .eye ///TODO: mv to style file
    }
}

// MARK: - TextFieldValidationDelegate

// TODO: mv to VM
extension PasscodeSetupViewController: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        presenter.validate(error: error)
        createButton.isEnabled = error == nil
    }
}

extension PasscodeSetupViewController: PasscodeSetupUserInterface {
    var createButtonEnabled: Bool {
        get {
            return createButton.isEnabled
        }
        
        set {
            createButton.isEnabled = newValue
        }
    }
}
