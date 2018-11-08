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

class ConversationTextMessageCell: UIView, ConversationMessageCell {

    struct Configuration {
        let attributedText: NSAttributedString
    }

    let messageTextView = LinkInteractionTextView()
    var isSelected: Bool = false

    var selectionView: UIView? {
        return messageTextView
    }

    var selectionRect: CGRect {
        return messageTextView.layoutManager.usedRect(for: messageTextView.textContainer)
    }

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
        messageTextView.isEditable = false
        messageTextView.isSelectable = true
        messageTextView.backgroundColor = UIColor.from(scheme: .contentBackground)
        messageTextView.isScrollEnabled = false
        messageTextView.textContainerInset = UIEdgeInsets.zero
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.isUserInteractionEnabled = true
        messageTextView.accessibilityIdentifier = "Message"
        messageTextView.accessibilityElementsHidden = false
        messageTextView.dataDetectorTypes = [.link, .address, .phoneNumber, .flightNumber, .calendarEvent, .shipmentTrackingNumber]
        messageTextView.setContentHuggingPriority(.required, for: .vertical)
        messageTextView.setContentCompressionResistancePriority(.required, for: .vertical)

        if #available(iOS 11.0, *) {
            messageTextView.textDragInteraction?.isEnabled = false
        }

        addSubview(messageTextView)
    }

    private func configureConstraints() {
        messageTextView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            messageTextView.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageTextView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            messageTextView.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageTextView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(with object: Configuration, animated: Bool) {
        messageTextView.attributedText = object.attributedText
    }

}

// MARK: - Description

class ConversationTextMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationTextMessageCell
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate?
    weak var actionController: ConversationCellActionController?

    let isFullWidth: Bool  = false
    let supportsActions: Bool = true

    init(attributedString: NSAttributedString) {
        configuration = View.Configuration(attributedText: attributedString)
    }

}

// MARK: - Factory

extension ConversationTextMessageCellDescription {

    static func cells(for message: ZMConversationMessage) -> [AnyConversationMessageCellDescription] {
        guard let textMessageData = message.textMessageData else {
            preconditionFailure("Invalid text message")
        }

        var lastKnownLinkAttachment: LinkAttachment?
        let messageText = NSAttributedString.format(message: textMessageData, isObfuscated: message.isObfuscated, linkAttachment: &lastKnownLinkAttachment)

        var cells: [AnyConversationMessageCellDescription] = []
        
        // Quote
        if textMessageData.hasQuote {
            let quotedMessage = message.textMessageData?.quote
            let quoteCell = ConversationReplyCellDescription(quotedMessage: quotedMessage)
            cells.append(AnyConversationMessageCellDescription(quoteCell))
        }

        // Text
        let textCell = ConversationTextMessageCellDescription(attributedString: messageText)
        cells.append(AnyConversationMessageCellDescription(textCell))

        guard !message.isObfuscated else {
            return cells
        }

        // Link Attachment
        if let attachment = lastKnownLinkAttachment, attachment.type != .none {
            switch attachment.type {
            case .youtubeVideo:
                let youtubeCell = ConversationYouTubeAttachmentCellDescription(attachment: attachment)
                cells.append(AnyConversationMessageCellDescription(youtubeCell))
            case .soundcloudTrack:
                let trackCell = ConversationSoundCloudCellDescription<AudioTrackViewController>(message: message, attachment: attachment)
                cells.append(AnyConversationMessageCellDescription(trackCell))
            case .soundcloudSet:
                let playlistCell = ConversationSoundCloudCellDescription<AudioPlaylistViewController>(message: message, attachment: attachment)
                cells.append(AnyConversationMessageCellDescription(playlistCell))
            default:
                break
            }
        }

        // Link Preview
        if textMessageData.linkPreview != nil {
            let linkPreviewCell = ConversationLinkPreviewArticleCellDescription(message: message, data: textMessageData)
            cells.append(AnyConversationMessageCellDescription(linkPreviewCell))
        }

        return cells
    }

}
