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

private let BaseLocalizationString = "content.system.cannot_decrypt"
private let IdentityString = ".identity"

class CannotDecryptCell: IconSystemCell {
    static fileprivate let generalErrorURL : URL = URL(string:"action://general-error")!
    static fileprivate let remoteIDErrorURL : URL = URL(string:"action://remote-id-error")!

    fileprivate let exclamationColor = UIColor(for: .vividRed)
    
    override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        leftIconView.image = UIImage(for: .exclamationMark, fontSize: 16, color: exclamationColor)
        updateLabel()
    }
    
    func updateLabel() {
        let acceptedTypes : [ZMSystemMessageType] = [.decryptionFailed, .decryptionFailed_RemoteIdentityChanged]
        guard let systemMessageData = message.systemMessageData,
            let labelBoldFont = labelBoldFont,
            let labelFont = labelFont,
            let labelTextColor = labelTextColor,
            let sender = message.sender,
            let labelTextBlendedColor = labelTextBlendedColor,
            acceptedTypes.contains(systemMessageData.systemMessageType)
        else { return }
        
        let remoteIDChanged = systemMessageData.systemMessageType == .decryptionFailed_RemoteIdentityChanged
        let link = remoteIDChanged ? type(of: self).remoteIDErrorURL : type(of: self).generalErrorURL

        let linkAttributes = [NSFontAttributeName: labelFont, NSLinkAttributeName: link as AnyObject] as [String : AnyObject]
        let name = localizedWhoPart(sender, remoteIDChanged: remoteIDChanged)
        let why = localizedWhyPart(remoteIDChanged) && labelFont && labelTextColor && linkAttributes
        let device : NSAttributedString?
        if DeveloperMenuState.developerMenuEnabled() {
            device = "\n" + localizedDevice(systemMessageData.clients.first as? UserClient) && labelFont && labelTextBlendedColor
        } else {
            device = nil
        }
        let messageString = localizedWhatPart(remoteIDChanged, name: name) && labelFont && labelTextColor
        let fullString = messageString + " " + why + (device ?? NSAttributedString())
        
        labelView.attributedText = fullString.addAttributes([ NSFontAttributeName: labelBoldFont], toSubstring:name)
        labelView.addLink(to: link, with: NSMakeRange(messageString.length+1, why.length))
        labelView.accessibilityLabel = labelView.attributedText?.string
    }
    
    func localizedWhoPart(_ sender: ZMUser, remoteIDChanged: Bool) -> String {
        switch (sender.isSelfUser, remoteIDChanged) {
        case (true, _):
            return (BaseLocalizationString+(remoteIDChanged ? IdentityString : "")+".you_part").localized
        case (false, true):
            return (BaseLocalizationString+IdentityString+".otherUser_part").localized(args: sender.displayName)
        case (false, false):
            return sender.displayName
        }
    }
    
    func localizedWhatPart(_ remoteIDChanged: Bool, name: String) -> String {
        return (BaseLocalizationString+(remoteIDChanged ? IdentityString : "")).localized(args: name)
    }
    
    func localizedWhyPart(_ remoteIDChanged: Bool) -> String {
        return (BaseLocalizationString+(remoteIDChanged ? IdentityString : "")+".why_part").localized
    }
    
    func localizedDevice(_ device: UserClient?) -> String {
        return (BaseLocalizationString+".otherDevice_part").localized(args: device?.remoteIdentifier ?? "-")
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWithURL URL: Foundation.URL!) {
        var url : Foundation.URL!
        if URL == type(of: self).generalErrorURL {
            url = NSURL.wr_cannotDecryptHelp() as URL!
        }
        else if URL == type(of: self).remoteIDErrorURL {
            url = NSURL.wr_cannotDecryptNewRemoteIDHelp() as URL!
        }
        UIApplication.shared.openURL(url)
    }
}

