//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@objc enum CollectionItemType : UInt, RawRepresentable {
    case image = 0
    case link = 1
    case file = 2
    case video = 3
    case audio = 4
}

extension CollectionItemType {
    init(message: ZMConversationMessage) {
        if Message.isImageMessage(message) {
            self = .image
        }
        else if Message.isVideoMessage(message) {
            self = .video
        }
        else if Message.isAudioMessage(message) {
            self = .audio
        }
        else if Message.isFileTransferMessage(message) {
            self = .file
        }
        else if let _ = message.textMessageData?.linkPreview {
            self = .link
        }
        else {
            fatal("Unknown message type")
        }
    }
}

fileprivate func string(for itemType: CollectionItemType) -> String {
    switch itemType {
    case .image:
        return "image"
    case .link:
        return "link"
    case .file:
        return "file"
    case .video:
        return "video"
    case .audio:
        return "audio"
    }
}

@objc enum CollectionActionType : UInt, RawRepresentable {
    case forward = 0
    case goto = 1
}

fileprivate func string(for actionType: CollectionActionType) -> String
{
    switch actionType {
    case .forward:
        return "forward"
    case .goto:
        return "goto"
    }
}

extension ZMConversation {
    fileprivate var conversationAttributes : [String : String] {
        var attributes = [String: String]()
        let isBot = self.isBotConversation ? "true" : "false"
        attributes["with_bot"] = isBot
        if let convType = self.analyticsTypeString() {
            attributes["conversation_type"] = convType
        }
        
        return attributes
    }
}

extension Analytics {
    
    @objc(tagCollectionOpenForConversation:withItemCount:withSearchResults:)
    func tagCollectionOpen(for conversation:ZMConversation, itemCount: UInt, withSearchResults: Bool)
    {
        var attributes = conversation.conversationAttributes
        attributes["is_empty"] = itemCount == 0 ? "true" : "false"
        attributes["with_search_result"] = withSearchResults ? "true" : "false" // Whether the collection is pre-filled with existing search

        tagEvent("collections.opened_collections", attributes:attributes)
    }
    
    @objc(tagCollectionOpenItemForConversation:withItemType:)
    func tagCollectionOpenItem(for conversation:ZMConversation, itemType:CollectionItemType)
    {
        var attributes = conversation.conversationAttributes
        attributes["type"] = string(for: itemType)
        
        
        tagEvent("collections.opened_item", attributes:attributes)
    }
    
    @objc(tagCollectionOpenItemMenyForConversation:withItemType:)
    func tagCollectionOpenItemMenu(for conversation:ZMConversation, itemType: CollectionItemType)
    {
        var attributes = conversation.conversationAttributes
        attributes["type"] = string(for: itemType)
        
        tagEvent("collections.opened_item_menu", attributes:attributes)
    }
    
    @objc(tagCollectionDidItemActionForConversation:withItemType:actionType:)
    func tagCollectionDidItemAction(for conversation:ZMConversation, itemType:CollectionItemType, action: CollectionActionType)
    {
        var attributes = conversation.conversationAttributes
        
        attributes["type"] = string(for: itemType)
        attributes["action"] = string(for: action)
        
        tagEvent("collections.did_item_action", attributes:attributes)
    }
}
