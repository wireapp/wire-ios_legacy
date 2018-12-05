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

import Foundation

extension ZMSystemMessageData {

    /// return self user if the users array has self user only. Otherwise return nil
    var involvesSelfUserOnly: ZMUser? {
        if users.count == 1,
            let user = users.first,
            user.isSelfUser {
            return user
        }

        return .none
    }

    var otherUserName: String? {
        let displayNamesOfOthers = users.filter {!$0.isSelfUser }.compactMap {$0.displayName as String}
        return displayNamesOfOthers[0]
    }
}

struct ReadReceiptViewModel {
    let icon: ZetaIconType
    let iconColor: UIColor?
    let message: ZMConversationMessage
    let systemMessage: ZMSystemMessageData

    func image() -> UIImage? {
        return iconColor.map { UIImage(for: icon, iconSize: .tiny, color: $0) }
    }

    func attributedTitle() -> NSAttributedString? {
        let baseAttributes: [NSAttributedString.Key: AnyObject] = [.font: UIFont.mediumFont, .foregroundColor: UIColor.from(scheme: .textForeground)]


        var updateText: NSAttributedString! = .none

        switch systemMessage.systemMessageType {
        case .readReceiptsDisabled:
            if let selfUser = systemMessage.involvesSelfUserOnly {
                updateText = NSAttributedString(string: "content.system.message_read_receipt_off".localized(pov: selfUser.pov, args: "content.system.you_started".localized), attributes: baseAttributes)
            } else if let otherUserName = systemMessage.otherUserName {
                updateText = NSAttributedString(string: "content.system.message_read_receipt_off".localized(args: otherUserName), attributes: baseAttributes)
                    .adding(font: .mediumSemiboldFont, to: otherUserName)
            }
        case .readReceiptsEnabled:
            if let selfUser = systemMessage.involvesSelfUserOnly {
                updateText = NSAttributedString(string: "content.system.message_read_receipt_on".localized(pov: selfUser.pov, args: "content.system.you_started".localized), attributes: baseAttributes)
            } else if let otherUserName = systemMessage.otherUserName {
                updateText = NSAttributedString(string: "content.system.message_read_receipt_on".localized(args: otherUserName), attributes: baseAttributes)
                    .adding(font: .mediumSemiboldFont, to: otherUserName)
            }
        case .readReceiptsOn:
            updateText = NSAttributedString(string: "content.system.message_read_receipt_on_add_to_group".localized)

        default:
            assertionFailure("invalid systemMessageType for ReadReceiptViewModel")
            break
        }


        return updateText
    }
}

final class ConversationReadReceiptSettingChangedCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage,
         data: ZMSystemMessageData) {
        let viewModel = ReadReceiptViewModel(icon: .eye,
                                             iconColor: UIColor.from(scheme: .textDimmed),
                                             message: message,
                                             systemMessage: data)

        configuration = View.Configuration(icon: viewModel.image(),
                                           attributedText: viewModel.attributedTitle(),
                                           showLine: true)
        actionController = nil
    }
}
