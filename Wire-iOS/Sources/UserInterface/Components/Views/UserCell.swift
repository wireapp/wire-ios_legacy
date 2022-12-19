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
import WireCommonComponents
import WireSyncEngine

extension UIImageView {
    func setUpIconImageView(accessibilityIdentifier: String? = nil) {
        translatesAutoresizingMaskIntoConstraints = false
        contentMode = .center
        self.accessibilityIdentifier = accessibilityIdentifier
        isHidden = true
    }
}

class UserCell: SeparatorCollectionViewCell, SectionListCellType {

    var hidesSubtitle: Bool = false
    typealias IconColors = SemanticColors.Icon
    typealias LabelColors = SemanticColors.Label

    let avatarSpacer = UIView()
    let avatar = BadgeUserImageView()
    let titleLabel = DynamicFontLabel(fontSpec: .normalLightFont,
                                      color: LabelColors.textDefault)
    let subtitleLabel = DynamicFontLabel(fontSpec: .smallRegularFont,
                                         color: LabelColors.textCellSubtitle)
    let connectButton = IconButton()
    let accessoryIconView = UIImageView()
    let userTypeIconView = IconImageView()
    let verifiedIconView = UIImageView()
    let videoIconView = IconImageView()
    let checkmarkIconView = UIImageView()
    let microphoneIconView = PulsingIconImageView()
    var contentStackView: UIStackView!
    var titleStackView: UIStackView!
    var iconStackView: UIStackView!

    fileprivate var avatarSpacerWidthConstraint: NSLayoutConstraint?

    weak var user: UserType?

    static let boldFont: FontSpec = .smallRegularFont
    static let lightFont: FontSpec = .smallLightFont
    static let defaultAvatarSpacing: CGFloat = 64

    /// Specify a custom avatar spacing
    var avatarSpacing: CGFloat? {
        get {
            return avatarSpacerWidthConstraint?.constant
        }
        set {
            avatarSpacerWidthConstraint?.constant = newValue ?? UserCell.defaultAvatarSpacing
        }
    }

    var sectionName: String?
    var cellIdentifier: String?
    let iconColor = IconColors.foregroundDefault

