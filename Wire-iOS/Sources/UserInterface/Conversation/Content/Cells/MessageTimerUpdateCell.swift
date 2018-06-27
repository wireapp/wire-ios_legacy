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
        leftIconView.image = UIImage(for: .hourglass, fontSize: 16, color: labelTextColor)
        updateLabel()
    }
    
    func updateLabel() {
        guard let systemMessageData = message.systemMessageData,
        systemMessageData.systemMessageType == .messageTimerUpdate,
        let timer = systemMessageData.messageTimer,
        let labelFont = labelFont,
        let labelBoldFont = labelBoldFont,
        let labelTextColor = labelTextColor,
        let user = systemMessageData.users.first
            else { return }
        
        let timeoutValue = MessageDestructionTimeoutValue(rawValue: timer.doubleValue)
        
        guard let displayString = timeoutValue.displayString,
            let name = (user.isSelfUser ? "content.system.you_started".localized : user.name)
            else { return }
        
        let timerString = "\(displayString)".replacingOccurrences(of: String.breakingSpace,
                                                                  with: String.nonBreakingSpace)
        let string = ("content.system.message_timer_changes".localized(args: name, timerString) && labelFont && labelTextColor)
                .addAttributes([.font: labelBoldFont], toSubstring: name)
                .addAttributes([.font: labelBoldFont], toSubstring: "\(timerString)")
            
        attributedText = string
        lineView.isHidden = true
    }

}

public extension String {
    static let breakingSpace = " "          // classic whitespace
    static let nonBreakingSpace = "\u{00A0}" // &#160;
}
