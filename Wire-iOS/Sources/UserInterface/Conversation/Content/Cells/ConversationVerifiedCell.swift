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


import Foundation

class ConversationVerifiedCell: IconSystemCell {
    override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        
        self.leftIconView.image = WireStyleKit.imageOfShieldverified()
        
        self.updateLabel()
    }
    
    func updateLabel() {
        if let systemMessageData = message.systemMessageData,
            let labelFont = self.labelFont,
            let labelTextColor = self.labelTextColor,
            systemMessageData.systemMessageType == ZMSystemMessageType.conversationIsSecure {
                
                attributedText = (NSLocalizedString("content.system.is_verified", comment: "") && [NSFontAttributeName: labelFont, NSForegroundColorAttributeName: labelTextColor])
        }
    }
}
