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

extension PasscodeSetupViewController: AuthenticationCoordinatedViewController {
    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        //no-op
    }

    func displayError(_ error: Error) {
        //no-op
    }
}

final class PasscodeSetupViewController: UIViewController {

    weak var passcodeSetupViewControllerDelegate: PasscodeSetupViewControllerDelegate?

    // MARK: AuthenticationCoordinatedViewController
    weak var authenticationCoordinator: AuthenticationCoordinator?

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
        textField.delegate = self

        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        return textField
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel.createMultiLineCenterdLabel(variant: variant)
        label.text = "create_passcode.title_label".localized

        return label
    }()

    private let useCompactLayout: Bool

    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.configMultipleLineLabel()
        label.textAlignment = .center

        let textColor = UIColor.from(scheme: .textForeground, variant: variant)

        let regularFont: UIFont
        let heightFont: UIFont
        let lineHeight: CGFloat

        if useCompactLayout {
            regularFont = FontSpec(.small, .regular).font!
            heightFont = FontSpec(.small, .bold).font!
            lineHeight = 14
        } else {
            regularFont = UIFont.normalRegularFont
            heightFont = FontSpec(.normal, .bold).font!
            lineHeight = 20
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor]

        let headingText = NSAttributedString(string: "create_passcode.info_label".localized) && baseAttributes && regularFont

        let highlightText = NSAttributedString(string: "create_passcode.info_label.highlighted".localized) && baseAttributes && heightFont

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

    /// init with parameters
    /// - Parameters:
    ///   - callback: callback for storing passcode result.
    ///   - variant: color variant for this screen. When it is nil, apply app's current scheme
    ///   - useCompactLayout: Set this to true for reduce font size and spacing for iPhone 4 inch screen. Set to nil to follow current window's height
    required init(callback: ResultHandler?,
                  variant: ColorSchemeVariant? = nil,
                  useCompactLayout: Bool? = nil) {
        self.callback = callback
        self.variant = variant ?? ColorScheme.default.variant

        self.useCompactLayout = useCompactLayout ??
                                (AppDelegate.shared.window!.frame.height <= CGFloat.iPhone4Inch.height)

        super.init(nibName: nil, bundle: nil)

        setupViews()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupViews() {
        view.backgroundColor = ColorScheme.default.color(named: .contentBackground,
                                                         variant: variant)

        view.addSubview(contentView)

        stackView.distribution = .fill

        contentView.addSubview(stackView)

        [titleLabel,
         SpacingView(useCompactLayout ? 1 : 10),
         infoLabel,
         UILabel.createHintLabel(variant: variant),
         passcodeTextField,
         SpacingView(useCompactLayout ? 2 : 16)].forEach {
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

    private func storePasscode() {
        guard let passcode = passcodeTextField.text else { return }
        presenter.storePasscode(passcode: passcode, callback: callback)

        authenticationCoordinator?.passcodeSetupControllerDidFinish(self)
        dismiss(animated: true)
    }

    @objc
    private func textFieldDidChange(textField: UITextField) {
        passcodeTextField.returnKeyType = presenter.isPasscodeValid ? .done : .default
        passcodeTextField.reloadInputViews()
    }

    @objc
    private func onCreateCodeButtonPressed(sender: AnyObject?) {
        storePasscode()
    }

    // MARK: - keyboard avoiding

    static func createKeyboardAvoidingFullScreenView(callback: ResultHandler?,
                                                     variant: ColorSchemeVariant? = nil) -> KeyboardAvoidingAuthenticationCoordinatedViewController {
        let passcodeSetupViewController = PasscodeSetupViewController(callback: callback,
                                                                      variant: variant)

        let keyboardAvoidingViewController = KeyboardAvoidingAuthenticationCoordinatedViewController(viewController: passcodeSetupViewController)

        keyboardAvoidingViewController.modalPresentationStyle = .fullScreen

        return keyboardAvoidingViewController
    }

    // MARK: - close button

    lazy var closeItem: UIBarButtonItem = {
        let closeItem = UIBarButtonItem.createCloseItem()
        closeItem.tintColor = .white

        closeItem.target = self
        closeItem.action = #selector(PasscodeSetupViewController.closeTapped)

        return closeItem
    }()

    @objc
    private func closeTapped() {
        dismiss(animated: true)

        appLockSetupViewControllerDismissed()
    }

    private func appLockSetupViewControllerDismissed() {
        callback?(false)

        passcodeSetupViewControllerDelegate?.passcodeSetupControllerWasDismissed(self)
    }
}

// MARK: - UITextFieldDelegate

extension PasscodeSetupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard presenter.isPasscodeValid else {
            return false
        }

        storePasscode()
        return true
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

// MARK: - UIAdaptivePresentationControllerDelegate
extension PasscodeSetupViewController: UIAdaptivePresentationControllerDelegate {
    @available(iOS 13.0, *)
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        appLockSetupViewControllerDismissed()
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // more space for iPhone 4-inch to prevent keyboard hides the create passcode button
        if view.frame.size.height <= CGFloat.iPhone4Inch.height {
            return .fullScreen
        } else {
            if #available(iOS 13.0, *) {
                return .automatic
            } else {
                return .none
            }
        }
    }

}
