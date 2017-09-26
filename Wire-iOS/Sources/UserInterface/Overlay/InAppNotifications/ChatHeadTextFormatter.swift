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
import WireDataModel

class ChatHeadTextFormatter {
    
    /// Returns the formatted title text for the given conversation and account.
    ///
    static func titleText(conversation: ZMConversation, teamName: String?, isAccountActive: Bool) -> NSAttributedString {
        
        let regularFont: [String: AnyObject] = [NSFontAttributeName: FontSpec(.medium, .regular).font!.withSize(14)]
        let mediumFont: [String: AnyObject] = [NSFontAttributeName: FontSpec(.medium, .medium).font!.withSize(14)]
        
        // if team & background account
        if let teamName = teamName, !isAccountActive {
            // "Name in Team"
            let result = NSMutableAttributedString(string: conversation.displayName + " ", attributes: mediumFont)
            result.append(NSMutableAttributedString(string: "in ", attributes: regularFont))
            result.append(NSAttributedString(string: teamName, attributes: mediumFont))
            return result
            
        } else {
            return NSAttributedString(string: conversation.displayName, attributes: mediumFont)
        }
    }

    
    /// Returns the formatted text for the given message and the account state.
    ///
    static func text(for message: ZMConversationMessage, isAccountActive: Bool) -> NSAttributedString {
        var result = ""
        
        if Message.isText(message) {
            
            result = (message.textMessageData!.messageText as NSString).resolvingEmoticonShortcuts() ?? ""
            
            if message.isEphemeral {
                result = result.obfuscated()
            }
            
            if message.conversation?.conversationType == .group {
                if let senderName = message.sender?.displayName {
                    result = "\(senderName): \(result)"
                }
            }
            
        } else if Message.isImage(message) {
            result = "notifications.shared_a_photo".localized
        } else if Message.isKnock(message) {
            result = "notifications.pinged".localized
        } else if Message.isVideo(message) {
            result = "notifications.sent_video".localized
        } else if Message.isAudio(message) {
            result = "notifications.sent_audio".localized
        } else if Message.isFileTransfer(message) {
            result = "notifications.sent_file".localized
        } else if Message.isLocation(message) {
            result = "notifications.sent_location".localized
        }
        
        let attr: [String : AnyObject] = [NSFontAttributeName: font(for: message)]
        return NSAttributedString(string: result, attributes: attr)
    }
    
    
    /// Returns the formatted alert body of the notification if it exists, else nil.
    ///
    static func text(for notification: UILocalNotification) -> NSAttributedString? {
        // use the alert body
        guard let alertBody = notification.alertBody else { return nil }
        return NSAttributedString(string: alertBody, attributes: [NSFontAttributeName: FontSpec(.medium, .regular).font!])
    }
    
    
    /// Returns the appropriate font for the given message.
    ///
    static func font(for message: ZMConversationMessage) -> UIFont {
        let font = FontSpec(.medium, .regular).font!
        
        if message.isEphemeral {
            return UIFont(name: "RedactedScript-Regular", size: font.pointSize)!
        }
        return font
    }
}
