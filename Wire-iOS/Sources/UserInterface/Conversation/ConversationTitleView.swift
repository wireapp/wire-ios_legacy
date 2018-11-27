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
import Cartography

class ConversationTitleView: TitleView {
    var conversation: ZMConversation
    var interactive: Bool = true
    
    @objc init(conversation: ZMConversation, interactive: Bool = true) {
        self.conversation = conversation
        self.interactive = interactive
        super.init()
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func configure() {
        titleColor = UIColor.from(scheme: .textForeground)
        titleColorSelected = UIColor.from(scheme: .textDimmed)
        titleFont = FontSpec(.medium, .semibold).font!
        
        var attachment : NSTextAttachment?
        if conversation.securityLevel == .secure {
            attachment = .verifiedShield()
        }
        super.configure(icon: attachment,
                        title: conversation.displayName.uppercased(),
                        interactive: self.interactive && conversation.relatedConnectionState != .sent)
    }

    override func updateAccessibilityLabel() {
        if conversation.securityLevel == .secure {
            self.accessibilityLabel = conversation.displayName.uppercased() + ", " + "conversation.voiceover.verified".localized
        } else {
            self.accessibilityLabel = conversation.displayName.uppercased()
        }
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
}

