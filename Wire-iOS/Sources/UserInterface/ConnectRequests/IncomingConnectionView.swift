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
            lightFont: FontSpec(.small, .light).font!,
            boldFont: FontSpec(.small, .medium).font!,
            color: UIColor.from(scheme: .textDimmed)
        )
    }()

    private let usernameLabel = UILabel()
    private let userDetailView = UserNameDetailView()
    private let userImageView = UserImageView()
    private let incomingConnectionFooter = UIView()
    private let acceptButton = Button(style: .full)
    private let ignoreButton = Button(style: .empty)

    public var user: ZMUser {
        didSet {
            self.setupLabelText()
            self.userImageView.user = self.user
        }
    }

    public typealias UserAction = (ZMUser) -> Void
    public var onAccept: UserAction?
    public var onIgnore: UserAction?

    public init(user: ZMUser) {
        self.user = user
        super.init(frame: .zero)

        self.userImageView.userSession = ZMUserSession.shared()
        self.setup()
        self.createConstraints()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.acceptButton.accessibilityLabel = "accept"
        self.acceptButton.setTitle("inbox.connection_request.connect_button_title".localized.uppercased(), for: .normal)
        self.acceptButton.addTarget(self, action: #selector(onAcceptButton), for: .touchUpInside)

        self.ignoreButton.accessibilityLabel = "ignore"
        self.ignoreButton.setTitle("inbox.connection_request.ignore_button_title".localized.uppercased(), for: .normal)
        self.ignoreButton.addTarget(self, action: #selector(onIgnoreButton), for: .touchUpInside)

        self.userImageView.accessibilityLabel = "user image"
        self.userImageView.shouldDesaturate = false
        self.userImageView.size = .big
        self.userImageView.user = self.user

        self.incomingConnectionFooter.addSubview(self.acceptButton)
        self.incomingConnectionFooter.addSubview(self.ignoreButton)

        [self.usernameLabel, self.userDetailView, self.userImageView, self.incomingConnectionFooter].forEach(self.addSubview)
        self.setupLabelText()
    }

    private func setupLabelText() {
        let viewModel = UserNameDetailViewModel(
            user: user,
            fallbackName: "",
            addressBookName: BareUserToUser(user)?.addressBookEntry?.cachedName
        )
        
        usernameLabel.attributedText = viewModel.title
        usernameLabel.accessibilityIdentifier = "name"
        userDetailView.configure(with: viewModel)
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

        constrain(self, self.usernameLabel, self.userDetailView, self.incomingConnectionFooter, self.userImageView) { selfView, usernameLabel, userDetailView, incomingConnectionFooter, userImageView in
            usernameLabel.top == selfView.top + 18
            usernameLabel.centerX == selfView.centerX
            usernameLabel.left >= selfView.left
            
            userDetailView.centerX == selfView.centerX
            userDetailView.top == usernameLabel.bottom + 4
            userDetailView.left >= selfView.left
            userDetailView.bottom <= userImageView.top

            userImageView.center == selfView.center
            userImageView.left >= selfView.left + 54
            userImageView.width == userImageView.height
            userImageView.height <= 264

            incomingConnectionFooter.top >= userImageView.bottom
            incomingConnectionFooter.left == selfView.left
            incomingConnectionFooter.bottom == selfView.bottom
            incomingConnectionFooter.right == selfView.right
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
