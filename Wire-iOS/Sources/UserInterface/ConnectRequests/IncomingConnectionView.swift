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
        [incomingConnectionFooter,
         acceptButton,
         ignoreButton,
         usernameLabel,
         userDetailView,
         userImageView].prepareForLayout()

        NSLayoutConstraint.activate([
            ignoreButton.leftAnchor.constraint(equalTo: incomingConnectionFooter.leftAnchor, constant: 16),
            ignoreButton.topAnchor.constraint(equalTo: incomingConnectionFooter.topAnchor, constant: 12),
            ignoreButton.bottomAnchor.constraint(equalTo: incomingConnectionFooter.bottomAnchor, constant: -16),
            ignoreButton.heightAnchor.constraint(equalToConstant: 40),
            ignoreButton.rightAnchor.constraint(equalTo: incomingConnectionFooter.centerXAnchor, constant: -8),

            acceptButton.rightAnchor.constraint(equalTo: incomingConnectionFooter.rightAnchor, constant: -16),
            acceptButton.leftAnchor.constraint(equalTo: incomingConnectionFooter.centerXAnchor, constant: 8),
            acceptButton.centerYAnchor.constraint(equalTo: ignoreButton.centerYAnchor),
            acceptButton.heightAnchor.constraint(equalTo: ignoreButton.heightAnchor),

            usernameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            usernameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            usernameLabel.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor),

            userDetailView.centerXAnchor.constraint(equalTo: centerXAnchor),
            userDetailView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            userDetailView.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor),
            userDetailView.bottomAnchor.constraint(lessThanOrEqualTo: userImageView.topAnchor),

            userImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            userImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            userImageView.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: 54),
            userImageView.widthAnchor.constraint(equalTo: userImageView.heightAnchor),
            userImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 264),

            incomingConnectionFooter.topAnchor.constraint(greaterThanOrEqualTo: userImageView.bottomAnchor),
            incomingConnectionFooter.leftAnchor.constraint(equalTo: leftAnchor),
            incomingConnectionFooter.bottomAnchor.constraint(equalTo: bottomAnchor),
            incomingConnectionFooter.rightAnchor.constraint(equalTo: rightAnchor)
        ])
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
