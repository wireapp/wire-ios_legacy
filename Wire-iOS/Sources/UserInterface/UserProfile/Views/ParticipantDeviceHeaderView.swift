
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension ParticipantDeviceHeaderView {
    
    //MARK: Attributed Text
    
    @objc(attributedExplanationTextForUserName:showUnencryptedLabel:)
    func attributedExplanationText(for userName: String,
                                   showUnencryptedLabel unencrypted: Bool) -> NSAttributedString? {
        if unencrypted {
            let message = "profile.devices.fingerprint_message_unencrypted".localized
            return attributedFingerprint(forUserName: userName, message: message)
        } else {
            let message = "\("profile.devices.fingerprint_message.title".localized)\("general.space_between_words".localized)"
            
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedFingerprint(forUserName: userName, message: message))
            
            let fingerprintLearnMoreLink = "profile.devices.fingerprint_message.link".localized && linkAttributes
            
            return mutableAttributedString + fingerprintLearnMoreLink
        }
    }
    
    func attributedFingerprint(forUserName userName: String, message: String) -> NSAttributedString {
        let fingerprintExplanation = String(format: message, userName)
        
        let textAttributes = [
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: paragraphStyleForFingerprint
        ]
        
        return NSAttributedString(string: fingerprintExplanation, attributes: textAttributes)
    }
    
    
    var linkAttributes: [NSAttributedString.Key : Any] {
        return [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: linkAttributeColor,
            NSAttributedString.Key.link: NSURL.wr_fingerprintLearnMoreURL,
            NSAttributedString.Key.paragraphStyle: paragraphStyleForFingerprint
        ]
    }
    
    var paragraphStyleForFingerprint: NSMutableParagraphStyle {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineSpacing = 2
        
        return paragraphStyle
    }
    
}