    override var isSelected: Bool {
        didSet {
            checkmarkIconView.image = isSelected ? StyleKitIcon.checkmark.makeImage(size: 12, color: IconColors.foregroundCheckMarkSelected) : nil
            checkmarkIconView.backgroundColor = isSelected ? IconColors.backgroundCheckMarkSelected : IconColors.backgroundCheckMark
            checkmarkIconView.layer.borderColor = isSelected ? UIColor.clear.cgColor : IconColors.borderCheckMark.cgColor
            setupAccessibility()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? SemanticColors.View.backgroundUserCellHightLighted : SemanticColors.View.backgroundUserCell
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        UIView.performWithoutAnimation {
            hidesSubtitle = false
            userTypeIconView.isHidden = true
            verifiedIconView.isHidden = true
            videoIconView.isHidden = true
            microphoneIconView.isHidden = true
            connectButton.isHidden = true
            accessoryIconView.isHidden = true
            checkmarkIconView.image = nil
            checkmarkIconView.layer.borderColor = IconColors.borderCheckMark.cgColor
            checkmarkIconView.isHidden = true
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        //  Border colors are not dynamically updating for Dark Mode
        //  When you use adaptive colors with CALayers you’ll notice that these colors,
        // are not updating when switching appearance live in the app.
        // That's why we use the traitCollectionDidChange(_:) method.
        checkmarkIconView.layer.borderColor = IconColors.borderCheckMark.cgColor
    }

    override func setUp() {
        super.setUp()

        backgroundColor = SemanticColors.View.backgroundUserCell

        userTypeIconView.setUpIconImageView()
        microphoneIconView.setUpIconImageView()
        videoIconView.setUpIconImageView()

        userTypeIconView.set(size: .tiny, color: iconColor)
        microphoneIconView.set(size: .tiny, color: iconColor)
        videoIconView.set(size: .tiny, color: iconColor)

        verifiedIconView.image = WireStyleKit.imageOfShieldverified
        verifiedIconView.setUpIconImageView(accessibilityIdentifier: "img.shield")

        connectButton.setIcon(.plusCircled, size: .tiny, for: .normal)
        connectButton.setIconColor(iconColor, for: .normal)
        connectButton.imageView?.contentMode = .center
        connectButton.isHidden = true

        checkmarkIconView.layer.borderWidth = 2
        checkmarkIconView.contentMode = .center
        checkmarkIconView.layer.cornerRadius = 12
        checkmarkIconView.backgroundColor = IconColors.backgroundCheckMark
        checkmarkIconView.isHidden = true

        accessoryIconView.setUpIconImageView()

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "user_cell.name"

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.accessibilityIdentifier = "user_cell.username"

        avatar.userSession = ZMUserSession.shared()
        avatar.initialsFont = .avatarInitial
        avatar.size = .small
        avatar.translatesAutoresizingMaskIntoConstraints = false

        avatarSpacer.addSubview(avatar)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false

        iconStackView = UIStackView(arrangedSubviews: [videoIconView, microphoneIconView, userTypeIconView, verifiedIconView, connectButton, checkmarkIconView, accessoryIconView])
        iconStackView.spacing = 16
        iconStackView.axis = .horizontal
        iconStackView.distribution = .fill
        iconStackView.alignment = .center
        iconStackView.translatesAutoresizingMaskIntoConstraints = false
        iconStackView.setContentHuggingPriority(.required, for: .horizontal)

        titleStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStackView.axis = .vertical
        titleStackView.distribution = .equalSpacing
        titleStackView.alignment = .leading
        titleStackView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView = UIStackView(arrangedSubviews: [avatarSpacer, titleStackView, iconStackView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStackView)
        createConstraints()
    }

    private func createConstraints() {
        let avatarSpacerWidthConstraint = avatarSpacer.widthAnchor.constraint(equalToConstant: UserCell.defaultAvatarSpacing)
        self.avatarSpacerWidthConstraint = avatarSpacerWidthConstraint

        NSLayoutConstraint.activate([
            checkmarkIconView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkIconView.heightAnchor.constraint(equalToConstant: 24),
            avatar.widthAnchor.constraint(equalToConstant: 28),
            avatar.heightAnchor.constraint(equalToConstant: 28),
            avatarSpacerWidthConstraint,
            avatarSpacer.heightAnchor.constraint(equalTo: avatar.heightAnchor),
            avatarSpacer.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarSpacer.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    private func setupAccessibility() {
        typealias ContactsList = L10n.Accessibility.ContactsList
        typealias ServicesList = L10n.Accessibility.ServicesList
        typealias ClientsList = L10n.Accessibility.ClientsList
        typealias CreateConversation = L10n.Accessibility.CreateConversation

        guard let title = titleLabel.text,
              let subtitle = subtitleLabel.text else {
                  isAccessibilityElement = false
                  return
              }
        isAccessibilityElement = true
        accessibilityTraits = .button

        var content = "\(title), \(subtitle)"
        if let userType = userTypeIconView.accessibilityLabel,
           !userTypeIconView.isHidden {
            content += ", \(userType)"
        }

        if !verifiedIconView.isHidden {
            content += ", " + ClientsList.DeviceVerified.description
        }

        accessibilityLabel = content

        if !checkmarkIconView.isHidden {
            accessibilityHint = isSelected
                                ? CreateConversation.SelectedUser.hint
                                : CreateConversation.UnselectedUser.hint
        } else if let user = user, user.isServiceUser {
            accessibilityHint = ServicesList.ServiceCell.hint
        } else {
            accessibilityHint = ContactsList.UserCell.hint
        }
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)

        accessoryIconView.setTemplateIcon(.disclosureIndicator, size: 12)
        accessoryIconView.tintColor = IconColors.foregroundDefault

        updateTitleLabel()
    }

    private func updateTitleLabel(selfUser: UserType? = nil) {
        guard let user = user,
              let selfUser = selfUser else {
                  return
              }
        var attributedTitle = user.nameIncludingAvailability(
            color: SemanticColors.Label.textDefault,
            selfUser: selfUser)

        if user.isSelfUser, let title = attributedTitle {
            attributedTitle = title + "user_cell.title.you_suffix".localized
        }

        titleLabel.attributedText = attributedTitle
    }

    func configure(with user: UserType,
                   selfUser: UserType,
                   subtitle overrideSubtitle: NSAttributedString? = nil,
                   conversation: GroupDetailsConversationType? = nil) {

        let subtitle: NSAttributedString?
        if overrideSubtitle == nil {
            subtitle = self.subtitle(for: user)
        } else {
            subtitle = overrideSubtitle
        }

        self.user = user

        avatar.user = user
        updateTitleLabel(selfUser: selfUser)

        let style = UserTypeIconStyle(conversation: conversation, user: user, selfUser: selfUser)
        userTypeIconView.set(style: style)

        verifiedIconView.isHidden = !user.isVerified

        if let subtitle = subtitle, !subtitle.string.isEmpty, !hidesSubtitle {
            subtitleLabel.isHidden = false
            subtitleLabel.attributedText = subtitle
        } else {
            subtitleLabel.isHidden = true
        }
        setupAccessibility()
    }

}

// MARK: - Subtitle

extension UserCell: UserCellSubtitleProtocol {}

extension UserCell {

    func subtitle(for user: UserType) -> NSAttributedString? {
        if user.isServiceUser, let service = user as? SearchServiceUser {
            return subtitle(forServiceUser: service)
        } else {
            return subtitle(forRegularUser: user)
        }
    }

    private func subtitle(forServiceUser service: SearchServiceUser) -> NSAttributedString? {
        guard let summary = service.summary else { return nil }

        return summary && UserCell.boldFont.font!
    }

    static var correlationFormatters: [ColorSchemeVariant: AddressBookCorrelationFormatter] = [:]
}

// MARK: - Availability

extension UserType {

    func nameIncludingAvailability(color: UIColor, selfUser: UserType) -> NSAttributedString? {
        if selfUser.isTeamMember {
            return AvailabilityStringBuilder.string(for: self, with: .list, color: color)
        } else if let name = name {
            return name && color
        }

        return nil
    }
}
