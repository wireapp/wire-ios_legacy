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
    func setValidationLabelsState(errorReason: PasscodeError, passed: Bool)
}

final class PasscodeSetupViewController: UIViewController {

    private lazy var presenter: PasscodeSetupPresenter = {
        return PasscodeSetupPresenter(userInterface: self)
    }()

    private let stackView: UIStackView = UIStackView.verticalStackView()

    private let contentView: UIView = UIView()

    private lazy var createButton: Button = {
        let button = Button(style: .full, titleLabelFont: .smallSemiboldFont)

        button.setTitle("create_passcode.create_button.title".localized(uppercased: true), for: .normal)
        button.isEnabled = false

        button.addTarget(self, action: #selector(onCreateCodeButtonPressed(sender:)), for: .touchUpInside)

        return button
    }()

    lazy var passcodeTextField: AccessoryTextField = {

        let textField = AccessoryTextField.createPasscodeTextField(kind: .passcode(isNew: true), delegate: self)
        textField.placeholder = "create_passcode.textfield.placeholder".localized

        return textField
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel.createMultiLineCenterdLabel(variant: variant)
        label.text = "create_passcode.title_label".localized

        return label
    }()

    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.configMultipleLineLabel()
        label.textAlignment = .center

        let textColor = UIColor.from(scheme: .textForeground, variant: variant)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 20
        paragraphStyle.maximumLineHeight = 20

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor]

        let headingText = NSAttributedString(string: "create_passcode.info_label".localized) && baseAttributes && UIFont.normalRegularFont

        let highlightText = NSAttributedString(string: "create_passcode.info_label.highlighted".localized) && baseAttributes && FontSpec(.normal, .bold).font!

        label.text = " "
        label.attributedText = headingText + highlightText

        return label
    }()

    private let validationLabels: [PasscodeError: UILabel] = {

        let myDictionary = PasscodeError.allCases.reduce([PasscodeError: UILabel]()) { (dict, errorReason) -> [PasscodeError: UILabel] in
            var dict = dict
            dict[errorReason] = UILabel()
            return dict
        }

        return myDictionary
    }()

    private var callback: ResultHandler?

    private let variant: ColorSchemeVariant

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(callback: ResultHandler?,
                  variant: ColorSchemeVariant? = nil) {
        self.callback = callback
        self.variant = variant ?? ColorScheme.default.variant

        super.init(nibName: nil, bundle: nil)

        setupViews()
    }

    private func setupViews() {
        view.backgroundColor = ColorScheme.default.color(named: .contentBackground,
                                                         variant: variant)

        view.addSubview(contentView)

        stackView.distribution = .fill

        contentView.addSubview(stackView)

        [titleLabel,
         SpacingView(10),
         infoLabel,
         UILabel.createHintLabel(variant: variant),
         passcodeTextField,
         SpacingView(16)].forEach {
            stackView.addArrangedSubview($0)
        }

        PasscodeError.allCases.forEach {
            if let label = validationLabels[$0] {
                label.font = UIFont.smallSemiboldFont
                label.textColor = UIColor.from(scheme: .textForeground, variant: self.variant)
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

        let widthConstraint = contentView.createContentWidthConstraint()

        let contentPadding: CGFloat = 24

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
            passcodeTextField.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            passcodeTextField.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            // create Button
            createButton.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.buttonHeight),
            createButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            createButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
    }

    @objc
    func onCreateCodeButtonPressed(sender: AnyObject?) {
        guard let passcode = passcodeTextField.text else { return }
        presenter.storePasscode(passcode: passcode)
        dismiss(animated: true)
        callback?(true)
    }

}

// MARK: - AccessoryTextFieldDelegate

extension PasscodeSetupViewController: AccessoryTextFieldDelegate {
    func buttonPressed(_ sender: UIButton) {
        passcodeTextField.isSecureTextEntry = !passcodeTextField.isSecureTextEntry

        passcodeTextField.updatePasscodeIcon()
    }
}

// MARK: - TextFieldValidationDelegate

extension PasscodeSetupViewController: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        presenter.validate(error: error)
    }
}

// MARK: - PasscodeSetupUserInterface

extension PasscodeSetupViewController: PasscodeSetupUserInterface {
    func setValidationLabelsState(errorReason: PasscodeError, passed: Bool) {
        validationLabels[errorReason]?.attributedText = passed ? errorReason.descriptionWithPassedIcon : errorReason.descriptionWithInvalidIcon
    }

    var createButtonEnabled: Bool {
        get {
            return createButton.isEnabled
        }

        set {
            createButton.isEnabled = newValue
        }
    }
}
