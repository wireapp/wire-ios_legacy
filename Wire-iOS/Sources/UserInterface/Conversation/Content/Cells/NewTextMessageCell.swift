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

typealias ViewLayout = (UIView, UIEdgeInsets)

class MessageCell: UIView {
    
    var senderView: SenderView?
    var burstTimestampView: ConversationCellBurstTimestampView?
    let toolboxView: MessageToolboxView = MessageToolboxView()
    var ephemeralCountdownView: DestructionCountdownView?
    
    var isSelected: Bool = false {
        didSet {
            toolboxView.setHidden(!isSelected, animated: true)
        }
    }
    
    init(from description: CommonCellDescription, content: UIView, fullWidthContent: UIView? = nil) {
        super.init(frame: .zero)
        
        var layout: [(UIView, UIEdgeInsets)] = []
        
        if description.contains(.showBurstTimestamp) {
            let burstTimestampView = ConversationCellBurstTimestampView()
            layout.append((burstTimestampView, UIEdgeInsets.zero))
            self.burstTimestampView = burstTimestampView
        }
        
        if description.contains(.showSender) {
            let senderView = SenderView()
            layout.append((senderView, UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)))
            self.senderView = senderView
        }
        
        layout.append((content, UIView.conversationLayoutMargins))
        
        if let fullWithContent = fullWidthContent {
            layout.append((fullWithContent, .zero))
        }
        
        layout.append((toolboxView, UIView.conversationLayoutMargins))
        
        layout.forEach({ (view, _) in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        })
        
        createConstraints(layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func configure(with message: ZMConversationMessage) {
        if let sender = message.sender {
            senderView?.configure(with: sender)
        }
        
        burstTimestampView?.label.text = Message.formattedReceivedDate(for: message).uppercased()
        burstTimestampView?.isSeparatorExpanded = true
        toolboxView.configureForMessage(message, forceShowTimestamp: false, animated: false)
        toolboxView.setHidden(!isSelected, animated: false)
    }
    
}

class TextMessageContentView: UIView {
    
    let textView: LinkInteractionTextView = LinkInteractionTextView()
    var articleView: ArticleView?
    var mediaPreviewController: MediaPreviewViewController?
    
    required init(from description: TextCellDescription) {
        super.init(frame: .zero)
        
        var layout: [(UIView, UIEdgeInsets)] = []
        
        layout.append((textView, .zero))
        
        switch description.attachment {
        case .linkPreview:
            let articleView = ArticleView(withImagePlaceholder: true)
            self.articleView = articleView
            layout.append((articleView, .zero))
        case .youtube:
            mediaPreviewController = MediaPreviewViewController()
        default:
            break
        }
        
        layout.forEach({ (view, _) in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        })
        
        createConstraints(layout)
        setupViews()
    }
    
    func setupViews() {
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = UIColor(scheme: .contentBackground)
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isUserInteractionEnabled = true
        textView.accessibilityIdentifier = "Message"
        textView.accessibilityElementsHidden = false
        textView.dataDetectorTypes = [.link, .address, .phoneNumber, .flightNumber, .calendarEvent, .shipmentTrackingNumber]
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    func configure(with textMessageData: ZMTextMessageData, isObfuscated: Bool) {
        var lastLinkAttachment: LinkAttachment = LinkAttachment(url: URL(fileURLWithPath: "/"), range: NSRange(location: 0, length: 0), string: "")
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: isObfuscated, linkAttachment: &lastLinkAttachment)
        textView.attributedText = formattedText
        articleView?.configure(withTextMessageData: textMessageData, obfuscated: isObfuscated)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class NewTextMessageCell: MessageCell, ConfigurableCell {
    
    typealias Content = ZMConversationMessage
    typealias Description = TextCellDescription
    
    let textContentView: TextMessageContentView
    var audioTrackViewController: AudioTrackViewController?
    var audioPlaylistViewController: AudioPlaylistViewController?
    
    required init(from description: TextCellDescription) {
        
        textContentView = TextMessageContentView(from: description)
        
        super.init(from: description.common, content: textContentView, fullWidthContent: audioTrackViewController?.view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure(with content: ZMConversationMessage) {
        super.configure(with: content)
        
        guard let textMessageData = content.textMessageData else { return }
        
        textContentView.configure(with: textMessageData, isObfuscated: content.isObfuscated)
    }
    
}
