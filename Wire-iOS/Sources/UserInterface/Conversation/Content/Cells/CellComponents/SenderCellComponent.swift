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

private enum TextType {
    case member(accent: UIColor)
    case external(accent: UIColor)
    case guest(accent: UIColor)
    case bot

    var color: UIColor {
        switch self {
        case let .member(accent: accentColor),
             let .guest(accent: accentColor),
             let .external(accent: accentColor):
            return accentColor
        case .bot:
            return .from(scheme: .textForeground)
        }
    }

    var font: UIFont {
        switch self {
        case .member, .bot, .external, .guest:
            return FontSpec(.medium, .semibold).font!
        }
    }

    var icon: StyleKitIcon? {
        switch self {
        case .member:
            return .none
        case .external:
            return .externalPartner
        case .bot:
            return .bot
        case .guest:
            return .guest
        }
    }

    var accessibilityString: String {
        switch self {
        case .member:
            return ""
        case .external:
            return L10n.Localizable.Profile.Details.partner
        case .guest:
            return L10n.Localizable.Profile.Details.guest
        case .bot:
            return L10n.Localizable.General.service
        }
    }

    init(user: UserType, conversation: ConversationLike?) {
        let accentColor = ColorScheme.default.nameAccent(for: user.accentColorValue, variant: ColorScheme.default.variant)

        if user.isServiceUser {
            self = .bot
        } else if user.isExternalPartner {
            self = .external(accent: accentColor)
        } else if let conversation = conversation,
                  user.isGuest(in: conversation) {
            self = .guest(accent: accentColor)
        } else {
            self = .member(accent: accentColor)
        }
    }
}

final class SenderCellComponent: UIView {

    private var senderType: TextType?

    let avatarSpacer = UIView()
    let avatar = UserImageView()
    let authorLabel = UILabel()
    var stackView: UIStackView!
    var avatarSpacerWidthConstraint: NSLayoutConstraint?
    var observerToken: Any?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUp()
    }

    func setUp() {
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

    func createConstraints() {
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

    func configure(with user: UserType, in conversation: ConversationLike?) {
        avatar.user = user
        senderType = TextType(user: user, conversation: conversation)
        configureNameLabel(for: user)

        if !ProcessInfo.processInfo.isRunningTests,
           let userSession = ZMUserSession.shared() {
            observerToken = UserChangeInfo.add(observer: self, for: user, in: userSession)
        }
    }

    private func configureNameLabel(for user: UserType) {
        authorLabel.attributedText = attributedName(for: user)
    }

    private func attributedName(for textType: TextType, string: String) -> NSAttributedString {
        let baseAttributedString = NSAttributedString(string: string, attributes: [.foregroundColor: textType.color, .font: textType.font])

        guard let icon = textType.icon else {
            return baseAttributedString
        }

        let attachment = NSTextAttachment.textAttachment(for: icon, with: UIColor.from(scheme: .iconGuest), iconSize: 12, verticalCorrection: -1.5)
        attachment.accessibilityLabel = textType.accessibilityString

        return baseAttributedString + "  ".attributedString + NSAttributedString(attachment: attachment)
    }

    private func attributedName(for user: UserType) -> NSAttributedString? {
        let fullName = user.name ?? ""

        guard let senderType = senderType  else {
            return nil
        }
        return attributedName(for: senderType, string: fullName)
    }

    // MARK: - tap gesture of avatar

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

        configureNameLabel(for: changeInfo.user)
    }

}
