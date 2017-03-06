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

class MissedCallCell: IconSystemCell {

    override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        leftIconView.image = UIImage(for: .endCall, iconSize: .tiny, color: UIColor(for: .vividRed))
        updateLabel()
    }

    private func updateLabel() {
        guard let systemMessageData = message.systemMessageData,
            let sender = message.sender,
            let labelFont = labelFont,
            let labelBoldFont = labelBoldFont,
            let labelTextColor = labelTextColor,
            systemMessageData.systemMessageType == .missedCall
            else { return }

        let senderString = string(for: sender) && labelBoldFont
        let calledString = " \(string(for: "called"))" && labelFont
        labelView.attributedText = (senderString + calledString) && labelTextColor
    }

    private func string(for user: ZMUser) -> String {
        return (user.isSelfUser ? string(for: "you") : user.displayName).uppercased()
    }

    private func string(for key: String) -> String {
        return "content.system.missed_call.\(key)".localized.uppercased()
    }

}
