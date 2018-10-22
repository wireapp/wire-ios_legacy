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

class TextMessageContentView: UIView {
    
    let textView: LinkInteractionTextView = LinkInteractionTextView()
    var articleView: ArticleView?
    var mediaPreviewController: MediaPreviewViewController?
    
    override var firstBaselineAnchor: NSLayoutYAxisAnchor {
        return textView.firstBaselineAnchor
    }
    
    required init(from description: TextMessageCellConfiguration) {
        super.init(frame: .zero)
        
        var layout: [(UIView, UIEdgeInsets)] = []
        
        layout.append((textView, .zero))
        
        switch description.attachment {
        case .linkPreview:
            let articleView = ArticleView(withImagePlaceholder: true)
            self.articleView = articleView
            layout.append((articleView, .zero))
        case .youtube:
            let mediaPreviewController = MediaPreviewViewController()
            self.mediaPreviewController = mediaPreviewController
            layout.append((mediaPreviewController.view, .zero))
        default:
            break
        }
        
        layout.forEach({ (view, _) in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        })
        
        arrangeSubviews(layout)
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
    
    func configure(with text: NSAttributedString, textMessageData: ZMTextMessageData, linkAttachment: LinkAttachment?, isObfuscated: Bool) { // TODO jacob clean this up
        textView.attributedText = text // TODO handle isObfuscated
        articleView?.configure(withTextMessageData: textMessageData, obfuscated: isObfuscated)
        
        if let linkAttachment = linkAttachment {
            mediaPreviewController?.linkAttachment = linkAttachment
            mediaPreviewController?.fetchAttachment()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
