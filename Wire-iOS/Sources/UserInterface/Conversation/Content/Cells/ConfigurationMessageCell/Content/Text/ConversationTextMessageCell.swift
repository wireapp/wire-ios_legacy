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

class ConversationTextMessageCell: UIView, ConversationMessageCell, TextViewInteractionDelegate {

    struct Configuration {
        let attributedText: NSAttributedString
    }

    let messageTextView = LinkInteractionTextView()
    var isSelected: Bool = false

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate?
    weak var menuPresenter: ConversationMessageCellMenuPresenter?
    
    var ephemeralTimerTopInset: CGFloat {
        guard let font = messageTextView.font else {
            return 0
        }
        
        return font.lineHeight / 2
    }

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
        messageTextView.backgroundColor = .clear
        messageTextView.isScrollEnabled = false
        messageTextView.textContainerInset = UIEdgeInsets.zero
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.isUserInteractionEnabled = true
        messageTextView.accessibilityIdentifier = "Message"
        messageTextView.accessibilityElementsHidden = false
        messageTextView.dataDetectorTypes = [.link, .address, .phoneNumber, .flightNumber, .calendarEvent, .shipmentTrackingNumber]
        messageTextView.setContentHuggingPriority(.required, for: .vertical)
        messageTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        messageTextView.interactionDelegate = self

        if #available(iOS 11.0, *) {
            messageTextView.textDragInteraction?.isEnabled = false
        }

        addSubview(messageTextView)
    }

    private func configureConstraints() {
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.fitInSuperview()
    }

    func configure(with object: Configuration, animated: Bool) {
        messageTextView.attributedText = object.attributedText
    }

    func textView(_ textView: LinkInteractionTextView, open url: URL) -> Bool {
        // Open mention link
        if url.isMention {
            if let message = self.message, let mention = message.textMessageData?.mentions.first(where: { $0.location == url.mentionLocation }) {
                return self.openMention(mention)
            } else {
                return false
            }
        }

        // Open the URL
        return url.open()
    }

    func openMention(_ mention: Mention) -> Bool {
        self.delegate?.conversationCell?(self, userTapped: mention.user, in: messageTextView, frame: selectionRect)
        return true
    }

    func textViewDidLongPress(_ textView: LinkInteractionTextView) {
        if !UIMenuController.shared.isMenuVisible {
            self.menuPresenter?.showMenu()
        }
    }

}

// MARK: - Description

class ConversationTextMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationTextMessageCell
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate?
    weak var actionController: ConversationMessageActionController?
    
    var showEphemeralTimer: Bool = false
    var topMargin: Float = 8

    let isFullWidth: Bool  = false
    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(attributedString: NSAttributedString) {
        configuration = View.Configuration(attributedText: attributedString)
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueConversationCell(with: self, for: indexPath)
        cell.cellView.delegate = self.delegate
        cell.cellView.message = self.message
        cell.cellView.menuPresenter = cell
        return cell
    }

}

// MARK: - Factory

extension ConversationTextMessageCellDescription {

    static func cells(for message: ZMConversationMessage, searchQueries: [String]) -> [AnyConversationMessageCellDescription] {
        guard let textMessageData = message.textMessageData else {
            preconditionFailure("Invalid text message")
        }

        var cells: [AnyConversationMessageCellDescription] = []

        // Text parsing

        var lastKnownLinkAttachment: LinkAttachment?
        var messageText = NSAttributedString.format(message: textMessageData, isObfuscated: message.isObfuscated, linkAttachment: &lastKnownLinkAttachment)

        // Search queries

        if !searchQueries.isEmpty {
            let highlightStyle: [NSAttributedString.Key: AnyObject] = [.backgroundColor: UIColor.accentDarken]
            messageText = messageText.highlightingAppearances(of: searchQueries, with: highlightStyle, upToWidth: 0, totalMatches: nil)
        }

        // Quote
        if textMessageData.hasQuote {
            let quotedMessage = message.textMessageData?.quote
            let quoteCell = ConversationReplyCellDescription(quotedMessage: quotedMessage)
            cells.append(AnyConversationMessageCellDescription(quoteCell))
        }

        // Text
        if messageText.length > 0 {
            let textCell = ConversationTextMessageCellDescription(attributedString: messageText)
            cells.append(AnyConversationMessageCellDescription(textCell))
        }

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
        } else if textMessageData.linkPreview != nil {
            // Link Preview
            let linkPreviewCell = ConversationLinkPreviewArticleCellDescription(message: message, data: textMessageData)
            cells.append(AnyConversationMessageCellDescription(linkPreviewCell))
        }

        return cells
    }

}
