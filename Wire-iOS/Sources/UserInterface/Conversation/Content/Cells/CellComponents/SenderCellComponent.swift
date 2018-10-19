//
//  SenderCellComponent.swift
//  Wire-iOS
//
//  Created by Jacob Persson on 19.10.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
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
            return UIColor(scheme: .textForeground)
        case .botSuffix:
            return UIColor(scheme: .textDimmed)
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
        
        avatar.userSession = ZMUserSession.shared()
        avatar.initials.font = .avatarInitial
        avatar.size = .small
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
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -UIView.conversationLayoutMargins.right),
            ])
    }
    
    func configure(with user: UserType) {
        let displayName =  user.displayName // TODO jacob should be displayName(in: conversation but it's not exposed on UserType)
        
        var attributedString: NSAttributedString
        if user.isServiceUser {
            let attachment = NSTextAttachment()
            let botIcon = UIImage(for: .bot, iconSize: .like, color: UIColor(scheme: .iconGuest, variant: ColorScheme.default.variant))!
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
    
    private func attributedName(for kind: TextKind, string: String) -> NSAttributedString {
        return string.attributedString.addAttributes([.foregroundColor : kind.color, .font : kind.font], toSubstring: string)
    }
    
}
