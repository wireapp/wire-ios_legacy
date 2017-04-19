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


import Classy
import Cartography


final class ConversationRenamedCell: IconSystemCell {

    var nameLabelFont: UIFont?
    private let nameLabel = UILabel()

    public required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        nameLabel.numberOfLines = 0
        messageContentView.addSubview(nameLabel)
        createConstraints()
        CASStyler.default().styleItem(self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        constrain(messageContentView, labelView, nameLabel) { container, label, nameLabel in
            nameLabel.leading == label.leading
            nameLabel.trailing == container.trailingMargin
            nameLabel.top == label.bottom + 8
            nameLabel.bottom == container.bottom - 8
        }
    }

    override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        updateImage()
        updateLabel()
    }

    private func updateImage() {
        guard let color = labelTextColor else { return }
        leftIconView.image = UIImage(for: .pencil, fontSize: 16, color: color)
    }

    private func updateLabel() {
        guard let systemMessage = message.systemMessageData,
            systemMessage.systemMessageType == .conversationNameChanged else { return }

        attributedText = attributedTitle(for: message)

        nameLabel.attributedText = attributedName(for: systemMessage)
        nameLabel.accessibilityLabel = nameLabel.attributedText?.string
    }

    private func attributedTitle(for message: ZMConversationMessage) -> NSAttributedString? {
        guard let labelFont = labelFont,
            let labelBoldFont = labelBoldFont,
            let labelTextColor = labelTextColor,
            let sender = message.sender,
            let senderString = self.sender(for: message) else { return nil }

        let title = key(with: "title").localized(pov: sender.pov, args: senderString) && labelFont
        return title.adding(font: labelBoldFont, to: senderString) && labelTextColor
    }

    private func attributedName(for systemMessage: ZMSystemMessageData) -> NSAttributedString? {
        guard let name = systemMessage.text, let font = nameLabelFont, let color = labelTextColor  else { return nil }
        return name && font && color
    }

    private func sender(for message: ZMConversationMessage) -> String? {
        guard let sender = message.sender else { return nil }
        if sender.isSelfUser {
            return key(with: "title.you").localized
        } else if let conversation = message.conversation {
            return sender.displayName(in: conversation)
        } else {
            return sender.displayName
        }
    }

    private func key(with pathComponent: String) -> String {
        return "content.system.renamed_conv.\(pathComponent)"
    }

}
