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

class GroupDetailsParticipantCell: UICollectionViewCell, Themeable {
    
    dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default().variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }
    
    enum AccessoryIcon {
        case none, disclosure, connect
    }
    
    let separator = UIView()
    let avatar = BadgeUserImageView(magicPrefix: "people_picker.search_results_mode")
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let accessoryActionButton = IconButton()
    let guestIconView = UIImageView()
    let verifiedIconView = UIImageView()
    var contentStackView : UIStackView!
    var titleStackView : UIStackView!
    var iconStackView : UIStackView!
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? .init(white: 0, alpha: 0.08)
                : .wr_color(fromColorScheme: ColorSchemeColorBarBackground, variant: colorSchemeVariant)
        }
    }
    
    var accessoryIcon : AccessoryIcon = .none {
        didSet {
            switch accessoryIcon {
            case .none:
                accessoryActionButton.isHidden = true
            case .disclosure:
                accessoryActionButton.isHidden = false
                accessoryActionButton.setIcon(.disclosureIndicator, with: .like, for: .normal)
            case .connect:
                accessoryActionButton.isHidden = false
                accessoryActionButton.setIcon(.plusCircled, with: .like, for: .normal)
            }
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
    
    fileprivate func setup() {
        guestIconView.translatesAutoresizingMaskIntoConstraints = false
        guestIconView.contentMode = .center
        guestIconView.accessibilityIdentifier = "img.guest"
        
        verifiedIconView.image = WireStyleKit.imageOfShieldverified()
        verifiedIconView.translatesAutoresizingMaskIntoConstraints = false
        verifiedIconView.contentMode = .center
        verifiedIconView.accessibilityIdentifier = "img.shield"
        
        accessoryActionButton.setIcon(.disclosureIndicator, with: .like, for: .normal)
        accessoryActionButton.imageView?.contentMode = .center
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSpec.init(.normal, .light).font!
        titleLabel.accessibilityIdentifier = "name"
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = FontSpec.init(.small, .regular).font!
        subtitleLabel.accessibilityIdentifier = "username"
        
        avatar.size = .small
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 28).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 28).isActive = true
        
        let avatarSpacer = UIView()
        avatarSpacer.addSubview(avatar)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false
        avatarSpacer.widthAnchor.constraint(equalToConstant: 64).isActive = true
        avatarSpacer.heightAnchor.constraint(equalTo: avatar.heightAnchor).isActive = true
        avatarSpacer.centerXAnchor.constraint(equalTo: avatar.centerXAnchor).isActive = true
        avatarSpacer.centerYAnchor.constraint(equalTo: avatar.centerYAnchor).isActive = true
        
        iconStackView = UIStackView(arrangedSubviews: [verifiedIconView, guestIconView, accessoryActionButton])
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
        
        contentView.addSubview(contentStackView)
        contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 64).isActive = true
        separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: .hairline).isActive = true
        
        applyColorScheme(colorSchemeVariant)
    }
    
    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorBarBackground, variant: colorSchemeVariant)
        separator.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorCellSeparator, variant: colorSchemeVariant)
        accessoryActionButton.setIconColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorSectionText, variant: colorSchemeVariant), for: .normal)
        titleLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: colorSchemeVariant)
        subtitleLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSectionText, variant: colorSchemeVariant)
        guestIconView.image = UIImage(for: .guest, iconSize: .tiny, color: UIColor.wr_color(fromColorScheme: ColorSchemeColorIconGuest, variant: colorSchemeVariant))
    }
    
    public func configure(with user: ZMBareUser, conversation: ZMConversation) {
        avatar.user = user
        titleLabel.attributedText = user.nameIncludingAvailability(color: UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: colorSchemeVariant))
        guestIconView.isHidden = !user.isGuest(in: conversation)
        
        if let user = user as? ZMUser {
            verifiedIconView.isHidden = !user.trusted() || user.clients.isEmpty
        } else {
            verifiedIconView.isHidden  = true
        }
        
        if let handle = user.handle, !handle.isEmpty {
            subtitleLabel.isHidden = false
            subtitleLabel.text = "@\(handle)"
        } else {
            subtitleLabel.isHidden = true
        }
    }
    
}


extension ZMBareUser {
    
    func nameIncludingAvailability(color: UIColor) -> NSAttributedString {
        if ZMUser.selfUser().isTeamMember, let user = self as? ZMUser {
            return AvailabilityStringBuilder.string(for: user, with: .list, color: color)
        } else {
            return NSAttributedString(string: name)
        }
    }
    
}
