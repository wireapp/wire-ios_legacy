////
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

public extension ConversationCell {

    private enum TextKind {
        case userName(accent: UIColor)
        case botName
        case botSuffix

        var color: UIColor {
            switch self {
            case let .userName(accent: accent):
                return accent
            case .botName:
                return UIColor.from(scheme: .textForeground)
            case .botSuffix:
                return UIColor.from(scheme: .textDimmed)
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

    @objc(updateSenderAndSenderImage:)
    func updateSenderAndImage(_ message: ZMConversationMessage) {
        guard let sender = message.sender, let conversation = message.conversation else { return }
        let name = sender.displayName(in: conversation)

        var attributedString: NSAttributedString
        if sender.isServiceUser {
            let attachment = NSTextAttachment()
            let botIcon = UIImage(for: .bot, iconSize: .like, color: UIColor.from(scheme: .iconGuest, variant: ColorScheme.default.variant))!
            attachment.image = botIcon
            attachment.bounds = CGRect(x: 0.0, y: -1.5, width: botIcon.size.width, height: botIcon.size.height)
            attachment.accessibilityLabel = "general.service".localized
            let bot = NSAttributedString(attachment: attachment)
            let name = attributedName(for: .botName, string: name)
            attributedString = name + "  ".attributedString + bot
        } else {
            let accentColor = ColorScheme.default.nameAccent(for: sender.accentColorValue, variant: ColorScheme.default.variant)
            attributedString = attributedName(for: .userName(accent: accentColor), string: name)
        }

        authorLabel.attributedText = attributedString
        authorImageView.user = sender
    }

    private func attributedName(for kind: TextKind, string: String) -> NSAttributedString {
        return NSAttributedString(string: string, attributes: [.foregroundColor : kind.color, .font : kind.font])
    }
}
