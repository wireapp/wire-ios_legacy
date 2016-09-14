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


class MissingMessagesCell: IconSystemCell {
    static private let userClientLink: NSURL = NSURL(string: "settings://user-client")!

    private let exclamationColor = UIColor(forZMAccentColor: .VividRed)
    
    override func configureForMessage(message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configureForMessage(message, layoutProperties: layoutProperties)
        leftIconView.image = UIImage(forIcon: .ExclamationMark, fontSize: 16, color: exclamationColor)
        updateLabel()
    }
    
    func updateLabel() {
        guard let systemMessageData = message.systemMessageData,
            labelFont = labelFont,
            labelBoldFont = labelBoldFont,
            labelTextColor = labelTextColor
        else { return }
        
        if systemMessageData.systemMessageType == .PotentialGap {
            configureForMissingMessages(systemMessageData, font: labelFont, boldFont: labelBoldFont, color: labelTextColor)
        } else if systemMessageData.systemMessageType == .ReactivatedDevice {
            configureForReactivatedClientOfSelfUser(labelFont, color: labelTextColor)
        }
        
        if let attributedString = self.labelView.attributedText {
            self.labelView.accessibilityLabel = attributedString.string
        }
    }
    
    
    func configureForMissingMessages(systemMessageData: ZMSystemMessageData, font: UIFont, boldFont: UIFont, color: UIColor) {
        let attributedLocalizedUppercaseString: (String, users: Set<ZMUser>) -> NSAttributedString? = { localizationKey, users in
            guard users.count > 0 else { return nil }
            let userNames = users.map { $0.displayName }.joinWithSeparator(", ")
            let string = localizationKey.localized(args: userNames + " ", users.count).uppercaseString + ". "
                && font && color
            return string.addAttributes([NSFontAttributeName: boldFont], toSubstring: userNames.uppercaseString)
        }
        
        var title = "content.system.missing_messages.title".localized.uppercaseString && font && color
        
        // We only want to display the subtitle if we have the final added and removed users and either one is not empty
        let addedOrRemovedUsers = !systemMessageData.addedUsers.isEmpty || !systemMessageData.removedUsers.isEmpty
        if !systemMessageData.needsUpdatingUsers && addedOrRemovedUsers {
            title += "\n\n" + "content.system.missing_messages.subtitle_start".localized.uppercaseString + " " && font && color
            title += attributedLocalizedUppercaseString("content.system.missing_messages.subtitle_added", users: systemMessageData.addedUsers)
            title += attributedLocalizedUppercaseString("content.system.missing_messages.subtitle_removed", users: systemMessageData.removedUsers)
        }
        
        self.labelView.attributedText = title
    }
    
    
    func configureForReactivatedClientOfSelfUser(font: UIFont, color: UIColor){
        let deviceString = NSLocalizedString("content.system.this_device", comment: "").uppercaseString
        var fullString  = NSString(format: NSLocalizedString("content.system.reactivated_device", comment: ""), deviceString).uppercaseString && font && color
        
        fullString = fullString.setAttributes([NSLinkAttributeName: self.dynamicType.userClientLink, NSFontAttributeName: font], toSubstring: deviceString)
        
        self.labelView.attributedText = fullString
        self.labelView.addLinks()
    }
    
    // MARK: - TTTAttributedLabelDelegate
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL URL: NSURL!) {
        if URL.isEqual(self.dynamicType.userClientLink) {
            if let systemMessageData = message.systemMessageData,
                let user = systemMessageData.users.first where systemMessageData.users.count == 1 {
                ZClientViewController.sharedZClientViewController().openClientListScreenForUser(user)
            } else if let conversation = message.conversation {
                ZClientViewController.sharedZClientViewController().openDetailScreenForConversation(conversation)
            }
        }
    }
}
