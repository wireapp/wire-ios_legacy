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

import Foundation
import UIKit
import WireSyncEngine
import WireCommonComponents

private struct SenderCellConfiguration {

    let fullName: String
    let textColor: UIColor
    let icon: StyleKitIcon?

    init(user: UserType, in conversation: ConversationLike?) {
        fullName = user.name ?? ""
        if user.isServiceUser {
            textColor = .from(scheme: .textForeground)
            icon = .bot
        } else if user.isExternalPartner {
            textColor = user.nameAccentColor
            icon = .externalPartner
        } else if let conversation = conversation,
                  user.isGuest(in: conversation) {
            textColor = user.nameAccentColor
            icon = .guest
        } else {
            textColor = user.nameAccentColor
            icon = .none
        }
    }

}

final class SenderCellComponent: UIView {

    let avatarSpacer = UIView()
    let avatar = UserImageView()
    let authorLabel = UILabel()
    var stackView: UIStackView!
    var avatarSpacerWidthConstraint: NSLayoutConstraint?
    var observerToken: Any?

    var conversation: ConversationLike?

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    // MARK: - Configuration

    func configure(with user: UserType, in conversation: ConversationLike?) {
        avatar.user = user
        self.conversation = conversation

        let configuration = SenderCellConfiguration(user: user, in: conversation)
        configureNameLabel(for: configuration)

        if !ProcessInfo.processInfo.isRunningTests,
           let userSession = ZMUserSession.shared() {
            observerToken = UserChangeInfo.add(observer: self, for: user, in: userSession)
        }
    }

    private func setup() {
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        authorLabel.font = .normalLightFont
        authorLabel.accessibilityIdentifier = "author.name"
        authorLabel.numberOfLines = 1

        avatar.userSession = ZMUserSession.shared()
        avatar.initialsFont = .avatarInitial
        avatar.size = .badge
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedOnAvatar)))

        avatarSpacer.addSubview(avatar)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false

        stackView = UIStackView(arrangedSubviews: [avatarSpacer, authorLabel])
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        createConstraints()
    }

    private func createConstraints() {
        let avatarSpacerWidthConstraint = avatarSpacer.widthAnchor.constraint(equalToConstant: conversationHorizontalMargins.left)
        self.avatarSpacerWidthConstraint = avatarSpacerWidthConstraint

        NSLayoutConstraint.activate([
            avatarSpacerWidthConstraint,
            avatarSpacer.heightAnchor.constraint(equalTo: avatar.heightAnchor),
            avatarSpacer.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarSpacer.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
    }

    private func configureNameLabel(for configuration: SenderCellConfiguration) {
        authorLabel.attributedText = attributedName(for: configuration)
    }

    private func attributedName(for configuration: SenderCellConfiguration) -> NSAttributedString {
        let baseAttributedString = NSAttributedString(string: configuration.fullName,
                                                      attributes: [.foregroundColor: configuration.textColor,
                                                                   .font: UIFont.mediumSemiboldFont])

        guard let icon = configuration.icon else {
            return baseAttributedString
        }
        let attachment = NSTextAttachment.textAttachment(for: icon,
                                                         with: UIColor.from(scheme: .iconGuest),
                                                         iconSize: 12, verticalCorrection: -1.5)

        return baseAttributedString + "  ".attributedString + NSAttributedString(attachment: attachment)
    }

    // MARK: - Tap gesture of avatar

    @objc func tappedOnAvatar() {
        guard let user = avatar.user else { return }

        SessionManager.shared?.showUserProfile(user: user)
    }

}

// MARK: - User change observer

extension SenderCellComponent: ZMUserObserver {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.nameChanged || changeInfo.accentColorValueChanged else {
            return
        }

        let configuration = SenderCellConfiguration(user: changeInfo.user, in: conversation)
        configureNameLabel(for: configuration)
    }

}
