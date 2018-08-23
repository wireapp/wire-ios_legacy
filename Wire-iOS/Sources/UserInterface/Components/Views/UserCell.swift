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
import WireExtensionComponents

class UserCell: SeparatorCollectionViewCell {

    enum AccessoryIcon {
        case none, disclosure, connect
    }
    
    var hidesSubtitle: Bool = false
    
    let avatarSpacer = UIView()
    let avatar = BadgeUserImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let connectButton = IconButton()
    let accessoryIconView = UIImageView()
    let guestIconView = UIImageView()
    let verifiedIconView = UIImageView()
    let videoIconView = UIImageView()
    let checkmarkIconView = UIImageView()
    var contentStackView : UIStackView!
    var titleStackView : UIStackView!
    var iconStackView : UIStackView!
    
    weak var user: UserType? = nil
    
    fileprivate static let boldFont: UIFont! = FontSpec.init(.small, .regular).font!
    fileprivate static let lightFont: UIFont! = FontSpec.init(.small, .light).font!

    override var isSelected: Bool {
        didSet {
            let foregroundColor = UIColor(scheme: .background, variant: colorSchemeVariant)
            let backgroundColor = UIColor(scheme: .iconNormal, variant: colorSchemeVariant)
            let borderColor = isSelected ? backgroundColor : backgroundColor.withAlphaComponent(0.64)
            checkmarkIconView.image = isSelected ? UIImage(for: .checkmark, iconSize: .like, color: foregroundColor) : nil
            checkmarkIconView.backgroundColor = isSelected ? backgroundColor : .clear
            checkmarkIconView.layer.borderColor = borderColor.cgColor
        }
    }
        
    override func prepareForReuse() {
        super.prepareForReuse()
        
        UIView.performWithoutAnimation {
            hidesSubtitle = false
            verifiedIconView.isHidden = true
            videoIconView.isHidden = true
            connectButton.isHidden = true
            accessoryIconView.isHidden = true
            checkmarkIconView.image = nil
            checkmarkIconView.layer.borderColor = UIColor(scheme: .iconNormal, variant: colorSchemeVariant).cgColor
            checkmarkIconView.isHidden = true
        }
    }
    
