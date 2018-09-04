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
import UIKit

class MessageTimerUpdateCell: IconSystemCell {
    
    override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        leftIconView.image = UIImage(for: .hourglass, fontSize: 16, color: UIColor(scheme: .textDimmed))
        updateLabel()
    }
    
    func updateLabel() {
        guard let systemMessageData = message.systemMessageData,
            systemMessageData.systemMessageType == .messageTimerUpdate,
            let timer = systemMessageData.messageTimer,
            let labelTextColor = labelTextColor,
            let sender = systemMessageData.users.first else { return }

        lineView.isHidden = true
        let name = sender.displayName
        let youString = "content.system.message_timer.you_part".localized
        let timeoutValue = MessageDestructionTimeoutValue(rawValue: timer.doubleValue)
        let boldAttributes: [NSAttributedStringKey: AnyObject] = [.font: labelBoldFont]
        
        if timeoutValue == .none {
            if sender.isSelfUser {
                attributedText = ("content.system.message_timer_off.you".localized && labelFont && labelTextColor)
                    .addAttributes(boldAttributes, toSubstring: youString)
            } else {
                attributedText = ("content.system.message_timer_off".localized(args: name) && labelFont && labelTextColor)
                    .addAttributes(boldAttributes, toSubstring: name)
            }
        } else if let displayString = timeoutValue.displayString {
            let timerString = displayString.replacingOccurrences(of: String.breakingSpace, with: String.nonBreakingSpace)
            if sender.isSelfUser {
                attributedText = ("content.system.message_timer_changes.you".localized(args: timerString) && labelFont && labelTextColor)
                    .addAttributes(boldAttributes, toSubstring: youString)
                    .addAttributes(boldAttributes, toSubstring: timerString)
            } else {
                attributedText = ("content.system.message_timer_changes".localized(args: name, timerString) && labelFont && labelTextColor)
                    .addAttributes(boldAttributes, toSubstring: name)
                    .addAttributes(boldAttributes, toSubstring: timerString)
            }
        }
    }
}

public extension String {
    static let breakingSpace = " "           // classic whitespace
    static let nonBreakingSpace = "\u{00A0}" // &#160;
}
