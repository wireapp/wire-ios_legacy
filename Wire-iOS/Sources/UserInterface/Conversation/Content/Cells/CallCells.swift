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


struct CallCellViewModel {

    let icon: ZetaIconType
    let iconColor: ZMAccentColor
    let systemMessageType: ZMSystemMessageType
    let font, boldFont: UIFont?
    let textColor: UIColor?
    let message: ZMConversationMessage

    func image() -> UIImage {
        return UIImage(for: icon, iconSize: .tiny, color: UIColor(for: iconColor))
    }

    func attributedTitle() -> NSAttributedString? {
        guard let systemMessageData = message.systemMessageData,
            let sender = message.sender,
            let labelFont = font,
            let labelBoldFont = boldFont,
            let labelTextColor = textColor,
            systemMessageData.systemMessageType == systemMessageType
            else { return nil }

        let senderString = string(for: sender)
        let called = key(with: "called").localized(args:  senderString) && labelFont
        var title = called.adding(font: labelBoldFont, to: senderString)

        if systemMessageData.childMessages.count > 0 {
            title += " (\(systemMessageData.childMessages.count + 1))" && labelFont
        }

        return title && labelTextColor
    }

    private func string(for user: ZMUser) -> String {
        return user.isSelfUser ? key(with: "you").localized : user.displayName
    }

    private func key(with component: String) -> String {
        return "content.system.call.\(component)"
    }

}


class MissedCallCell: IconSystemCell {
    
    override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        let model = CallCellViewModel(
            icon: .endCall,
            iconColor: .vividRed,
            systemMessageType: .missedCall,
            font: labelFont,
            boldFont: labelBoldFont,
            textColor: labelTextColor,
            message: message
        )
        leftIconView.image = model.image()
        labelView.attributedText = model.attributedTitle()
        lineView.isHidden = true
    }

    override func update(forMessage changeInfo: MessageChangeInfo!) -> Bool {
        let updated = super.update(forMessage: changeInfo)
        guard changeInfo.childMessagesChanged else { return updated }
        configure(for: changeInfo.message, layoutProperties: layoutProperties)
        return true
    }

}


class PerformedCallCell: IconSystemCell {

    static var callDurationFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }

    override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        let model = CallCellViewModel(
            icon: .callAudio,
            iconColor: .strongLimeGreen,
            systemMessageType: .performedCall,
            font: labelFont,
            boldFont: labelBoldFont,
            textColor: labelTextColor,
            message: message
        )
        leftIconView.image = model.image()
        labelView.attributedText = model.attributedTitle()
        lineView.isHidden = true
    }

    override func update(forMessage changeInfo: MessageChangeInfo!) -> Bool {
        let updated = super.update(forMessage: changeInfo)
        guard changeInfo.childMessagesChanged else { return updated }
        configure(for: changeInfo.message, layoutProperties: layoutProperties)
        return true
    }

}
