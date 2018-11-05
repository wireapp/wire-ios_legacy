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


@objcMembers class MissingMessagesCell: IconSystemCell {
    static fileprivate let userClientLink: URL = URL(string: "settings://user-client")!

    fileprivate let exclamationColor = UIColor.vividRed
    
    override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        leftIconView.image = UIImage(for: .exclamationMark, fontSize: 16, color: exclamationColor)
        updateLabel()
    }
    
    func updateLabel() {
        guard let systemMessageData = message.systemMessageData,
            let labelTextColor = labelTextColor
        else { return }
        
        if systemMessageData.systemMessageType == .potentialGap {
            configureForMissingMessages(systemMessageData, font: labelFont, boldFont: labelBoldFont, color: labelTextColor)
        } else if systemMessageData.systemMessageType == .reactivatedDevice {
            configureForReactivatedClientOfSelfUser(labelFont, color: labelTextColor)
        }
    }
    
    
    func configureForMissingMessages(_ systemMessageData: ZMSystemMessageData, font: UIFont, boldFont: UIFont, color: UIColor) {
        let attributedLocalizedUppercaseString: (String, _ users: Set<ZMUser>) -> NSAttributedString? = { localizationKey, users in
            guard users.count > 0 else { return nil }
            let userNames = users.map { $0.displayName }.joined(separator: ", ")
            let string = localizationKey.localized(args: userNames + " ", users.count) + ". "
                && font && color
            return string.addAttributes([.font: boldFont], toSubstring: userNames)
        }
        
        var title = "content.system.missing_messages.title".localized && font && color
        
        // We only want to display the subtitle if we have the final added and removed users and either one is not empty
        let addedOrRemovedUsers = !systemMessageData.addedUsers.isEmpty || !systemMessageData.removedUsers.isEmpty
        if !systemMessageData.needsUpdatingUsers && addedOrRemovedUsers {
            title += "\n\n" + "content.system.missing_messages.subtitle_start".localized + " " && font && color
            title += attributedLocalizedUppercaseString("content.system.missing_messages.subtitle_added", systemMessageData.addedUsers)
            title += attributedLocalizedUppercaseString("content.system.missing_messages.subtitle_removed", systemMessageData.removedUsers)
        }
        
        attributedText = title
    }

    func configureForReactivatedClientOfSelfUser(_ font: UIFont, color: UIColor){
        let deviceString = NSLocalizedString("content.system.this_device", comment: "")
        let fullString  = String(format: NSLocalizedString("content.system.reactivated_device", comment: ""), deviceString) && font && color
        
        attributedText = fullString.setAttributes([.link: type(of: self).userClientLink as AnyObject, .font: font], toSubstring: deviceString)
    }
    
    // MARK: - TTTAttributedLabelDelegate
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWithURL URL: Foundation.URL!) {
        if URL == type(of: self).userClientLink {
            if let systemMessageData = message.systemMessageData,
                let user = systemMessageData.users.first , systemMessageData.users.count == 1 {
                ZClientViewController.shared()?.openClientListScreen(for: user)
            } else if let conversation = message.conversation {
                ZClientViewController.shared()?.openDetailScreen(for: conversation)
            }
        }
    }
}
