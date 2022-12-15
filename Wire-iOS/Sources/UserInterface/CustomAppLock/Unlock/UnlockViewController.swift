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
import WireDataModel
import WireSyncEngine

protocol UnlockViewControllerDelegate: AnyObject {

    func unlockViewControllerDidUnlock()

}

/// UnlockViewController
/// 
/// This VC should be wrapped in KeyboardAvoidingViewController as the "unlock" button would be covered on 4 inch iPhone
final class UnlockViewController: UIViewController {

    typealias Session = ZMUserSessionInterface & UserSessionAppLockInterface
    typealias Unlock = L10n.Localizable.Unlock

    weak var delegate: UnlockViewControllerDelegate?

    private let selfUser: UserType
    private var userSession: Session?

    private let stackView: UIStackView = UIStackView.verticalStackView()
    private let upperStackView = UIStackView.verticalStackView()

    private let contentView: UIView = UIView()

    private static let errorFont = FontSpec.smallLightFont.font!

    private lazy var unlockButton: Button = {
        let button = Button(style: .primaryTextButtonStyle, cornerRadius: 16, fontSpec: .mediumSemiboldFont)

        button.setTitle(Unlock.SubmitButton.title, for: .normal)
        button.isEnabled = false
        button.addTarget(self, action: #selector(onUnlockButtonPressed(sender:)), for: .touchUpInside)
        button.accessibilityIdentifier = "unlock_screen.button.unlock"

        return button
    }()

    lazy var validatedTextField: ValidatedTextField = {
        let textField = ValidatedTextField.createPasscodeTextField(kind: .passcode(isNew: false), delegate: self, setNewColors: true)
        textField.placeholder = Unlock.Textfield.placeholder
        textField.delegate = self
        textField.accessibilityIdentifier = "unlock_screen.text_field.enter_passcode"

        return textField
    }()

    private let titleLabel: UILabel = {
        let label = DynamicFontLabel(text: Unlock.titleLabel,
                                     fontSpec: .largeSemiboldFont,
                                     color: SemanticColors.Label.textDefault)

        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    private lazy var accountIndicator: UIView = {
        let view = UIView()
        view.addSubview(userImageView)
        view.addSubview(nameLabel)
        return view
    }()

    private lazy var userImageView: UIView = {
        let imageView = UserImageView(size: .small)
        imageView.user = selfUser
        imageView.userSession = userSession
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = DynamicFontLabel(fontSpec: .mediumRegularFont,
                                     color: SemanticColors.Label.textDefault)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.text = selfUser.name ?? ""
        return label
    }()

    private let errorLabel: UILabel = {
        let label = DynamicFontLabel(fontSpec: .smallLightFont,
                                     color: SemanticColors.Label.textErrorDefault)
        label.text = " "

        return label
    }()

    private lazy var wipeButton: Button = {
        let button = Button(style: .secondaryTextButtonStyle, cornerRadius: 16, fontSpec: .mediumRegularFont)

        button.setTitle(Unlock.wipeButton, for: .normal)

        button.addTarget(self, action: #selector(onWipeButtonPressed(sender:)), for: .touchUpInside)

        return button
    }()

    init(selfUser: UserType, userSession: Session? = nil) {
        self.selfUser = selfUser
        self.userSession = userSession

        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = SemanticColors.View.backgroundDefault

        [contentView].forEach {
            view.addSubview($0)
        }

        stackView.distribution = .fill

        // stackview for horizonal spacing except unlockButton
        upperStackView.distribution = .fillProportionally

        contentView.addSubview(stackView)

        [accountIndicator,
         titleLabel,
         UILabel.createHintLabel(),
         validatedTextField,
         errorLabel,
         wipeButton].forEach(upperStackView.addArrangedSubview)

        [upperStackView, unlockButton].forEach(stackView.addArrangedSubview)

        createConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        validatedTextField.becomeFirstResponder()
    }

    private func createConstraints() {

        [userImageView,
         nameLabel,
         contentView,
         upperStackView,
         stackView].prepareForLayout()

        let widthConstraint = contentView.createContentWidthConstraint()

        let contentPadding: CGFloat = 24

        NSLayoutConstraint.activate([
            // content view
            widthConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: CGFloat.iPhone4_7Inch.width),
            contentView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: contentPadding),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -contentPadding),

            // stack view
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // unlock Button
            unlockButton.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.buttonHeight),

            // account indicator
            userImageView.topAnchor.constraint(equalTo: accountIndicator.topAnchor),
            userImageView.centerXAnchor.constraint(equalTo: accountIndicator.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: userImageView.bottomAnchor, constant: 11),
            nameLabel.centerXAnchor.constraint(equalTo: accountIndicator.centerXAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: accountIndicator.bottomAnchor)
        ])
    }

    @objc
    private func onWipeButtonPressed(sender: AnyObject?) {
        let wipeDatabaseViewController = WipeDatabaseWireframe().createWipeDatabaseModule()
        navigationController?.pushViewController(wipeDatabaseViewController, animated: true)
    }

    @discardableResult
    private func unlock() -> Bool {
        guard
            let passcode = validatedTextField.text,
            let session = userSession,
            session.appLockController.evaluateAuthentication(customPasscode: passcode) == .granted
        else {
            return false
        }

        delegate?.unlockViewControllerDidUnlock()
        return true
    }

    @objc
    private func onUnlockButtonPressed(sender: AnyObject?) {
        unlock()
    }

    func showWrongPasscodeMessage() {

        let textAttachment = NSTextAttachment.textAttachment(for: .exclamationMarkCircle,
                                                             with: SemanticColors.Label.textErrorDefault,
                                                             iconSize: StyleKitIcon.Size.CreatePasscode.errorIconSize,
                                                             verticalCorrection: -1,
                                                             insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4))

        let attributedString = NSAttributedString(string: Unlock.errorLabel) && UnlockViewController.errorFont

        errorLabel.attributedText = NSAttributedString(attachment: textAttachment) + attributedString
        unlockButton.isEnabled = false
    }
}

// MARK: - ValidatedTextFieldDelegate

extension UnlockViewController: ValidatedTextFieldDelegate {
    func buttonPressed(_ sender: UIButton) {
        validatedTextField.isSecureTextEntry = !validatedTextField.isSecureTextEntry

        validatedTextField.updatePasscodeIcon()
    }
}

// MARK: - TextFieldValidationDelegate

extension UnlockViewController: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        unlockButton.isEnabled = error == nil
        errorLabel.text = " "
    }
}

// MARK: - UITextFieldDelegate

extension UnlockViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return unlock()
    }
}
