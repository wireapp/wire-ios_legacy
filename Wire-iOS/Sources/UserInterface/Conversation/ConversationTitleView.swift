//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireDataModel

final class ConversationTitleView: TitleView {
    var conversation: ConversationLike
    var interactive: Bool = true

    init(conversation: ConversationLike, interactive: Bool = true) {
        self.conversation = conversation
        self.interactive = interactive
        super.init()
        configure()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        titleColor = SemanticColors.Label.textDefault
        titleFont = .normalSemiboldFont
        accessibilityHint = "conversation_details.open_button.accessibility_hint".localized

        var attachments: [NSTextAttachment] = []

        if conversation.isUnderLegalHold {
            attachments.append(.legalHold())
        }

        if conversation.securityLevel == .secure {
            attachments.append(.verifiedShield())
        }

        var subtitle: String?
        if conversation.conversationType == .oneOnOne,
           let user = conversation.connectedUserType,
           user.isFederated {
            subtitle = user.handleDisplayString(withDomain: true)
        }

        super.configure(icons: attachments,
                        title: conversation.displayName.capitalized,
                        subtitle: subtitle,
                        interactive: self.interactive && conversation.relatedConnectionState != .sent)

        setupAccessibility()
    }

    private func setupAccessibility() {
        typealias Conversation = L10n.Accessibility.Conversation

        accessibilityTraits = .button

        var components: [String] = []
        components.append(conversation.displayName.capitalized)

        if conversation.securityLevel == .secure {
            components.append(Conversation.VerifiedIcon.description)
        }

        if conversation.isUnderLegalHold {
            components.append(Conversation.LegalHoldIcon.description)
        }

        if !UIApplication.isLeftToRightLayout {
            components.reverse()
        }

        accessibilityLabel = components.joined(separator: ", ")

        accessibilityHint = conversation.conversationType == .oneOnOne
                            ? Conversation.TitleViewForOneToOne.hint
                            : Conversation.TitleViewForGroup.hint

    }

}

extension NSTextAttachment {
    static func verifiedShield() -> NSTextAttachment {
        let attachment = NSTextAttachment()
        let shield = WireStyleKit.imageOfShieldverified
        attachment.image = shield
        let ratio = shield.size.width / shield.size.height
        let height: CGFloat = 12
        attachment.bounds = CGRect(x: 0, y: -2, width: height * ratio, height: height)
        return attachment
    }

    static func legalHold() -> NSTextAttachment {
        let attachment = NSTextAttachment()
        let legalHold = StyleKitIcon.legalholdactive.makeImage(size: .tiny, color: SemanticColors.LegacyColors.vividRed)
        attachment.image = legalHold
        let ratio = legalHold.size.width / legalHold.size.height
        let height: CGFloat = 12
        attachment.bounds = CGRect(x: 0, y: -2, width: height * ratio, height: height)
        return attachment
    }
}
