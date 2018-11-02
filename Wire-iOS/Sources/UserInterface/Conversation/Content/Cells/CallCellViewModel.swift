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


import Foundation
import Cartography
import WireExtensionComponents

struct CallCellViewModel {

    let icon: ZetaIconType
    let iconColor: UIColor?
    let systemMessageType: ZMSystemMessageType
    let font, boldFont: UIFont?
    let textColor: UIColor?
    let message: ZMConversationMessage
    
    func image() -> UIImage? {
        return iconColor.map { UIImage(for: icon, iconSize: .tiny, color: $0) }
    }

    func attributedTitle() -> NSAttributedString? {
        guard let systemMessageData = message.systemMessageData,
            let sender = message.sender,
            let labelFont = font,
            let labelBoldFont = boldFont,
            let labelTextColor = textColor,
            systemMessageData.systemMessageType == systemMessageType
            else { return nil }

        let senderString = string(for: sender)
        
        var called = NSAttributedString()
        let childs = systemMessageData.childMessages.count
        
        if systemMessageType == .missedCall {
            
            var detailKey = "missed-call"
            
            if message.conversation?.conversationType == .group {
                detailKey.append(".groups")
            }
            
            called = key(with: detailKey).localized(pov: sender.pov, args: childs + 1, senderString) && labelFont
        } else {
            called = key(with: "called").localized(pov: sender.pov, args: senderString) && labelFont
        }
        
        var title = called.adding(font: labelBoldFont, to: senderString)

        if childs > 0 {
            title += " (\(childs + 1))" && labelFont
        }

        return title && labelTextColor
    }

    private func string(for user: ZMUser) -> String {
        return user.isSelfUser ? key(with: "you").localized : user.displayName
    }

    private func key(with component: String) -> String {
        return "content.system.call.\(component)"
    }
}
