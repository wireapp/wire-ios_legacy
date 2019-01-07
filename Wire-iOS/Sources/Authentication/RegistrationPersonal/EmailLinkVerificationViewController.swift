//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import UIKit

class EmailLinkVerificationViewController: UIViewController, AuthenticationCoordinatedViewController {

    weak var authenticationCoordinator: AuthenticationCoordinator?

    // MARK: - Initialization

    /// The e-mail address that the user is registering
    private let emailAddress: String

    init(credentials: ZMEmailCredentials) {
        self.emailAddress = credentials.email!
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Elements

    private let mailIconView = UIImageView()
    private let instructionsLabel = UILabel()
    private let resendInstructionsLabel = UILabel()
    private let resendButton = IconButton()
    private let resendContainer = UIStackView()
    private let container = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configureConstraints()
    }

    // MARK: - Interface Configuration

    private func configureSubviews() {
        mailIconView.image = UIImage(for: .envelope, iconSize: .large, color: .white)
        mailIconView.contentMode = .center
        mailIconView.translatesAutoresizingMaskIntoConstraints = false

        instructionsLabel.numberOfLines = 0
        instructionsLabel.textAlignment = .center
        instructionsLabel.font = .normalLightFont
        instructionsLabel.textColor = .white
        instructionsLabel.attributedText = makeAttributedInstructionsText()
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false

        resendInstructionsLabel.numberOfLines = 0
        resendInstructionsLabel.textAlignment = .center
        resendInstructionsLabel.font = .normalLightFont
        resendInstructionsLabel.textColor = UIColor.from(scheme: .buttonFaded, variant: .dark)
        resendInstructionsLabel.text = "registration.verify_email.resend.instructions".localized
        resendInstructionsLabel.translatesAutoresizingMaskIntoConstraints = false

        resendButton.setTitleColor(.white, for: .normal)
        resendButton.setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .highlighted)
        resendButton.setTitle("registration.verify_email.resend.button_title".localized, for: .normal)
        resendButton.addTarget(self, action: #selector(resendButtonTapped), for: .touchUpInside)

        resendContainer.alignment = .fill
        resendContainer.distribution = .fill
        resendContainer.axis = .vertical
        resendContainer.spacing = 8

        resendContainer.addArrangedSubview(resendInstructionsLabel)
        resendContainer.addArrangedSubview(resendButton)

        container.translatesAutoresizingMaskIntoConstraints = false
        container.alignment = .fill
        container.distribution = .fill
        container.axis = .vertical
        container.spacing = 32

        container.addArrangedSubview(mailIconView)
        container.addArrangedSubview(instructionsLabel)
        container.addArrangedSubview(resendContainer)
        view.addSubview(container)
    }

    private func configureConstraints() {
        let offset: CGFloat = 28

        let constraints = [
            // Container
            container.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: offset),
            container.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -offset),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func makeAttributedInstructionsText() -> NSAttributedString {
        let instructions = String(format: "registration.verify_email.instructions".localized, emailAddress)
        let attributedText = NSMutableAttributedString(string: instructions)

        let emailAttributes: [NSAttributedString.Key: AnyObject] = [
            .font: UIFont.normalMediumFont
        ]

        attributedText.addAttributes(emailAttributes, to: emailAddress)
        return attributedText
    }

    // MARK: - Actions

    @objc private func resendButtonTapped() {
        authenticationCoordinator?.resendEmailVerificationCode()
    }

}
