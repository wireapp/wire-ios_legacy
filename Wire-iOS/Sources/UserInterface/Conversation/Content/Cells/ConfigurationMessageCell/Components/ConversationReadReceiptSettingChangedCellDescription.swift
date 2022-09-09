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
import WireCommonComponents
import WireDataModel

struct ReadReceiptViewModel {
    let icon: StyleKitIcon
    let iconColor: UIColor?
    let systemMessageType: ZMSystemMessageType
    let sender: UserType

    func image() -> UIImage? {
        return iconColor.map { icon.makeImage(size: .tiny, color: $0) }
    }

    func createSystemMessage(template: String) -> NSAttributedString {
        var updateText: NSAttributedString! = .none

        if sender.isSelfUser {
            let youLocalized = "content.system.you_started".localized

            updateText = NSAttributedString(string: template.localized(pov: sender.pov, args: youLocalized), attributes: ConversationSystemMessageCell.baseAttributes).adding(font: .mediumSemiboldFont, to: youLocalized)
        } else if let otherUserName = sender.name {
            updateText = NSAttributedString(string: template.localized(args: otherUserName), attributes: ConversationSystemMessageCell.baseAttributes)
                .adding(font: .mediumSemiboldFont, to: otherUserName)
        } else {
            assertionFailure("invalid user name for ReadReceiptViewModel")
        }

        return updateText
    }

    func attributedTitle() -> NSAttributedString? {

        var updateText: NSAttributedString! = .none

        switch systemMessageType {
        case .readReceiptsDisabled:
            updateText = createSystemMessage(template: "content.system.message_read_receipt_off")
        case .readReceiptsEnabled:
            updateText = createSystemMessage(template: "content.system.message_read_receipt_on")
        case .readReceiptsOn:
            updateText = NSAttributedString(string: "content.system.message_read_receipt_on_add_to_group".localized, attributes: ConversationSystemMessageCell.baseAttributes)
        default:
            assertionFailure("invalid systemMessageType for ReadReceiptViewModel")
        }

        return updateText
    }
}

extension ConversationSystemMessageCell {
    static var baseAttributes: [NSAttributedString.Key: AnyObject] {
        return [.font: UIFont.mediumFont, .foregroundColor: SemanticColors.Label.textDefault]
    }
}

final class ConversationReadReceiptSettingChangedCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(sender: UserType,
         systemMessageType: ZMSystemMessageType) {
        let viewModel = ReadReceiptViewModel(icon: .eye,
                                             iconColor: SemanticColors.Icon.backgroundIconDefaultConversationView,
                                             systemMessageType: systemMessageType, sender: sender)

        configuration = View.Configuration(icon: viewModel.image(),
                                           attributedText: viewModel.attributedTitle(),
                                           showLine: true)
        actionController = nil
    }
}
