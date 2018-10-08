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

@objcMembers class ConversationNewDeviceCell: IconSystemCell {
    static fileprivate let userClientLink: URL = URL(string: "settings://user-client")!
    
    override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        
        self.leftIconView.image = WireStyleKit.imageOfShieldnotverified
        
        self.updateLabel()
    }
    
    struct TextAttributes {
        let senderAttributes : [NSAttributedString.Key: AnyObject]
        let startedUsingAttributes : [NSAttributedString.Key: AnyObject]
        let linkAttributes : [NSAttributedString.Key: AnyObject]
        
        init(boldFont: UIFont, normalFont: UIFont, textColor: UIColor, link: URL) {
            senderAttributes = [.font: boldFont, .foregroundColor: textColor]
            startedUsingAttributes = [.font: normalFont, .foregroundColor: textColor]
            linkAttributes = [.font: normalFont, .link: link as AnyObject]
        }
    }
    
    func updateLabel() {
        guard let systemMessageData = message.systemMessageData,
            let clients = message.systemMessageData?.clients.compactMap ({ $0 as? UserClientType }),
            let labelTextColor = self.labelTextColor,
            (systemMessageData.users.count > 0 || systemMessageData.addedUsers.count > 0) && (systemMessageData.systemMessageType == .newClient || systemMessageData.systemMessageType == .usingNewDevice)
            else { return }
        
        let textAttributes = TextAttributes(boldFont: labelBoldFont, normalFont: labelFont, textColor: labelTextColor, link: type(of: self).userClientLink)
        
        let users = systemMessageData.users.sorted(by: { (a: ZMUser, b: ZMUser) -> Bool in
            a.displayName.compare(b.displayName) == ComparisonResult.orderedAscending
        })
        
        if !systemMessageData.addedUsers.isEmpty {
            configureForAddedUsers(with: textAttributes)
        }
        else if let user = users.first , user.isSelfUser && systemMessageData.systemMessageType == .usingNewDevice {
            configureForNewCurrentDeviceOfSelfUser(user, attributes: textAttributes)
        }
        else if users.count == 1, let user = users.first , user.isSelfUser {
            configureForNewClientOfSelfUser(user, clients: clients, attributes: textAttributes)
        } else {
            configureForOtherUsers(users, clients: clients, attributes: textAttributes)
        }
    }
    
    func configureForNewClientOfSelfUser(_ selfUser: ZMUser, clients: [UserClientType], attributes: TextAttributes){
        let isSelfClient = clients.first?.isEqual(ZMUserSession.shared()?.selfUserClient()) ?? false
        
        let senderName = NSLocalizedString("content.system.you_started", comment: "") && attributes.senderAttributes
        let startedUsingString = NSLocalizedString("content.system.started_using", comment: "") && attributes.startedUsingAttributes
        let userClientString = NSLocalizedString("content.system.new_device", comment: "") && attributes.linkAttributes
        
        attributedText = senderName + "general.space_between_words".localized + startedUsingString + "general.space_between_words".localized + userClientString
        self.leftIconView.isHidden = isSelfClient
    }
    
    func configureForNewCurrentDeviceOfSelfUser(_ selfUser: ZMUser, attributes: TextAttributes){
        let senderName = NSLocalizedString("content.system.you_started", comment: "") && attributes.senderAttributes
        let startedUsingString = NSLocalizedString("content.system.started_using", comment: "") && attributes.startedUsingAttributes
        let userClientString = NSLocalizedString("content.system.this_device", comment: "") && attributes.linkAttributes
        
        attributedText = senderName + "general.space_between_words".localized + startedUsingString + "general.space_between_words".localized + userClientString
        self.leftIconView.isHidden = true
    }
    
    func configureForOtherUsers(_ users: [ZMUser], clients: [UserClientType], attributes: TextAttributes) {
        let displayNamesOfOthers = users.filter {!$0.isSelfUser }.compactMap {$0.displayName as String}
        guard displayNamesOfOthers.count > 0 else { return }
        
        let firstTwoNames = displayNamesOfOthers.prefix(2)
        let senderNames = firstTwoNames.joined(separator: ", ")
        let additionalSenderCount = max(displayNamesOfOthers.count - 1, 1)
    
        // %@ %#@d_number_of_others@ started using %#@d_new_devices@
        let senderNamesString = NSString(format: NSLocalizedString("content.system.people_started_using", comment: "") as NSString,
                                         senderNames,
                                         additionalSenderCount,
                                         clients.count) as String
        
        let userClientString = NSString(format: NSLocalizedString("content.system.new_devices", comment: "") as NSString, clients.count) as String
        
        var attributedSenderNames = NSAttributedString(string: senderNamesString, attributes: attributes.startedUsingAttributes)
        attributedSenderNames = attributedSenderNames.setAttributes(attributes.senderAttributes, toSubstring: senderNames)
        attributedSenderNames = attributedSenderNames.setAttributes(attributes.linkAttributes, toSubstring: userClientString)
        
        attributedText = attributedSenderNames
        self.leftIconView.isHidden = false
    }
    
    func configureForAddedUsers(with attributes: TextAttributes) {
        let attributedNewUsers = NSAttributedString(string: "content.system.new_users".localized, attributes: attributes.startedUsingAttributes)
        let attributedLink = NSAttributedString(string: "content.system.verify_devices".localized, attributes: attributes.linkAttributes)

        attributedText = attributedNewUsers + " " + attributedLink
        self.leftIconView.isHidden = false
    }
    
    // MARK: - TTTAttributedLabelDelegate
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWithURL URL: Foundation.URL!) {
        if URL == type(of: self).userClientLink {
            if let systemMessageData = message.systemMessageData, !systemMessageData.addedUsers.isEmpty,
               let conversation = message.conversation  {
                ZClientViewController.shared()?.openDetailScreen(for: conversation)
            }
            else if let systemMessageData = message.systemMessageData,
                let user = systemMessageData.users.first, systemMessageData.users.count == 1 {
                    ZClientViewController.shared()?.openClientListScreen(for: user)
            }
            else if let conversation = message.conversation {
                ZClientViewController.shared()?.openDetailScreen(for: conversation)
            }
        }
    }
}
