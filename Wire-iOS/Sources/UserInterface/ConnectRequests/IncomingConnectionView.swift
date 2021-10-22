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
import WireSyncEngine

final class IncomingConnectionView: UIView {

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

    var user: UserType {
        didSet {
            setupLabelText()
            userImageView.user = user
        }
    }

    typealias UserAction = (UserType) -> Void
    var onAccept: UserAction?
    var onIgnore: UserAction?

    init(user: UserType) {
        self.user = user
        super.init(frame: .zero)

        userImageView.userSession = ZMUserSession.shared()
        userImageView.initialsFont = UIFont.systemFont(ofSize: 55, weight: .semibold).monospaced()
        setup()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        acceptButton.accessibilityLabel = "accept"
        acceptButton.setTitle("inbox.connection_request.connect_button_title".localized(uppercased: true), for: .normal)
        acceptButton.addTarget(self, action: #selector(onAcceptButton), for: .touchUpInside)

        ignoreButton.accessibilityLabel = "ignore"
        ignoreButton.setTitle("inbox.connection_request.ignore_button_title".localized(uppercased: true), for: .normal)
        ignoreButton.addTarget(self, action: #selector(onIgnoreButton), for: .touchUpInside)

        userImageView.accessibilityLabel = "user image"
        userImageView.shouldDesaturate = false
        userImageView.size = .big
        userImageView.user = user

        incomingConnectionFooter.addSubview(acceptButton)
        incomingConnectionFooter.addSubview(ignoreButton)

        [usernameLabel, userDetailView, userImageView, incomingConnectionFooter].forEach(addSubview)
        setupLabelText()
    }

    private func setupLabelText() {
        let viewModel = UserNameDetailViewModel(
            user: user,
            fallbackName: "",
            addressBookName: (user as? ZMUser)?.addressBookEntry?.cachedName
        )

        usernameLabel.attributedText = viewModel.title
        usernameLabel.accessibilityIdentifier = "name"
        userDetailView.configure(with: viewModel)
    }

    private func createConstraints() {
        constrain(incomingConnectionFooter, acceptButton, ignoreButton) { incomingConnectionFooter, acceptButton, ignoreButton in
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

        constrain(self, usernameLabel, userDetailView, incomingConnectionFooter, userImageView) { selfView, usernameLabel, userDetailView, incomingConnectionFooter, userImageView in
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

    @objc
    private func onAcceptButton(sender: AnyObject!) {
        onAccept?(user)
    }

    @objc
    private func onIgnoreButton(sender: AnyObject!) {
        onIgnore?(user)
    }
}