    override func setUp() {
        super.setUp()

        guestIconView.translatesAutoresizingMaskIntoConstraints = false
        guestIconView.contentMode = .center
        guestIconView.accessibilityIdentifier = "img.guest"
        guestIconView.isHidden = true
        
        videoIconView.translatesAutoresizingMaskIntoConstraints = false
        videoIconView.contentMode = .center
        videoIconView.accessibilityIdentifier = "img.video"
        videoIconView.isHidden = true
        
        verifiedIconView.image = WireStyleKit.imageOfShieldverified()
        verifiedIconView.translatesAutoresizingMaskIntoConstraints = false
        verifiedIconView.contentMode = .center
        verifiedIconView.accessibilityIdentifier = "img.shield"
        verifiedIconView.isHidden = true
        
        connectButton.setIcon(.plusCircled, with: .tiny, for: .normal)
        connectButton.imageView?.contentMode = .center
        connectButton.isHidden = true
        
        checkmarkIconView.layer.borderWidth = 2
        checkmarkIconView.contentMode = .center
        checkmarkIconView.layer.cornerRadius = 12
        checkmarkIconView.isHidden = true

        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .center
        accessoryIconView.isHidden = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSpec.init(.normal, .light).font!
        titleLabel.accessibilityIdentifier = "user_cell.name"
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = FontSpec.init(.small, .regular).font!
        subtitleLabel.accessibilityIdentifier = "user_cell.username"
        
        avatar.userSession = ZMUserSession.shared()
        avatar.initials.font = UIFont.systemFont(ofSize: 11, weight: .light)
        avatar.size = .small
        avatar.translatesAutoresizingMaskIntoConstraints = false

        avatarSpacer.addSubview(avatar)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false
        
        iconStackView = UIStackView(arrangedSubviews: [verifiedIconView, guestIconView, videoIconView, connectButton, checkmarkIconView, accessoryIconView])
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
    
    func createConstraints() {
        NSLayoutConstraint.activate([
            checkmarkIconView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkIconView.heightAnchor.constraint(equalToConstant: 24),
            avatar.widthAnchor.constraint(equalToConstant: 28),
            avatar.heightAnchor.constraint(equalToConstant: 28),
            avatarSpacer.widthAnchor.constraint(equalToConstant: 64),
            avatarSpacer.heightAnchor.constraint(equalTo: avatar.heightAnchor),
            avatarSpacer.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarSpacer.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }
    
    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        let sectionTextColor = UIColor(scheme: .sectionText, variant: colorSchemeVariant)
        backgroundColor = contentBackgroundColor(for: colorSchemeVariant)
        videoIconView.image = UIImage(for: .videoCall, iconSize: .tiny, color: UIColor(scheme: .iconGuest, variant: colorSchemeVariant))
        guestIconView.image = UIImage(for: .guest, iconSize: .tiny, color: UIColor(scheme: .iconGuest, variant: colorSchemeVariant))
        accessoryIconView.image = UIImage(for: .disclosureIndicator, iconSize: .like, color: sectionTextColor)
        connectButton.setIconColor(sectionTextColor, for: .normal)
        checkmarkIconView.layer.borderColor = UIColor(scheme: .iconNormal, variant: colorSchemeVariant).cgColor
        titleLabel.textColor = UIColor(scheme: .textForeground, variant: colorSchemeVariant)
        subtitleLabel.textColor = sectionTextColor
        updateTitleLabel()
    }
    
    private func updateTitleLabel() {
        guard let user = self.user else {
            return
        }
        titleLabel.attributedText = user.nameIncludingAvailability(color: UIColor(scheme: .textForeground, variant: colorSchemeVariant))
    }
    
    public func configure(with user: UserType, conversation: ZMConversation? = nil) {
        self.user = user
        
        avatar.user = user
        updateTitleLabel()
        
        if let conversation = conversation {
            guestIconView.isHidden = !user.isGuest(in: conversation)
        } else {
            guestIconView.isHidden = !ZMUser.selfUser().isTeamMember || user.isTeamMember || user.isServiceUser
        }
        
        if let user = user as? ZMUser {
            verifiedIconView.isHidden = !user.trusted() || user.clients.isEmpty
        } else {
            verifiedIconView.isHidden  = true
        }
        
        if let subtitle = subtitle(for: user), subtitle.length > 0, !hidesSubtitle {
            subtitleLabel.isHidden = false
            subtitleLabel.attributedText = subtitle
        } else {
            subtitleLabel.isHidden = true
        }
    }
    
}

// MARK: - Subtitle

extension UserCell {
    
    func subtitle(for user: UserType) -> NSAttributedString? {
        if user.isServiceUser, let service = user as? SearchServiceUser {
            return subtitle(forServiceUser: service)
        } else {
            return subtitle(forRegularUser: user)
        }
    }
    
    private func subtitle(forRegularUser user: UserType) -> NSAttributedString {
        var components: [NSAttributedString?] = []
        
        if let handle = user.handle, !handle.isEmpty {
            components.append("@\(handle)" && UserCell.boldFont)
        }
        
        WirelessExpirationTimeFormatter.shared.string(for: user).apply {
            components.append($0 && UserCell.boldFont)
        }
        
        if let user = user as? ZMUser, let addressBookName = user.addressBookEntry?.cachedName {
            let formatter = UserCell.correlationFormatter(for: colorSchemeVariant)
            components.append(formatter.correlationText(for: user, addressBookName: addressBookName))
        }
        
        return components.compactMap({ $0 }).joined(separator: " · " && UserCell.lightFont)
    }
    
    private func subtitle(forServiceUser service: SearchServiceUser) -> NSAttributedString? {
        guard let summary = service.summary else { return nil }
        
        return summary && UserCell.boldFont
    }
    
    private static var correlationFormatters:  [ColorSchemeVariant : AddressBookCorrelationFormatter] = [:]
    private class func correlationFormatter(for colorSchemeVariant: ColorSchemeVariant) -> AddressBookCorrelationFormatter {
        if let formatter = correlationFormatters[colorSchemeVariant] {
            return formatter
        }
        
        let color = UIColor(scheme: .sectionText, variant: colorSchemeVariant)
        let formatter = AddressBookCorrelationFormatter(lightFont: lightFont, boldFont: boldFont, color: color)
        
        correlationFormatters[colorSchemeVariant] = formatter
        
        return formatter
    }
    
}

// MARK: - Availability

extension UserType {
    
    func nameIncludingAvailability(color: UIColor) -> NSAttributedString? {
        if ZMUser.selfUser().isTeamMember, let user = self as? ZMUser {
            return AvailabilityStringBuilder.string(for: user, with: .list, color: color)
        } else {
            if let name = name {
                return NSAttributedString(string: name)
            } else {
                return nil
            }
        }
    }
    
}
