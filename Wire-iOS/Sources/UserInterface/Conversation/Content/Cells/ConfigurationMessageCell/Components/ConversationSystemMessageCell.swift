//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import UIKit
import TTTAttributedLabel

class ConversationSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    struct Configuration {
        let icon: UIImage?
        let attributedText: NSAttributedString?
        let showLine: Bool
    }

    // MARK: - Configuration

    func configure(with object: Configuration) {
        lineView.isHidden = !object.showLine
        imageView.image = object.icon
        attributedText = object.attributedText
    }

}

class ConversationRenamedSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    struct Configuration {
        let attributedText: NSAttributedString
        let newConversationName: NSAttributedString
    }

    var nameLabelFont: UIFont? = .normalSemiboldFont
    private let nameLabel = UILabel()

    override func configureSubviews() {
        super.configureSubviews()
        nameLabel.numberOfLines = 0
        imageView.image = UIImage(for: .pencil, fontSize: 16, color: .textForeground)
        contentView.addSubview(nameLabel)
    }

    override func configureConstraints() {
        super.configureConstraints()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.fitInSuperview()
    }

    // MARK: - Configuration

    func configure(with object: Configuration) {
        lineView.isHidden = false
        attributedText = object.attributedText
        nameLabel.attributedText = object.newConversationName
        nameLabel.accessibilityLabel = nameLabel.attributedText?.string
    }

}

class ConversationSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var isFullWidth: Bool {
        return true
    }

    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let icon: UIImage = UIImage(for: .pencil, fontSize: 16, color: .textForeground)
        configuration = View.Configuration(icon: icon, attributedText: NSAttributedString(string: "System Message"), showLine: true)

//        switch systemMessage.systemMessageType {
//        case .connectionRequest:
//            cellIdentifier = ConversationConnectionRequestCellId
//        case .connectionUpdate:
//            break
//        case .conversationNameChanged:
//            cellIdentifier = ConversationNameChangedCellId
//        case .missedCall:
//            cellIdentifier = ConversationMissedCallCellId
//        case .newClient, .usingNewDevice:
//            cellIdentifier = ConversationNewDeviceCellId
//        case .ignoredClient:
//            cellIdentifier = ConversationIgnoredDeviceCellId
//        case .conversationIsSecure:
//            cellIdentifier = ConversationVerifiedCellId
//        case .potentialGap, .reactivatedDevice:
//            cellIdentifier = ConversationMissingMessagesCellId
//        case .decryptionFailed, .decryptionFailed_RemoteIdentityChanged:
//            cellIdentifier = ConversationCannotDecryptCellId
//        case .participantsAdded, .participantsRemoved, .newConversation, .teamMemberLeave:
//            cellIdentifier = ParticipantsCell.zm_reuseIdentifier
//        case .messageDeletedForEveryone:
//            cellIdentifier = ConversationMessageDeletedCellId
//        case .performedCall:
//            cellIdentifier = ConversationPerformedCallCellId
//        case .messageTimerUpdate:
//            cellIdentifier = ConversationMessageTimerUpdateCellId
//        }
    }

//    static func attributedSystemMessage(for title: String, message: ZMConversationMessage, sender: UserType) {
//        let senderString = self.senderName(for: message)
//        let title = title.localized(pov: sender.pov, args: senderString) && UIFont.mediumFont
//        return title.adding(font: labelBoldFont, to: senderString) && labelTextColor
//    }
//
    static func senderName(for message: ZMConversationMessage) -> String {
        guard let sender = message.sender else { return "conversation.status.someone".localized }
        if sender.isSelfUser {
            return "conversation.status.you".localized
        } else if let conversation = message.conversation {
            return sender.displayName(in: conversation)
        } else {
            return sender.displayName
        }
    }

}

class ConversationRenamedSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationRenamedSystemMessageCell
    let configuration: View.Configuration

    var isFullWidth: Bool {
        return true
    }

    init(message: ZMConversationMessage, data: ZMSystemMessageData, sender: ZMUser, newName: String) {
        let senderText = ConversationSystemMessageCellDescription.senderName(for: message)
        let titleString = "content.system.renamed_conv.title".localized(pov: sender.pov, args: senderText)

        let title = NSAttributedString(string: titleString, attributes: [.font: UIFont.mediumFont, .foregroundColor: UIColor.textForeground])
            .adding(font: .mediumSemiboldFont, to: senderText)

        let conversationName = NSAttributedString(string: newName, attributes: [.font: UIFont.normalSemiboldFont, .foregroundColor: UIColor.textForeground])
        configuration = View.Configuration(attributedText: title, newConversationName: conversationName)
    }

}

class ConversationCallSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var isFullWidth: Bool {
        return true
    }

    init(message: ZMConversationMessage, data: ZMSystemMessageData, missed: Bool) {
        let viewModel = CallCellViewModel(
            icon: missed ? .endCall : .phone,
            iconColor: UIColor(for: missed ? .vividRed : .strongLimeGreen),
            systemMessageType: data.systemMessageType,
            font: .mediumFont,
            boldFont: .mediumSemiboldFont,
            textColor: .textForeground,
            message: message
        )

        configuration = View.Configuration(icon: viewModel.image(), attributedText: viewModel.attributedTitle(), showLine: false)
    }
}

class ConversationMessageTimerCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var isFullWidth: Bool {
        return true
    }

    init(message: ZMConversationMessage, data: ZMSystemMessageData, timer: NSNumber, sender: ZMUser) {
        let senderText = ConversationSystemMessageCellDescription.senderName(for: message)
        let timeoutValue = MessageDestructionTimeoutValue(rawValue: timer.doubleValue)

        var updateText: NSAttributedString? = nil
        let baseAttributes: [NSAttributedString.Key: AnyObject] = [.font: UIFont.mediumFont, .foregroundColor: UIColor.textForeground]

        if timeoutValue == .none {
            updateText = NSAttributedString(string: "content.system.message_timer_off".localized(pov: sender.pov, args: senderText), attributes: baseAttributes)
                .adding(font: .mediumSemiboldFont, to: senderText)

        } else if let displayString = timeoutValue.displayString {
            let timerString = displayString.replacingOccurrences(of: String.breakingSpace, with: String.nonBreakingSpace)
            updateText = NSAttributedString(string: "content.system.message_timer_changes".localized(pov: sender.pov, args: senderText, timerString), attributes: baseAttributes)
                .adding(font: .mediumSemiboldFont, to: senderText)
                .adding(font: .mediumSemiboldFont, to: timerString)
        }

        let icon = UIImage(for: .hourglass, fontSize: 16, color: UIColor(scheme: .textDimmed))
        configuration = View.Configuration(icon: icon, attributedText: updateText, showLine: false)
    }

}

public extension String {
    static let breakingSpace = " "           // classic whitespace
    static let nonBreakingSpace = "\u{00A0}" // &#160;
}

class ConversationVeritfiedSystemMessageSectionDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var isFullWidth: Bool {
        return true
    }

    init() {
        let title = NSAttributedString(
            string: "content.system.is_verified".localized,
            attributes: [.font: UIFont.mediumFont, .foregroundColor: UIColor.textForeground]
        )

        configuration = View.Configuration(icon: WireStyleKit.imageOfShieldverified, attributedText: title, showLine: true)
    }
}
