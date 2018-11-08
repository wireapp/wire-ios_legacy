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

protocol ConversationReplyContentViewDelegate: class {
    func conversationReplyContentViewDidTapOriginalMessage()
}

class ConversationReplyContentView: UIView {

    struct Configuration {
        enum Content {
            case text(NSAttributedString)
            case imagePreview(thumbnail: PreviewableImageResource, isVideo: Bool)
        }

        let showDetails: Bool
        let isEdited: Bool
        let senderName: String?
        let timestamp: String?

        let content: Content
    }

    let senderComponent = SenderNameCellComponent()
    let contentTextView = UITextView()
    let timestampLabel = UILabel()
    let assetThumbnail = ImageResourceThumbnailView()

    let stackView = UIStackView()

    weak var delegate: ConversationReplyContentViewDelegate?

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

        senderComponent.label.font = .mediumSemiboldFont
        senderComponent.label.textColor = .from(scheme: .textForeground)
        stackView.addArrangedSubview(senderComponent)

        contentTextView.textContainer.lineBreakMode = .byTruncatingTail
        contentTextView.textContainer.maximumNumberOfLines = 4
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.isScrollEnabled = false
        contentTextView.isUserInteractionEnabled = false
        contentTextView.textContainerInset = .zero
        contentTextView.isEditable = false
        contentTextView.isSelectable = false
        contentTextView.backgroundColor = .clear
        contentTextView.textColor = .from(scheme: .textForeground)

        contentTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.addArrangedSubview(contentTextView)

        assetThumbnail.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.addArrangedSubview(assetThumbnail)

        timestampLabel.font = .mediumFont
        timestampLabel.textColor = .from(scheme: .textDimmed)
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
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            assetThumbnail.heightAnchor.constraint(lessThanOrEqualToConstant: 140)
        ])
    }

    func configure(with object: Configuration) {
        senderComponent.isHidden = !object.showDetails
        timestampLabel.isHidden = !object.showDetails

        senderComponent.senderName = object.senderName
        senderComponent.indicatorIcon = object.isEdited ? UIImage(for: .pencil, iconSize: .messageStatus, color: .from(scheme: .iconNormal)) : nil
        timestampLabel.text = object.timestamp

        switch object.content {
        case .text(let attributedContent):
            contentTextView.attributedText = attributedContent
            contentTextView.isHidden = false
            assetThumbnail.isHidden = true
        case .imagePreview(let resource, let isVideo):
            assetThumbnail.setResource(resource, isVideoPreview: isVideo)
            assetThumbnail.isHidden = false
            contentTextView.isHidden = true
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = UIColor(rgb: 0x33373A, alpha: 0.4)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            backgroundColor = .clear
        }

        guard
            let touchLocation = touches.first?.location(in: self),
            bounds.contains(touchLocation)
        else {
            return
        }

        delegate?.conversationReplyContentViewDidTapOriginalMessage()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = .clear
    }

}

class ConversationReplyCell: UIView, ConversationMessageCell, ConversationReplyContentViewDelegate {
    typealias Configuration = ConversationReplyContentView.Configuration
    var isSelected: Bool = false

    let contentView: ConversationReplyContentView
    var container: ReplyRoundCornersView

    weak var delegate: ConversationCellDelegate?
    weak var message: ZMConversationMessage?

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
        contentView.delegate = self
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

    func configure(with object: Configuration, animated: Bool) {
        contentView.configure(with: object)
    }

    func conversationReplyContentViewDidTapOriginalMessage() {
        delegate?.conversationCell?(self, didSelect: .openQuote, for: message)
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
        let isEdited = quotedMessage?.updatedAt != nil
        let senderName = quotedMessage?.senderName
        let timestamp = quotedMessage?.formattedOriginalReceivedDate()

        var isUnavailable = false
        let content: View.Configuration.Content
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.smallSemiboldFont,
                                                         .foregroundColor: UIColor.from(scheme: .textForeground)]

        switch quotedMessage {
        case let message? where message.isText:
            let data = message.textMessageData!
            content = .text(NSAttributedString.formatForPreview(message: data, inputMode: false))

        case let message? where message.isLocation:
            let location = message.locationMessageData!
            let imageIcon = NSTextAttachment.textAttachment(for: .location, with: .from(scheme: .textForeground))!
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + (location.name ?? "conversation.input_bar.message_preview.location".localized).localizedUppercase
            content = .text(initialString && attributes)

        case let message? where message.isAudio:
            let imageIcon = NSTextAttachment.textAttachment(for: .microphone, with: .from(scheme: .textForeground))!
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + "conversation.input_bar.message_preview.audio".localized.localizedUppercase
            content = .text(initialString && attributes)

        case let message? where message.isImage:
            content = .imagePreview(thumbnail: message.imageMessageData!.image, isVideo: false)

        case let message? where message.isVideo:
            content = .imagePreview(thumbnail: message.fileMessageData!.thumbnailImage, isVideo: true)

        case let message? where message.isFile:
            let fileData = message.fileMessageData!
            let imageIcon = NSTextAttachment.textAttachment(for: .document, with: .from(scheme: .textForeground))!
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + (fileData.filename ?? "conversation.input_bar.message_preview.file".localized).localizedUppercase
            content = .text(initialString && attributes)

        default:
            isUnavailable = true
            let attributes: [NSAttributedString.Key: AnyObject] = [.font: UIFont.mediumFont.italic, .foregroundColor: UIColor.from(scheme: .textDimmed)]
            content = .text(NSAttributedString(string: "content.message.reply.broken_message".localized, attributes: attributes))
        }

        configuration = View.Configuration(showDetails: !isUnavailable, isEdited: isEdited, senderName: senderName, timestamp: timestamp, content: content)
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueConversationCell(with: self, for: indexPath)
        cell.cellView.delegate = self.delegate
        cell.cellView.message = self.message
        return cell
    }

}
