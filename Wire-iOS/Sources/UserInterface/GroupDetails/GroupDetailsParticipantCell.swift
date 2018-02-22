//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

class GroupDetailsParticipantCell: UICollectionViewCell {
    
    enum AccessoryIcon {
        case none, disclosure, connect
    }
    
    let separator = UIView()
    let avatar = UserImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let accessoryActionButton = IconButton()
    let guestIconView = UIImageView()
    var contentStackView : UIStackView!
    var titleStackView : UIStackView!
    var iconStackView : UIStackView!
    
    var variant : ColorSchemeVariant = ColorScheme.default().variant {
        didSet {
            guard oldValue != variant else { return }
            configureColors()
        }
    }
    
    var accessoryIcon : AccessoryIcon = .none {
        didSet {
            switch accessoryIcon {
            case .none:
                accessoryActionButton.isHidden = true
            case .disclosure:
                accessoryActionButton.isHidden = false
                accessoryActionButton.setIcon(.disclosureIndicator, with: .tiny, for: .normal)
            case .connect:
                accessoryActionButton.isHidden = false
                accessoryActionButton.setIcon(.plusCircled, with: .tiny, for: .normal)
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
        guestIconView.image = UIImage(for: .person, iconSize: .tiny, color: UIColor.wr_color(fromColorScheme: ColorSchemeColorSeparator, variant: variant))
        guestIconView.translatesAutoresizingMaskIntoConstraints = false
        guestIconView.contentMode = .scaleAspectFit
        
        accessoryActionButton.setIcon(.disclosureIndicator, with: .tiny, for: .normal)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSpec.init(.normal, .medium).font!
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = FontSpec.init(.small, .medium).font!
        
        avatar.size = .small
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 32).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        let avatarSpacer = UIView()
        avatarSpacer.addSubview(avatar)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false
        avatarSpacer.widthAnchor.constraint(equalToConstant: 64).isActive = true
        avatarSpacer.heightAnchor.constraint(equalTo: avatar.heightAnchor).isActive = true
        avatarSpacer.centerXAnchor.constraint(equalTo: avatar.centerXAnchor).isActive = true
        avatarSpacer.centerYAnchor.constraint(equalTo: avatar.centerYAnchor).isActive = true
        
        iconStackView = UIStackView(arrangedSubviews: [guestIconView, accessoryActionButton])
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
        
        configureColors()
    }
    
    private func configureColors() {
        let separatorColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSeparator, variant: variant)
        
        backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextBackground, variant: variant)
        separator.backgroundColor = separatorColor
        guestIconView.image = UIImage(for: .person, iconSize: .tiny, color: separatorColor)
        accessoryActionButton.setIconColor(separatorColor, for: .normal)
        titleLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: variant)
        subtitleLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSectionText, variant: variant)
    }
    
    public func configure(with user: ZMUser) {
        avatar.user = user
        titleLabel.attributedText = user.nameIncludingAvailability(color: UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: variant))
        guestIconView.isHidden = !ZMUser.selfUser().isTeamMember || user.isTeamMember
        
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
