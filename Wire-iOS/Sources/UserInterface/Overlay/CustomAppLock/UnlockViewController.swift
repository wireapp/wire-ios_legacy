
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


// This VC should be wrapped in KeyboardAvoidingViewController as the "unlock" button would be covered on 4 inch iPhone
final class UnlockViewController: UIViewController, AccessoryTextFieldDelegate, TextFieldValidationDelegate {
    
    final class UnlockViewModel {
        
    }
    
    private let viewModel: UnlockViewModel = UnlockViewModel()
    
    private let shieldView = UIView.shieldView()
    private let blurView: UIVisualEffectView = UIVisualEffectView.blurView()
    
    private let stackView: UIStackView = UIStackView.verticalStackView()
    
    private let contentView: UIView = { let view = UIView()
        return view
    }()
    
    private let unlockButton: Button = {
        let button = Button(style: .fullMonochrome)
        
        button.setTitle("unlock".localized, for: .normal)
        button.isEnabled = false
        
        ///TODO: lazy add target
        return button
    }()
    
    //TODO: mv to style file
    private let revealIcon: StyleKitIcon = .cross //TODO: add eye with splash
    
    private lazy var accessoryTextField: AccessoryTextField = {
        let textField = AccessoryTextField(kind: .passcode,
                                           leftInset: 0,
                                           cornerRadius: 4)
        textField.placeholder = "Enter your passcode".localized //TODO:
        
        textField.overrideButtonIcon = revealIcon
        textField.accessoryTextFieldDelegate = self
        textField.textFieldValidationDelegate = self
        
        textField.heightAnchor.constraint(equalToConstant: 40).isActive = true ///TODO: constant file

        return textField
    }()
    
    private let titleLabel: UILabel = {
        //TODO: copy
        let label = UILabel(key: "Enter Passcode to unlock Wire".localized, size: FontSize.large, weight: .semibold, color: .textForeground, variant: .dark)
        
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        
        return label
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "123"
        label.font = FontSpec(.small, .regular).font
        label.textColor = .red ///TODO: get form spec

//        "Incorrect passcode".localized
        return label
    }()
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
        
        [shieldView, blurView, contentView].forEach() {
            view.addSubview($0)
        }
        
        stackView.distribution = .fillProportionally
        
        contentView.addSubview(stackView)
        

        let hintLabel = UILabel()
        hintLabel.text = "Passcode".localized
        hintLabel.font = UIFont.smallRegularFont.withSize(10) ///TODO: dynamic?
        hintLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        

        ///TODO: keep a var, link
        let linkLabel = UILabel(key: "Forgot passcode?".localized, size: .medium, weight: .medium, color: .textForeground, variant: .dark)
        linkLabel.textAlignment = .center
        linkLabel.numberOfLines = 1

        [titleLabel,
         hintLabel,
         accessoryTextField,
         errorLabel,
         linkLabel,
         SpacingView(25),
         unlockButton].forEach() {
            stackView.addArrangedSubview($0)
        }

        createConstraints()
    }
    
    //MARK: - status bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        accessoryTextField.becomeFirstResponder()
    }
    
    private func createConstraints(/*nibView: UIView*/) {
        
        [shieldView,
         blurView,
         contentView,
         stackView].disableAutoresizingMaskTranslation()
        
        let widthConstraint = contentView.widthAnchor.constraint(equalToConstant: 375)
        widthConstraint.priority = .defaultHigh
        
        let contentPadding: CGFloat = 24
        let textFieldPadding: CGFloat = 19

        NSLayoutConstraint.activate([
            // nibView
            shieldView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shieldView.topAnchor.constraint(equalTo: view.topAnchor),
            shieldView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shieldView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // blurView
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
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
            
            accessoryTextField.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: textFieldPadding),
            accessoryTextField.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -textFieldPadding),

            // authenticateButton
            unlockButton.heightAnchor.constraint(equalToConstant: 40),
            unlockButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            unlockButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor), 
        ])
    }
    
    // MARK: - AccessoryTextFieldDelegate
    
    func buttonPressed(_ sender: UIButton) {
        accessoryTextField.isSecureTextEntry = !accessoryTextField.isSecureTextEntry
        
        accessoryTextField.overrideButtonIcon = accessoryTextField.isSecureTextEntry ? revealIcon : .eye ///TODO: mv to style file
    }
    
    //MARK: - TextFieldValidationDelegate
    
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        unlockButton.isEnabled = error == nil
    }
}
