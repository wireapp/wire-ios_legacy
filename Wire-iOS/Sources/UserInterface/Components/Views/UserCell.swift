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

class UserCell: UICollectionViewCell, Themeable {
    
    dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default().variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }
    
    // if nil the background color is the default content background color for the theme
    dynamic var contentBackgroundColor: UIColor? = nil {
        didSet {
            guard oldValue != contentBackgroundColor else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }
    
    enum AccessoryIcon {
        case none, disclosure, connect
    }
    
    let separator = UIView()
    let avatarSpacer = UIView()
    let avatar = BadgeUserImageView(magicPrefix: "people_picker.search_results_mode")
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let connectButton = IconButton()
    let accessoryIconView = UIImageView()
    let guestIconView = UIImageView()
    let verifiedIconView = UIImageView()
    let checkmarkIconView = UIImageView()
    var contentStackView : UIStackView!
    var titleStackView : UIStackView!
    var iconStackView : UIStackView!
    
    fileprivate static let boldFont: UIFont! = FontSpec.init(.small, .regular).font!
    fileprivate static let lightFont: UIFont! = FontSpec.init(.small, .light).font!
    
    private func contentBackgroundColor(for colorSchemeVariant: ColorSchemeVariant) -> UIColor {
        return contentBackgroundColor ?? UIColor.wr_color(fromColorScheme: ColorSchemeColorBarBackground, variant: colorSchemeVariant)
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? .init(white: 0, alpha: 0.08)
                : contentBackgroundColor(for: colorSchemeVariant)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            let foregroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorBackground, variant: colorSchemeVariant)
            let backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: colorSchemeVariant)
            let borderColor = isSelected ? backgroundColor : backgroundColor.withAlphaComponent(0.64)
            checkmarkIconView.image = isSelected ? UIImage(for: .checkmark, iconSize: .like, color: foregroundColor) : nil
            checkmarkIconView.backgroundColor = isSelected ? backgroundColor : .clear
            checkmarkIconView.layer.borderColor = borderColor.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        UIView.performWithoutAnimation {
            verifiedIconView.isHidden = true
            connectButton.isHidden = true
            accessoryIconView.isHidden = false
            checkmarkIconView.image = nil
            checkmarkIconView.layer.borderColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: colorSchemeVariant).cgColor
            checkmarkIconView.isHidden = true
        }
    }
    
    fileprivate func setup() {
        guestIconView.translatesAutoresizingMaskIntoConstraints = false
        guestIconView.contentMode = .center
        guestIconView.accessibilityIdentifier = "img.guest"
        guestIconView.isHidden = true
        
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
        
        avatar.size = .small
        avatar.translatesAutoresizingMaskIntoConstraints = false

        avatarSpacer.addSubview(avatar)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false
        
        iconStackView = UIStackView(arrangedSubviews: [verifiedIconView, guestIconView, connectButton, checkmarkIconView, accessoryIconView])
        iconStackView.spacing = 8
        iconStackView.axis = .horizontal
        iconStackView.distribution = .fill
        iconStackView.alignment = .center
        iconStackView.translatesAutoresizingMaskIntoConstraints = false
        iconStackView.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        
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
        
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(contentStackView)
        contentView.addSubview(separator)
        
        createConstraints()
        applyColorScheme(colorSchemeVariant)
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
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 64),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: .hairline),
        ])
    }
    
    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        let sectionTextColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSectionText, variant: colorSchemeVariant)
        backgroundColor = contentBackgroundColor(for: colorSchemeVariant)
        separator.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorCellSeparator, variant: colorSchemeVariant)
        guestIconView.image = UIImage(for: .guest, iconSize: .tiny, color: UIColor.wr_color(fromColorScheme: ColorSchemeColorIconGuest, variant: colorSchemeVariant))
        accessoryIconView.image = UIImage(for: .disclosureIndicator, iconSize: .like, color: sectionTextColor)
        connectButton.setIconColor(sectionTextColor, for: .normal)
        checkmarkIconView.layer.borderColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: colorSchemeVariant).cgColor
        titleLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: colorSchemeVariant)
        subtitleLabel.textColor = sectionTextColor
    }
    
    public func configure(with user: ZMBareUser, conversation: ZMConversation? = nil) {
        avatar.user = user
        titleLabel.attributedText = user.nameIncludingAvailability(color: UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: colorSchemeVariant))
        
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
        
        if let subtitle = subtitle(for: user), subtitle.length > 0 {
            subtitleLabel.isHidden = false
            subtitleLabel.attributedText = subtitle
        } else {
            subtitleLabel.isHidden = true
        }
    }
    
}

// MARK: - Subtitle

extension UserCell {
    
    func subtitle(for user: ZMBareUser) -> NSAttributedString? {
        if user.isServiceUser, let service = user as? SearchServiceUser {
            return subtitle(forServiceUser: service)
        } else {
            return subtitle(forRegularUser: user)
        }
    }
    
    private func subtitle(forRegularUser user: ZMBareUser) -> NSAttributedString {
        var components: [NSAttributedString?] = []
        
        if let handle = user.handle, !handle.isEmpty {
            components.append("@\(handle)" && UserCell.boldFont)
        }
        
        if let user = user as? ZMUser, let addressBookName = user.addressBookEntry?.cachedName {
            let formatter = UserCell.correlationFormatter(for: colorSchemeVariant)
            components.append(formatter.correlationText(for: user, addressBookName: addressBookName))
        }
        
        return components.flatMap({ $0 }).joined(separator: " · " && UserCell.lightFont)
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
        
        let color = UIColor.wr_color(fromColorScheme: ColorSchemeColorSectionText, variant: colorSchemeVariant)
        let formatter = AddressBookCorrelationFormatter(lightFont: lightFont, boldFont: boldFont, color: color)
        
        correlationFormatters[colorSchemeVariant] = formatter
        
        return formatter
    }
    
}

// MARK: - Availability

extension ZMBareUser {
    
    func nameIncludingAvailability(color: UIColor) -> NSAttributedString {
        if ZMUser.selfUser().isTeamMember, let user = self as? ZMUser {
            return AvailabilityStringBuilder.string(for: user, with: .list, color: color)
        } else {
            return NSAttributedString(string: name)
        }
    }
    
}
