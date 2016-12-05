//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

public final class IncomingConnectionView: UIView {

    static private var correlationFormatter: AddressBookCorrelationFormatter = {
        return AddressBookCorrelationFormatter(
            lightFont: UIFont(magicIdentifier: "style.text.small.font_spec_light"),
            boldFont: UIFont(magicIdentifier: "style.text.small.font_spec_bold"),
            color: ColorScheme.default().color(withName: ColorSchemeColorTextDimmed)
        )
    }()

    public typealias User = ZMBareUser & ZMBareUserConnection & ZMSearchableUser

    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let correlationLabel = UILabel()
    private let labelContainer = UIView()

    private let userImageView = UserImageView()
    private let incomingConnectionFooter = UIView()
    private let acceptButton = Button(style: .full)
    private let ignoreButton = Button(style: .empty)

    public var user: User {
        didSet {
            self.updateForUser()
            self.userImageView.user = self.user
        }
    }

    public var commonConnectionsCount: UInt = 0 {
        didSet {
            self.setupLabelText()
        }
    }

    public typealias UserAction = (User) -> Void
    public var onAccept: UserAction?
    public var onIgnore: UserAction?

    public init(user: User) {
        self.user = user
        super.init(frame: .zero)

        self.setup()
        self.createConstraints()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        [nameLabel, handleLabel, correlationLabel].forEach {
            $0.numberOfLines = 0
            $0.textAlignment = .center
        }

        nameLabel.accessibilityIdentifier = "name"
        handleLabel.accessibilityIdentifier = "handle"
        correlationLabel.accessibilityIdentifier = "correlation"

        self.acceptButton.accessibilityLabel = "accept"
        self.acceptButton.setTitle("inbox.connection_request.connect_button_title".localized.uppercased(), for: .normal)
        self.acceptButton.addTarget(self, action: #selector(onAcceptButton), for: .touchUpInside)

        self.ignoreButton.accessibilityLabel = "ignore"
        self.ignoreButton.setTitle("inbox.connection_request.ignore_button_title".localized.uppercased(), for: .normal)
        self.ignoreButton.addTarget(self, action: #selector(onIgnoreButton), for: .touchUpInside)

        self.userImageView.accessibilityLabel = "user image"
        self.userImageView.shouldDesaturate = false
        self.userImageView.suggestedImageSize = .big
        self.userImageView.user = self.user

        self.incomingConnectionFooter.addSubview(self.acceptButton)
        self.incomingConnectionFooter.addSubview(self.ignoreButton)

        [self.labelContainer, self.userImageView, self.incomingConnectionFooter].forEach(self.addSubview)
        [self.nameLabel, self.handleLabel, self.correlationLabel].forEach(labelContainer.addSubview)
        self.updateForUser()
    }

    private func updateForUser() {
        self.setupLabelText()
    }

    private func setupNameLabelText() {
        guard let username = user.name else { return }
        nameLabel.attributedText = username && [
            NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextForeground),
            NSFontAttributeName: UIFont(magicIdentifier: "style.text.normal.font_spec_bold")
        ]
    }

    private func setupHandleLabelText() {
        guard let handle = user.handle else { return }
        handleLabel.attributedText = ("@" + handle) && [
            NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextDimmed),
            NSFontAttributeName: UIFont(magicIdentifier: "style.text.small.font_spec_bold")
        ]
    }

    private func setupCorrelationLabelText() {
        correlationLabel.attributedText = type(of: self).correlationFormatter.correlationText(
            for: user,
            with: Int(commonConnectionsCount),
            addressBookName: BareUserToUser(user)?.contact()?.name
        )
    }

    private func setupLabelText() {
        setupNameLabelText()
        setupHandleLabelText()
        setupCorrelationLabelText()
    }

    private func createConstraints() {
        constrain(self.incomingConnectionFooter, self.acceptButton, self.ignoreButton) { incomingConnectionFooter, acceptButton, ignoreButton in
            ignoreButton.left == incomingConnectionFooter.left + 16
            ignoreButton.top == incomingConnectionFooter.top + 12
            ignoreButton.bottom == incomingConnectionFooter.bottom - 16
            ignoreButton.height == 40
            ignoreButton.right == incomingConnectionFooter.centerX - 8

            acceptButton.right == incomingConnectionFooter.right - 16
            acceptButton.left == incomingConnectionFooter.centerX + 8
            acceptButton.centerY == ignoreButton.centerY
            acceptButton.height == ignoreButton.height
        }

        constrain(self, self.labelContainer, self.incomingConnectionFooter, self.userImageView) { selfView, labelContainer, incomingConnectionFooter, userImageView in
            labelContainer.centerX == selfView.centerX
            labelContainer.top == selfView.top + 12
            labelContainer.left >= selfView.left
            labelContainer.bottom <= userImageView.top

            userImageView.center == selfView.center
            userImageView.left >= selfView.left + 54
            userImageView.width == userImageView.height
            userImageView.height <= 264

            incomingConnectionFooter.top >= userImageView.bottom
            incomingConnectionFooter.left == selfView.left
            incomingConnectionFooter.bottom == selfView.bottom
            incomingConnectionFooter.right == selfView.right
        }

        constrain(labelContainer, nameLabel, handleLabel, correlationLabel) { labelContainer, nameLabel, handleLabel, correlationLabel in
            nameLabel.top == labelContainer.top
            nameLabel.height == 32
            handleLabel.top == nameLabel.bottom + 10
            handleLabel.height == 16
            correlationLabel.top == handleLabel.bottom
            handleLabel.height == 16

            [nameLabel, handleLabel, correlationLabel].forEach {
                $0.leading == labelContainer.leading
                $0.trailing == labelContainer.trailing
            }
        }
    }

    // MARK: - Actions

    @objc func onAcceptButton(sender: AnyObject!) {
        self.onAccept?(self.user)
    }

    @objc func onIgnoreButton(sender: AnyObject!) {
        self.onIgnore?(self.user)
    }
}
