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
import WireDataModel
import WireCommonComponents

final class UnlockViewController: UIViewController {

    typealias Callback = (_ passcode: String?) -> Void

    // MARK: - Properties

    var callback: Callback?

    private let contentView: UIView = UIView()
    private let stackView: UIStackView = UIStackView.verticalStackView()

    private lazy var unlockButton: UIButton = {
        var button = UIButton()

        button.setBackgroundImage(UIImage.singlePixelImage(with: .white), for: .normal)
        button.setTitleColor(.graphite, for: .normal)
        button.setTitleColor(.lightGraphite, for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)

        button.setTitle("share_extension.unlock.submit_button.title".localized(uppercased: true), for: .normal)
        button.isEnabled = false

        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true

        button.addTarget(self, action: #selector(onUnlockButtonPressed(sender:)), for: .touchUpInside)
        button.accessibilityIdentifier = "unlock_screen.button.unlock"

        return button
    }()

    private lazy var passcodeTextField: PasscodeTextField = {
        let textField = PasscodeTextField.createPasscodeTextField(delegate: self)
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none

        textField.placeholder = "share_extension.unlock.textfield.placeholder".localized
        textField.accessibilityIdentifier = "unlock_screen.text_field.enter_passcode"

        return textField
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()

        label.text = "share_extension.unlock.title_label".localized
        label.accessibilityIdentifier = "unlock_screen.title.enter_passcode"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .white

        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    private let hintFont = UIFont.systemFont(ofSize: 10)
    private let hintLabel: UILabel = {
        let label = UILabel()

        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .white

        let leadingMargin: CGFloat = 16
        let style = NSMutableParagraphStyle()
        style.firstLineHeadIndent = leadingMargin
        style.headIndent = leadingMargin

        label.attributedText = NSAttributedString(string: "share_extension.unlock.hint_label".localized,
                                                  attributes: [NSAttributedString.Key.paragraphStyle: style])
        return label
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = " "
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.PasscodeUnlock.error

        return label
    }()

    // MARK: - Life cycle

    init() {
        super.init(nibName: nil, bundle: nil)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupInitialStates()
    }
}

// MARK: - View creation

extension UnlockViewController {

    private func setupViews() {
        view.backgroundColor = .black

        view.addSubview(contentView)

        stackView.distribution = .fill
        contentView.addSubview(stackView)

        [titleLabel,
         hintLabel,
         passcodeTextField,
         errorLabel,
         unlockButton].forEach(stackView.addArrangedSubview)

        createConstraints()
    }

    private func createConstraints() {
        [contentView,
         stackView].forEach { (view) in
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        let widthConstraint = contentView.createContentWidthConstraint()

        let contentPadding: CGFloat = 24

        NSLayoutConstraint.activate([
            // content view
            widthConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: CGFloat.iPhone4_7Inch.width),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: contentPadding),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -contentPadding),

            // stack view
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // unlock button
            unlockButton.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.buttonHeight)
        ])
    }

    private func setupInitialStates() {
        errorLabel.text = " "
        passcodeTextField.text = ""
        unlockButton.isEnabled = false
        passcodeTextField.becomeFirstResponder()
    }

}

// MARK: - Actions

extension UnlockViewController {

    @objc
    private func onUnlockButtonPressed(sender: AnyObject?) {
        unlock()
    }

    private func unlock() {
        guard let passcode = passcodeTextField.text else { return }
        callback?(passcode)
    }

    func showWrongPasscodeMessage() {
        let textAttachment = NSTextAttachment.textAttachment(for: .exclamationMarkCircle, with: UIColor.PasscodeUnlock.error, iconSize: StyleKitIcon.Size.CreatePasscode.errorIconSize, verticalCorrection: -1, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4))

        let attributedString = NSAttributedString(string: "share_extension.unlock.error_label".localized) && hintFont

        errorLabel.attributedText = NSAttributedString(attachment: textAttachment) + attributedString
        unlockButton.isEnabled = false
    }

}

// MARK: - PasscodeTextFieldDelegate

extension UnlockViewController: PasscodeTextFieldDelegate {

    func textFieldValueChanged(_ value: String?) {
        errorLabel.text = " "
        if let isEmpty = value?.isEmpty {
            unlockButton.isEnabled = !isEmpty
        } else {
            unlockButton.isEnabled = false
        }
    }

}
