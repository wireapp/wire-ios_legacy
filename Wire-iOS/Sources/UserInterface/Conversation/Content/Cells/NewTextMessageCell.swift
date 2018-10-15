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

class NewTextMessageCell: UIView, ConfigurableCell {
    
    typealias Content = ZMConversationMessage
    typealias Description = TextCellDescription
    
    let textView: LinkInteractionTextView = LinkInteractionTextView()
    var senderView: SenderView?
    var burstTimestampView: ConversationCellBurstTimestampView?
    var articleView: ArticleView?
    var mediaPreviewController: MediaPreviewViewController?
    var audioTrackViewController: AudioTrackViewController?
    var audioPlaylistViewController: AudioPlaylistViewController?
    
    required init(from description: TextCellDescription) {
        super.init(frame: .zero)
        
        var layout: [(UIView, UIEdgeInsets)] = []
        
        if description.common.contains(.showBurstTimestamp) {
            let burstTimestampView = ConversationCellBurstTimestampView()
            layout.append((burstTimestampView, UIEdgeInsets.zero))
            self.burstTimestampView = burstTimestampView
        }
        
        if description.common.contains(.showSender) {
            let senderView = SenderView()
            layout.append((senderView, UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)))
            self.senderView = senderView
        }
        
        layout.append((textView, UIView.conversationLayoutMargins))
        
        switch description.attachment {
        case .linkPreview:
            let articleView = ArticleView(withImagePlaceholder: true)
            self.articleView = articleView
            layout.append((articleView, UIView.conversationLayoutMargins))
        case .youtube:
            mediaPreviewController = MediaPreviewViewController()
        default:
            break
        }
        
        layout.forEach({ (view, _) in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        })
        
        configureViews()
        createConstraints(layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureViews() {
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
    }
    
    func configure(with content: ZMConversationMessage) {
        guard let textMessageData = content.textMessageData else { return }
        
        if let sender = content.sender {
            senderView?.configure(with: sender)
        }
        
        burstTimestampView?.label.text = Message.formattedReceivedDate(for: content).uppercased()
        burstTimestampView?.isSeparatorExpanded = true
        
        var lastLinkAttachment: LinkAttachment = LinkAttachment(url: URL(fileURLWithPath: "/"), range: NSRange(location: 0, length: 0), string: "")
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: content.isObfuscated, linkAttachment: &lastLinkAttachment)
        textView.attributedText = formattedText
        articleView?.configure(withTextMessageData: textMessageData, obfuscated: content.isObfuscated)
    }
    
}
