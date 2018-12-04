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

final class ConversationReadReceiptSettingChangedCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    var configuration: View.Configuration!

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

    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let icon = UIImage(for: .eye, fontSize: 16, color: UIColor.from(scheme: .textDimmed))


        configuration = View.Configuration(icon: icon,
                                           attributedText: messageString(message: message),
                                           showLine: true)
        actionController = nil
    }

    func messageString(message: ZMConversationMessage) -> NSAttributedString {
        let baseAttributes: [NSAttributedString.Key: AnyObject] = [.font: UIFont.mediumFont, .foregroundColor: UIColor.from(scheme: .textForeground)]

        ///TODO: get on/off setting from somewhere or argument?
        let updateText: NSAttributedString
        let sender = message.sender! ///TODO:
        let senderText = message.senderName

        ///TODO: on case
        updateText = NSAttributedString(string: "content.system.message_read_receipt_off".localized(pov: sender.pov, args: senderText), attributes: baseAttributes)
            .adding(font: .mediumSemiboldFont, to: senderText)

        return updateText
    }

}
