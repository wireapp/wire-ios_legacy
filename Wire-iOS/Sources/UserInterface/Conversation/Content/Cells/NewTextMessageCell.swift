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
    let formattedText: NSAttributedString
    let linkAttachment: LinkAttachment?
    let configuration: TextMessageCellConfiguration
    
    init (message: ZMConversationMessage, context: MessageCellContext) {
        guard let textMessageData = message.textMessageData else { fatal("Boom" )} // TODO jacob move textMessageData into initializer
        
        var configuration = MessageCellConfiguration(context: context)
        
        if message.updatedAt != nil {
            configuration.insert(.showSender)
        }
    
        var lastLinkAttachment: LinkAttachment = LinkAttachment(url: URL(fileURLWithPath: "/"), range: NSRange(location: 0, length: 0), string: "")
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: message.isObfuscated, linkAttachment: &lastLinkAttachment)
        var linkAttachment: LinkAttachment? = lastLinkAttachment
        
        var attachment: TextMessageCellConfiguration.Attachment = .none
        if textMessageData.linkPreview != nil {
            attachment = .linkPreview
            linkAttachment = nil
        } else {
            switch lastLinkAttachment.type {
            case .none:
                attachment = .none
            case .soundcloudSet, .soundcloudTrack:
                attachment = .soundcloud
            case .youtubeVideo:
                attachment = .youtube
            }
        }
        
        self.context = context
        self.message = message
        self.formattedText = formattedText
        self.linkAttachment = linkAttachment
        self.configuration = TextMessageCellConfiguration(configuration: configuration, attachment: attachment)
    }
    
    func cell(tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell: ConfigurableCellTableViewAdapter<NewTextMessageCell> = tableView.dequeueConfigurableCell(configuration: configuration, for: indexPath)
        cell.configure(with: self)
        return cell
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
        
        textContentView.configure(with: content.formattedText,
                                  textMessageData: textMessageData,
                                  linkAttachment: content.linkAttachment,
                                  isObfuscated: content.message.isObfuscated)
    }
    
}
