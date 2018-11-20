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

private enum TextKind {
    case userName(accent: UIColor)
    case botName
    case botSuffix
    
    var color: UIColor {
        switch self {
        case let .userName(accent: accent):
            return accent
        case .botName:
            return .from(scheme: .textForeground)
        case .botSuffix:
            return .from(scheme: .textDimmed)
        }
    }
    
    var font: UIFont {
        switch self {
        case .userName, .botName:
            return FontSpec(.medium, .semibold).font!
        case .botSuffix:
            return FontSpec(.medium, .regular).font!
        }
    }
}

class SenderCellComponent: UIView {
    
    let avatarSpacer = UIView()
    let avatar = UserImageView()
    let authorLabel = UILabel()
    var stackView: UIStackView!
    var avatarSpacerWidthConstraint: NSLayoutConstraint?
    
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
        let avatarSpacerWidthConstraint = avatarSpacer.widthAnchor.constraint(equalToConstant: UIView.conversationLayoutMargins.left)
        self.avatarSpacerWidthConstraint = avatarSpacerWidthConstraint
        
        NSLayoutConstraint.activate([
            avatarSpacerWidthConstraint,
            avatarSpacer.heightAnchor.constraint(equalTo: avatar.heightAnchor),
            avatarSpacer.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarSpacer.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ])
    }
    
    func configure(with user: UserType) {
        let displayName =  user.displayName // TODO jacob should be displayName(in: conversation but it's not exposed on UserType)
        
        var attributedString: NSAttributedString
        if user.isServiceUser {
            let attachment = NSTextAttachment()
            let botIcon = UIImage(for: .bot, iconSize: .like, color: UIColor.from(scheme: .iconGuest))!
            attachment.image = botIcon
            attachment.bounds = CGRect(x: 0.0, y: -1.5, width: botIcon.size.width, height: botIcon.size.height)
            attachment.accessibilityLabel = "general.service".localized
            let bot = NSAttributedString(attachment: attachment)
            let name = attributedName(for: .botName, string: displayName)
            attributedString = name + "  ".attributedString + bot
        } else {
            let accentColor = ColorScheme.default.nameAccent(for: user.accentColorValue, variant: ColorScheme.default.variant)
            attributedString = attributedName(for: .userName(accent: accentColor), string: displayName)
        }
        
        avatar.user = user
        authorLabel.attributedText = attributedString
    }

    func prepareForReuse() {
        avatar.user = nil
        authorLabel.attributedText = nil
    }
    
    private func attributedName(for kind: TextKind, string: String) -> NSAttributedString {
        return NSAttributedString(string: string, attributes: [.foregroundColor : kind.color, .font : kind.font])
    }
    
}
