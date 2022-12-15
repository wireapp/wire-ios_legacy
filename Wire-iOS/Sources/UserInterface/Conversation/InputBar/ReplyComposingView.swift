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

import WireSyncEngine
import UIKit

private typealias ConversationInputBarMessagePreview = L10n.Localizable.Conversation.InputBar.MessagePreview

// MARK: - ReplyComposingViewDelegate
protocol ReplyComposingViewDelegate: AnyObject {
    func composingViewDidCancel(composingView: ReplyComposingView)
    func composingViewWantsToShowMessage(composingView: ReplyComposingView, message: ZMConversationMessage)
}

// MARK: - ZMConversationMessage Extension
fileprivate extension ZMConversationMessage {
    var accessibilityDescription: String {

        let contentDescriptionText: String
        let senderDescriptionText = senderUser?.name ?? ""

        if let textData = textMessageData {
            contentDescriptionText = textData.messageText ?? ""
        } else if isImage {
            contentDescriptionText = ConversationInputBarMessagePreview.Accessibility.imageMessage
        } else if let locationData = locationMessageData {
            contentDescriptionText = locationData.name ?? ConversationInputBarMessagePreview.Accessibility.locationMessage
        } else if isVideo {
            contentDescriptionText = ConversationInputBarMessagePreview.Accessibility.videoMessage
        } else if isAudio {
            contentDescriptionText = ConversationInputBarMessagePreview.Accessibility.audioMessage
        } else if let fileData = fileMessageData {
            contentDescriptionText = ConversationInputBarMessagePreview.Accessibility.fileMessage(fileData.filename ?? "")
        } else {
            contentDescriptionText = ConversationInputBarMessagePreview.Accessibility.unknownMessage
        }

        return ConversationInputBarMessagePreview.Accessibility.messageFrom(contentDescriptionText, senderDescriptionText)
    }
}

// MARK: - ReplyComposingView
final class ReplyComposingView: UIView {
    // MARK: - Properties
    let message: ZMConversationMessage
    let closeButton = IconButton()
    private let leftSideView = UIView(frame: .zero)
    private var messagePreviewContainer: ReplyRoundCornersView!
    private var previewView: UIView!
    weak var delegate: ReplyComposingViewDelegate?
    private var observerToken: Any?

    // MARK: - Init
    init(message: ZMConversationMessage) {
        require(message.canBeQuoted)
        require(message.conversationLike != nil)

        self.message = message
        super.init(frame: .zero)

        setupMessageObserver()
        setupSubviews()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Message Observer
    private func setupMessageObserver() {
        if let userSession = ZMUserSession.shared() {
            observerToken = MessageChangeInfo.add(observer: self, for: message, userSession: userSession)
        }
    }

    // MARK: - Setup Views and Constraints
    private func setupSubviews() {
        backgroundColor = SemanticColors.SearchBar.backgroundInputView

        previewView = message.replyPreview()!
        previewView.isUserInteractionEnabled = false
        previewView.accessibilityIdentifier = "replyView"
        previewView.accessibilityLabel = buildAccessibilityLabel()

        messagePreviewContainer = ReplyRoundCornersView(containedView: previewView)
        messagePreviewContainer.addTarget(self, action: #selector(onTap), for: .touchUpInside)

        leftSideView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        messagePreviewContainer.translatesAutoresizingMaskIntoConstraints = false

        closeButton.isAccessibilityElement = true
        closeButton.accessibilityIdentifier = "cancelReply"
        closeButton.accessibilityLabel = L10n.Localizable.Conversation.InputBar.closeReply
        closeButton.setIcon(.cross, size: .tiny, for: .normal)
        closeButton.setIconColor(SemanticColors.Icon.foregroundDefaultBlack, for: .normal)
        closeButton.addCallback(for: .touchUpInside) { [weak self] _ in
            self?.delegate?.composingViewDidCancel(composingView: self!)
        }

        [leftSideView, messagePreviewContainer].forEach(self.addSubview)

        leftSideView.addSubview(closeButton)
    }

    private func buildAccessibilityLabel() -> String {
        let messageDescription = message.accessibilityDescription
        return ConversationInputBarMessagePreview.accessibilityDescription(messageDescription)
    }

    private func setupConstraints() {
        let margins = directionAwareConversationLayoutMargins

        let constraints: [NSLayoutConstraint] = [
            leftSideView.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftSideView.topAnchor.constraint(equalTo: topAnchor),
            leftSideView.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftSideView.widthAnchor.constraint(equalToConstant: margins.left),
            closeButton.centerXAnchor.constraint(equalTo: leftSideView.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: leftSideView.topAnchor, constant: 8),
            messagePreviewContainer.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            messagePreviewContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            messagePreviewContainer.leadingAnchor.constraint(equalTo: leftSideView.trailingAnchor),
            messagePreviewContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margins.right),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Actions
    @objc func onTap() {
        self.delegate?.composingViewWantsToShowMessage(composingView: self, message: message)
    }

}

// MARK: - ReplyComposingView Extension
extension ReplyComposingView: ZMMessageObserver {
    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        if changeInfo.message.hasBeenDeleted {
            self.delegate?.composingViewDidCancel(composingView: self)
        }
    }
}
