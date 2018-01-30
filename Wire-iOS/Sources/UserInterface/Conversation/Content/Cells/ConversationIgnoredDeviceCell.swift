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
import TTTAttributedLabel

class ConversationIgnoredDeviceCell : IconSystemCell {
    fileprivate static let deviceListLink = URL(string:"setting://device-list")!
    
    override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        
        self.leftIconView.image = WireStyleKit.imageOfShieldnotverified()
        
        self.updateLabel()
    }
    
    func updateLabel() {
        if let systemMessageData = message.systemMessageData,
            let labelFont = self.labelFont,
            let labelBoldFont = self.labelBoldFont,
            let labelTextColor = self.labelTextColor
            , systemMessageData.systemMessageType == ZMSystemMessageType.ignoredClient && systemMessageData.users.count > 0 {
                
                guard let user = systemMessageData.users.first else { return }
                
                let youString = "content.system.you_started".localized
                let deviceString : String
                
                if user.isSelfUser {
                    deviceString = "content.system.your_devices".localized
                } else {
                    deviceString = String(format: "content.system.other_devices".localized, user.displayName)
                }
                
                let baseString = "content.system.unverified".localized
                let endResult = String(format: baseString, youString, deviceString)

                let youRange = (endResult as NSString).range(of: youString)
                let deviceRange = (endResult as NSString).range(of: deviceString)

                let attributedString = NSMutableAttributedString(string: endResult)
                attributedString.addAttributes([NSFontAttributeName: labelFont, NSForegroundColorAttributeName: labelTextColor], range:NSRange(location: 0, length: endResult.count))
                attributedString.addAttributes([NSFontAttributeName: labelBoldFont, NSForegroundColorAttributeName: labelTextColor], range: youRange)
                attributedString.addAttributes([NSFontAttributeName: labelFont, NSLinkAttributeName: type(of: self).deviceListLink], range: deviceRange)
                
                attributedText = NSAttributedString(attributedString: attributedString)
        }
    }
    
    // MARK: - TTTAttributedLabelDelegate
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWithURL URL: Foundation.URL!) {
        if URL == type(of: self).deviceListLink {
            if let systemMessageData = message.systemMessageData,
                let users = systemMessageData.users,
                let firstUserClient = users.first
            {
                ZClientViewController.shared()?.openClientListScreen(for: firstUserClient)
            }
        }
    }

}
