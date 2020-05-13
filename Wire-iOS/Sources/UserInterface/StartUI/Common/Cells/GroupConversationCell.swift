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
import WireDataModel
import UIKit

class GroupConversationCell: UICollectionViewCell, Themeable {
    
    let avatarSpacer = UIView()
    let avatarView = ConversationAvatarView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let separator = UIView()
    var contentStackView : UIStackView!
    var titleStackView : UIStackView!
    
    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }
    
    // if nil the background color is the default content background color for the theme
    @objc dynamic var contentBackgroundColor: UIColor? = nil {
        didSet {
            guard oldValue != contentBackgroundColor else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .init(white: 0, alpha: 0.08) : .clear
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
    
    fileprivate func contentBackgroundColor(for colorSchemeVariant: ColorSchemeVariant) -> UIColor {
        return contentBackgroundColor ?? UIColor.from(scheme: .barBackground, variant: colorSchemeVariant)
    }
    
    fileprivate func setup() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSpec.init(.normal, .light).font!
        titleLabel.accessibilityIdentifier = "user_cell.name"
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = FontSpec.init(.small, .regular).font!
        subtitleLabel.accessibilityIdentifier = "user_cell.username"
        
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        
        avatarSpacer.addSubview(avatarView)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false

        titleStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStackView.axis = .vertical
        titleStackView.distribution = .equalSpacing
        titleStackView.alignment = .leading
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentStackView = UIStackView(arrangedSubviews: [avatarSpacer, titleStackView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(contentStackView)
        contentView.addSubview(separator)
        
        applyColorScheme(colorSchemeVariant)
        createConstraints()
    }
    
    func createConstraints() {
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 28),
            avatarView.heightAnchor.constraint(equalToConstant: 28),
            avatarSpacer.widthAnchor.constraint(equalToConstant: 64),
            avatarSpacer.heightAnchor.constraint(equalTo: avatarView.heightAnchor),
            avatarSpacer.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarSpacer.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
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
        let sectionTextColor = UIColor.from(scheme: .sectionText, variant: colorSchemeVariant)
        backgroundColor = contentBackgroundColor(for: colorSchemeVariant)
        separator.backgroundColor = UIColor.from(scheme: .cellSeparator, variant: colorSchemeVariant)
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        subtitleLabel.textColor = sectionTextColor
    }
    
    public func configure(conversation: ZMConversation) {
        avatarView.configure(context: .conversation(conversation: conversation))

        titleLabel.text = conversation.displayName
        
        if conversation.conversationType == .oneOnOne, let handle = conversation.connectedUser?.handle {
            subtitleLabel.isHidden = false
            subtitleLabel.text = "@\(handle)"
        } else {
            subtitleLabel.isHidden = true
        }
    }
    
}
