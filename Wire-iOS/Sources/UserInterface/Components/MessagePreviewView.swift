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

extension NSTextAttachment {
    static func textAttachment(for icon: ZetaIconType, with color: UIColor, and size: FontSize) -> NSTextAttachment? {
        guard let image = UIImage(for: icon, fontSize: 10, color: color)
            else { return nil }
        
        let attachment = NSTextAttachment()
        attachment.image = image
        let ratio = image.size.width / image.size.height
        let height: CGFloat = 10
        let verticalOffset : CGFloat = (size == .small) ? -1.0 : 0.0
        attachment.bounds = CGRect(x: 0, y: verticalOffset, width: height * ratio, height: height)
        return attachment
    }
}

extension ZMConversationMessage {
    func replyPreview() -> UIView? {
        guard self.canBeQuoted else {
            return nil
        }
        
        if self.isImage || self.isVideo {
            return MessageThumbnailPreviewView(message: self)
        }
        else {
            return MessagePreviewView(message: self)
        }
    }
}

extension UITextView {
    fileprivate static func previewTextView() -> UITextView {
        let textView = UITextView()
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.textContainer.maximumNumberOfLines = 1
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        
        textView.isEditable = false
        textView.isSelectable = true
        
        textView.backgroundColor = .clear
        textView.textColor = .textForeground
        
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        return textView
    }
}

final class MessageThumbnailPreviewView: UIView {
    private let senderLabel = UILabel()
    private let contentTextView = UITextView.previewTextView()
    private let imagePreview = UIImageView()
    private var observerToken: Any? = nil

    let message: ZMConversationMessage
    
    init(message: ZMConversationMessage) {
        require(message.canBeQuoted)
        require(message.conversation != nil)
        self.message = message
        super.init(frame: .zero)
        setupSubviews()
        setupConstraints()
        setupMessageObserver()
        updateForMessage()
    }
    
    private func setupMessageObserver() {
        if let userSession = ZMUserSession.shared() {
            observerToken = MessageChangeInfo.add(observer: self,
                                                  for: message,
                                                  userSession: userSession)
        }
    }
    
    private func setupSubviews() {
        let allViews: [UIView] = [senderLabel, contentTextView, imagePreview]
        
        senderLabel.font = .mediumSemiboldFont
        senderLabel.textColor = .textForeground
        senderLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        imagePreview.clipsToBounds = true
        imagePreview.contentMode = .scaleAspectFill
        
        allViews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        allViews.forEach(self.addSubview)
    }
    
    private func setupConstraints() {
        
        let inset: CGFloat = 12
        
        NSLayoutConstraint.activate([
            senderLabel.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            senderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            senderLabel.trailingAnchor.constraint(equalTo: imagePreview.leadingAnchor, constant: inset),
            contentTextView.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: inset / 2),
            contentTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            contentTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            contentTextView.trailingAnchor.constraint(equalTo: imagePreview.leadingAnchor, constant: inset),
            imagePreview.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            imagePreview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            imagePreview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            imagePreview.widthAnchor.constraint(equalToConstant: 42),
            imagePreview.heightAnchor.constraint(equalToConstant: 42),
            ])
    }
    
    private func updateForMessage() {
        senderLabel.text = message.senderName
        
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.smallSemiboldFont,
                                                         .foregroundColor: UIColor.textForeground]
        
        if message.isImage {
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.smallSemiboldFont,
                                                             .foregroundColor: UIColor.textForeground]
            let imageIcon = NSTextAttachment.textAttachment(for: .photo, with: .textForeground, and: .medium)!
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + "conversation.input_bar.message_preview.image".localized.localizedUppercase
            contentTextView.attributedText = initialString && attributes
            
            if let data = message.imageMessageData?.imageData {
                imagePreview.image = UIImage(from: data, withMaxSize: 100)
            }
        }
        else if message.isVideo, let fileMessageData = message.fileMessageData {
            let imageIcon = NSTextAttachment.textAttachment(for: .videoMessage, with: .textForeground, and: .medium)!
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + "conversation.input_bar.message_preview.video".localized.localizedUppercase
            contentTextView.attributedText = initialString && attributes
            
            if let data = fileMessageData.previewData {
                imagePreview.image = UIImage(from: data, withMaxSize: 100)
            }
        }
        else {
            fatal("Unknown message for preview: \(message)")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MessageThumbnailPreviewView: ZMMessageObserver {
    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        updateForMessage()
    }
}

final class MessagePreviewView: UIView {
    private let senderLabel = UILabel()
    private let contentTextView = UITextView.previewTextView()
    private var observerToken: Any? = nil

    let message: ZMConversationMessage
    
    init(message: ZMConversationMessage) {
        require(message.canBeQuoted)
        require(message.conversation != nil)
        self.message = message
        super.init(frame: .zero)
        setupSubviews()
        setupConstraints()
        setupMessageObserver()
        updateForMessage()
    }
    
    private func setupMessageObserver() {
        if let userSession = ZMUserSession.shared() {
            observerToken = MessageChangeInfo.add(observer: self,
                                                  for: message,
                                                  userSession: userSession)
        }
    }
    
    private func setupSubviews() {
        let allViews: [UIView] = [senderLabel, contentTextView]
        
        senderLabel.font = .mediumSemiboldFont
        senderLabel.textColor = .textForeground
        senderLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        allViews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        allViews.forEach(self.addSubview)
    }
    
    private func setupConstraints() {
        let inset: CGFloat = 12

        NSLayoutConstraint.activate([
            senderLabel.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            senderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            senderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            contentTextView.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: inset / 2),
            contentTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            contentTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            contentTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
        ])
    }
    
    private func updateForMessage() {
        senderLabel.text = message.senderName

        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.smallSemiboldFont,
                                                         .foregroundColor: UIColor.textForeground]
        
        if let textMessageData = message.textMessageData {
            let hasNoText = textMessageData.messageText == nil || textMessageData.messageText!.isEmpty
            if hasNoText, let linkPreview = textMessageData.linkPreview {
                let font = UIFont.systemFont(ofSize: 14, contentSizeCategory: .medium, weight: .light)
                    contentTextView.attributedText = linkPreview.originalURLString && [.font: font,
                                                                                       .foregroundColor: UIColor.textForeground]
            }
            else {
                contentTextView.attributedText = NSAttributedString.formatForPreview(message: message.textMessageData!)
            }
        }
        else if let location = message.locationMessageData {
            
            let imageIcon = NSTextAttachment.textAttachment(for: .location, with: .textForeground, and: .medium)!
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + (location.name ?? "conversation.input_bar.message_preview.location".localized).localizedUppercase
            contentTextView.attributedText = initialString && attributes
        }
        else if message.isAudio {
            let imageIcon = NSTextAttachment.textAttachment(for: .microphone, with: .textForeground, and: .medium)!
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + "conversation.input_bar.message_preview.audio".localized.localizedUppercase
            contentTextView.attributedText = initialString && attributes
        }
        else if let fileData = message.fileMessageData {
            let imageIcon = NSTextAttachment.textAttachment(for: .document, with: .textForeground, and: .medium)!
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + (fileData.filename ?? "conversation.input_bar.message_preview.file".localized).localizedUppercase
            contentTextView.attributedText = initialString && attributes
        }
        else {
            fatal("Unknown message for preview: \(message)")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MessagePreviewView: ZMMessageObserver {
    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        // TODO: Observe text edits correctly
//        updateForMessage()
    }
}
