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



struct TextMessageCellConfiguration: Equatable {
    
    enum Attachment: Int, Codable, CaseIterable {
        case none
        case linkPreview
        case youtube
        case soundcloud
    }
    
    var attachment: Attachment = .none
    var configuration: MessageCellConfiguration
    
    static var variants: [TextMessageCellConfiguration] {
        
        var variants: [TextMessageCellConfiguration] = []
        
        MessageCellConfiguration.allCases.forEach { configuration in
            Attachment.allCases.forEach { attachment in
                variants.append(TextMessageCellConfiguration(configuration: configuration, attachment: attachment))
            }
        }
        
        return variants
    }
    
    init(configuration: MessageCellConfiguration, attachment: Attachment) {
        self.configuration = configuration
        self.attachment = attachment
    }
    
}

struct TextMessageCellDescription: CellDescription {
    
    let context: MessageCellContext
    let message: ZMConversationMessage
    let configuration: TextMessageCellConfiguration
    
    init (message: ZMConversationMessage, context: MessageCellContext) {
        var configuration = MessageCellConfiguration(context: context)
        
        if message.updatedAt != nil {
            configuration.insert(.showSender)
        }
        
        self.context = context
        self.message = message
        self.configuration = TextMessageCellConfiguration(configuration: configuration, attachment: .none)
    }
    
    func cell(tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewConfigurableCellAdapter<NewTextMessageCell> = tableView.dequeueConfigurableCell(configuration: configuration, for: indexPath)
        cell.configure(with: self)
        return cell
    }
    
}

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
    
    typealias Content = TextMessageCellDescription
    typealias Configuration = TextMessageCellConfiguration
    
    let textContentView: TextMessageContentView
    var audioTrackViewController: AudioTrackViewController?
    var audioPlaylistViewController: AudioPlaylistViewController?
    
    static var mapping : [String : TextMessageCellConfiguration] = {
        var mapping: [String : TextMessageCellConfiguration] = [:]
        
        for (index, variant) in TextMessageCellConfiguration.variants.enumerated() {
            mapping["\(NSStringFromClass(NewTextMessageCell.self))_\(index)"] = variant
        }
        
        return mapping
    }()
        
    required init(from configuration: TextMessageCellConfiguration) {        
        textContentView = TextMessageContentView(from: configuration)
        
        super.init(from: configuration.configuration, content: textContentView, fullWidthContent: audioTrackViewController?.view)
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with content: TextMessageCellDescription) {
        super.configure(with: content.message, context: content.context)
        
        guard let textMessageData = content.message.textMessageData else { return }
        
        textContentView.configure(with: textMessageData, isObfuscated: content.message.isObfuscated)
    }
    
}
