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

class ConversationPingCell: ConversationIconBasedCell, ConversationMessageCell {

    struct Configuration {
        let pingColor: UIColor
        let pingText: NSAttributedString
    }

    func configure(with object: Configuration, animated: Bool) {
        attributedText = object.pingText
        imageView.image = UIImage(for: .ping, fontSize: 20, color: object.pingColor)
        lineView.isHidden = true
    }

}

class ConversationPingCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationPingCell
    let configuration: ConversationPingCell.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate? 
    weak var actionController: ConversationCellActionController?

    var isFullWidth: Bool {
        return true
    }

    var supportsActions: Bool {
        return true
    }

    init(message: ZMConversationMessage, sender: ZMUser) {
        let senderText = sender.isSelfUser ? "content.ping.text.you".localized : sender.displayName
        let pingText = "content.ping.text".localized(pov: sender.pov, args: senderText)

        let text = NSAttributedString(string: pingText, attributes: [.font: UIFont.mediumFont])
            .adding(font: .mediumSemiboldFont, to: senderText)

        let pingColor: UIColor = message.isObfuscated ? .accentDimmedFlat : sender.accentColor
        self.configuration = View.Configuration(pingColor: pingColor, pingText: text)
        actionController = nil
    }

}
