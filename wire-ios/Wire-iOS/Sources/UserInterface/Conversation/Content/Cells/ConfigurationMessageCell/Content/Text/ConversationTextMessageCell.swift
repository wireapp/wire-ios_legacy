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
import WireSyncEngine
import UIKit

final class ConversationTextMessageCell: UIView,
                                         ConversationMessageCell,
                                         TextViewInteractionDelegate {

    struct Configuration: Equatable {
        let attributedText: NSAttributedString
        let isObfuscated: Bool
    }

    private lazy var messageTextView: LinkInteractionTextView = {
        let view = LinkInteractionTextView()

        view.isEditable = false
        view.isSelectable = true
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = UIEdgeInsets.zero
        view.textContainer.lineFragmentPadding = 0
        view.isUserInteractionEnabled = true
        view.accessibilityIdentifier = "Message"
        view.accessibilityElementsHidden = false
        view.dataDetectorTypes = [.link, .address, .phoneNumber, .flightNumber, .calendarEvent, .shipmentTrackingNumber]
        view.linkTextAttributes = [.foregroundColor: UIColor.accent()]
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.interactionDelegate = self

        view.textDragInteraction?.isEnabled = false

        return view
    }()

    var isSelected: Bool = false

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
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
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(messageTextView)
        configureConstraints()
    }

    private func configureConstraints() {
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.fitInSuperview()
    }

    func configure(with object: Configuration, animated: Bool) {
        messageTextView.attributedText = object.attributedText

        if object.isObfuscated {
            messageTextView.accessibilityIdentifier = "Obfuscated message"
        } else {
            messageTextView.accessibilityIdentifier = "Message"
        }
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
        delegate?.conversationMessageWantsToOpenUserDetails(self, user: mention.user, sourceView: messageTextView, frame: selectionRect)
        return true
    }

    func textViewDidLongPress(_ textView: LinkInteractionTextView) {
        if !UIMenuController.shared.isMenuVisible {
            menuPresenter?.showMenu()
        }
    }

}

// MARK: - Description

final class ConversationTextMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationTextMessageCell
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 8

    let isFullWidth: Bool  = false
    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(attributedString: NSAttributedString, isObfuscated: Bool) {
        configuration = View.Configuration(attributedText: attributedString, isObfuscated: isObfuscated)
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueConversationCell(with: self, for: indexPath)
        cell.accessibilityCustomActions = actionController?.makeAccessibilityActions()
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

        return cells(textMessageData: textMessageData, message: message, searchQueries: searchQueries)
    }

    static func cells(textMessageData: ZMTextMessageData,
                      message: ZMConversationMessage,
                      searchQueries: [String]) -> [AnyConversationMessageCellDescription] {

        var cells: [AnyConversationMessageCellDescription] = []

        // Refetch the link attachments if needed
        if !Settings.disableLinkPreviews {
            ZMUserSession.shared()?.enqueue {
                message.refetchLinkAttachmentsIfNeeded()
            }
        }

        // Text parsing
        let attachments = message.linkAttachments ?? []
        var messageText = NSAttributedString.format(message: textMessageData, isObfuscated: message.isObfuscated)

        // Search queries
        if !searchQueries.isEmpty {
            let highlightStyle: [NSAttributedString.Key: AnyObject] = [.backgroundColor: UIColor.accentDarken]
            messageText = messageText.highlightingAppearances(of: searchQueries, with: highlightStyle, upToWidth: 0, totalMatches: nil)
        }

        // Quote
        if textMessageData.hasQuote {
            let quotedMessage = textMessageData.quoteMessage
            let quoteCell = ConversationReplyCellDescription(quotedMessage: quotedMessage)
            cells.append(AnyConversationMessageCellDescription(quoteCell))
        }

        // Text
        if !messageText.string.isEmpty {
            let textCell = ConversationTextMessageCellDescription(attributedString: messageText, isObfuscated: message.isObfuscated)
            cells.append(AnyConversationMessageCellDescription(textCell))
        }

        guard !message.isObfuscated else {
            return cells
        }

        // Links
        if let attachment = attachments.first {
            // Link Attachment
            let attachmentCell = ConversationLinkAttachmentCellDescription(attachment: attachment, thumbnailResource: message.linkAttachmentImage)
            cells.append(AnyConversationMessageCellDescription(attachmentCell))
        } else if textMessageData.linkPreview != nil {
            // Link Preview
            let linkPreviewCell = ConversationLinkPreviewArticleCellDescription(message: message, data: textMessageData)
            cells.append(AnyConversationMessageCellDescription(linkPreviewCell))
        }

        return cells
    }

}
