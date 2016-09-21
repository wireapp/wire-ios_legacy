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

class ConversationNewDeviceCell: IconSystemCell {
    static fileprivate let userClientLink: URL = URL(string: "settings://user-client")!
    
    override func configureForMessage(_ message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configureForMessage(message, layoutProperties: layoutProperties)
        
        self.leftIconView.image = WireStyleKit.imageOfShieldnotverified()
        
        self.updateLabel()
    }
    
    struct TextAttributes {
        let senderAttributes : [String: AnyObject]
        let startedUsingAttributes : [String: AnyObject]
        let linkAttributes : [String: AnyObject]
        
        init(boldFont: UIFont, normalFont: UIFont, textColor: UIColor, link: URL) {
            senderAttributes = [NSFontAttributeName: boldFont, NSForegroundColorAttributeName: textColor]
            startedUsingAttributes = [NSFontAttributeName: normalFont, NSForegroundColorAttributeName: textColor]
            linkAttributes = [NSFontAttributeName: normalFont, NSLinkAttributeName: link as AnyObject]
        }
    }
    
    func updateLabel() {
        guard let systemMessageData = message.systemMessageData,
            let clients = message.systemMessageData?.clients.flatMap ({ $0 as? UserClientType }),
            let labelFont = self.labelFont,
            let labelBoldFont = self.labelBoldFont,
            let labelTextColor = self.labelTextColor
            , systemMessageData.users.count > 0 && (systemMessageData.systemMessageType == .NewClient || systemMessageData.systemMessageType == .UsingNewDevice)
            else { return }
        
        let textAttributes = TextAttributes(boldFont: labelBoldFont, normalFont: labelFont, textColor: labelTextColor, link: type(of: self).userClientLink)
        
        let users = systemMessageData.users.sort({ (a: ZMUser, b: ZMUser) -> Bool in
            a.displayName.compare(b.displayName) == NSComparisonResult.OrderedAscending
        })
        
        if let user = users.first , user.isSelfUser && systemMessageData.systemMessageType == .UsingNewDevice {
            configureForNewCurrentDeviceOfSelfUser(user, attributes: textAttributes)
        }
        else if users.count == 1, let user = users.first , user.isSelfUser {
            configureForNewClientOfSelfUser(user, clients: clients, attributes: textAttributes)
        } else {
            configureForOtherUsers(users, clients: clients, attributes: textAttributes)
        }
        
        self.labelView.addLinks()
        self.labelView.accessibilityLabel = self.labelView.attributedText.string
    }
    
    
    func configureForNewClientOfSelfUser(_ selfUser: ZMUser, clients: [UserClientType], attributes: TextAttributes){
        let isSelfClient = clients.first?.isEqual(ZMUserSession.sharedSession().selfUserClient()) ?? false
        
        let senderName = NSLocalizedString("content.system.you_started", comment: "").uppercased() && attributes.senderAttributes
        let startedUsingString = NSLocalizedString("content.system.started_using", comment: "").uppercased() && attributes.startedUsingAttributes
        let userClientString = NSLocalizedString("content.system.new_device", comment: "").uppercased() && attributes.linkAttributes
        
        self.labelView.attributedText = senderName + " " + startedUsingString + " " + userClientString
        self.leftIconView.hidden = isSelfClient
    }
    
    func configureForNewCurrentDeviceOfSelfUser(_ selfUser: ZMUser, attributes: TextAttributes){
        let senderName = NSLocalizedString("content.system.you_started", comment: "").uppercased() && attributes.senderAttributes
        let startedUsingString = NSLocalizedString("content.system.started_using", comment: "").uppercased() && attributes.startedUsingAttributes
        let userClientString = NSLocalizedString("content.system.this_device", comment: "").uppercased() && attributes.linkAttributes
        
        self.labelView.attributedText = senderName + " " + startedUsingString + " " + userClientString
        self.leftIconView.isHidden = true
    }
    
    func configureForOtherUsers(_ users: [ZMUser], clients: [UserClientType], attributes: TextAttributes) {
        let displayNamesOfOthers = users.filter {!$0.isSelfUser }.flatMap {$0.displayName as String}
        guard displayNamesOfOthers.count > 0 else { return }
        
        let firstTwoNames = displayNamesOfOthers.prefix(2)
        let senderNames = firstTwoNames.joinWithSeparator(", ").uppercaseString
        let additionalSenderCount = max(displayNamesOfOthers.count - 1, 1)
    
        // %@ %#@d_number_of_others@ started using %#@d_new_devices@
        let senderNamesString = NSString(format: NSLocalizedString("content.system.people_started_using", comment: ""),
                                         senderNames,
                                         additionalSenderCount,
                                         clients.count).uppercaseString as String
        
        let userClientString = NSString(format: NSLocalizedString("content.system.new_devices", comment: ""), clients.count).uppercaseString as String
        
        var attributedSenderNames = NSAttributedString(string: senderNamesString, attributes: attributes.startedUsingAttributes)
        attributedSenderNames = attributedSenderNames.setAttributes(attributes.senderAttributes, toSubstring: senderNames)
        attributedSenderNames = attributedSenderNames.setAttributes(attributes.linkAttributes, toSubstring: userClientString)
        
        self.labelView.attributedText = attributedSenderNames
        self.leftIconView.isHidden = false
    }
    
    
    // MARK: - TTTAttributedLabelDelegate
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWithURL URL: Foundation.URL!) {
        if URL.isEqual(type(of: self).userClientLink) {
            if let systemMessageData = message.systemMessageData,
                let user = systemMessageData.users.first , systemMessageData.users.count == 1 {
                    ZClientViewController.sharedZClientViewController().openClientListScreenForUser(user)
            } else if let conversation = message.conversation {
                ZClientViewController.sharedZClientViewController().openDetailScreenForConversation(conversation)
            }
        }
    }
}
