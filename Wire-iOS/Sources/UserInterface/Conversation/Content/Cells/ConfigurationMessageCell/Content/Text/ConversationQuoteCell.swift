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

class ConversationReplyContentView: UIView {

    struct Configuration {
        enum Content {
            case text(NSAttributedString)
            case imagePreview(ZMConversationMessage, isVideo: Bool)
        }

        let showDetails: Bool
        let senderName: String?
        let timestamp: String?

        let content: Content
    }

    let senderLabel = UILabel()
    let contentTextView = UITextView()
    let timestampLabel = UILabel()

    let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
        configureConstraints()
    }

    private func configureSubviews() {
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 6
        addSubview(stackView)

        senderLabel.font = .mediumSemiboldFont
        senderLabel.textColor = .textForeground
        senderLabel.numberOfLines = 1
        senderLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.addArrangedSubview(senderLabel)

        contentTextView.textContainer.lineBreakMode = .byTruncatingTail
        contentTextView.textContainer.maximumNumberOfLines = 4
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.isScrollEnabled = false
        contentTextView.textContainerInset = .zero
        contentTextView.isEditable = false
        contentTextView.isSelectable = true
        contentTextView.backgroundColor = .clear
        contentTextView.textColor = .textForeground

        contentTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.addArrangedSubview(contentTextView)

        timestampLabel.font = .mediumFont
        timestampLabel.textColor = .textDimmed
        timestampLabel.numberOfLines = 1
        timestampLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.addArrangedSubview(timestampLabel)
    }

    private func configureConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    func configure(with object: Configuration) {
        senderLabel.isHidden = !object.showDetails
        timestampLabel.isHidden = !object.showDetails

        senderLabel.text = object.senderName
        timestampLabel.text = object.timestamp

        switch object.content {
        case .text(let attributedContent):
            contentTextView.attributedText = attributedContent
        case .imagePreview:
            contentTextView.text = "UNSUPPORTED MESSAGE"
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

    }

}

class ConversationReplyCell: UIView, ConversationMessageCell {
    typealias Configuration = ConversationReplyContentView.Configuration
    var isSelected: Bool = false

    let contentView: ConversationReplyContentView
    var container: ReplyRoundCornersView

    override init(frame: CGRect) {
        contentView = ConversationReplyContentView()
        container = ReplyRoundCornersView(containedView: contentView)
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        addSubview(container)
    }

    private func configureConstraints() {
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(with object: Configuration) {
        contentView.configure(with: object)
    }

}

class ConversationReplyCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationReplyCell
    let configuration: View.Configuration

    let isFullWidth = false
    let supportsActions = false

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate?
    weak var actionController: ConversationCellActionController?

    init(quotedMessage: ZMConversationMessage?) {
        let isUnavailable = quotedMessage == nil
        let senderName = quotedMessage?.senderName
        let timestamp = quotedMessage?.formattedOriginalReceivedDate()

        let content: View.Configuration.Content
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.smallSemiboldFont,
                                                         .foregroundColor: UIColor.textForeground]

        switch quotedMessage {
        case let message? where message.isText:
            let textMessageData = message.textMessageData!
            let hasNoText = textMessageData.messageText == nil || textMessageData.messageText!.isEmpty
            if hasNoText, let linkPreview = textMessageData.linkPreview {
                let font = UIFont.systemFont(ofSize: 14, contentSizeCategory: .medium, weight: .light)
                content = .text(linkPreview.originalURLString && [.font: font, .foregroundColor: UIColor.textForeground])
            } else {
                content = .text(NSAttributedString.formatForPreview(message: message.textMessageData!))
            }

        case let message? where message.isLocation:
            let location = message.locationMessageData!
            let imageIcon = NSTextAttachment.textAttachment(for: .location, with: .textForeground, and: .medium)!
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + (location.name ?? "conversation.input_bar.message_preview.location".localized).localizedUppercase
            content = .text(initialString && attributes)

        case let message? where message.isAudio:
            let imageIcon = NSTextAttachment.textAttachment(for: .microphone, with: .textForeground, and: .medium)!
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + "conversation.input_bar.message_preview.audio".localized.localizedUppercase
            content = .text(initialString && attributes)

        case let message? where message.isFile:
            let fileData = message.fileMessageData!
            let imageIcon = NSTextAttachment.textAttachment(for: .document, with: .textForeground, and: .medium)!
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + (fileData.filename ?? "conversation.input_bar.message_preview.file".localized).localizedUppercase
            content = .text(initialString && attributes)

        default:
            content = .text(NSAttributedString(string: "You cannot see this message."))
        }

        configuration = View.Configuration(showDetails: !isUnavailable, senderName: senderName, timestamp: timestamp, content: content)
    }

}
