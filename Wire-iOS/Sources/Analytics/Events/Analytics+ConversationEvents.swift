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


import Foundation
import WireSyncEngine

public extension ReactionType {
    var analyticsTypeString : String {
        switch self {
        case .undefined:    return "undefined"
        case .like:         return "like"
        case .unlike:       return "unlike"
        }
    }
}

public extension InteractionMethod {
    var analyticsTypeString : String {
        switch self {
        case .undefined:    return "undefined"
        case .button:       return "button"
        case .menu:         return "menu"
        case .doubleTap:    return "double-tap"
        }
    }
}

public extension Analytics {
    
    public func tagReactedOnMessage(_ message: ZMConversationMessage, reactionType:ReactionType, method: InteractionMethod) {
        guard let conversation = message.conversation,
            let sender = message.sender,
            let lastMessage = (conversation.messages.lastObject as? ZMMessage),
            let zmMessage = message as? ZMMessage
            else { return }
        
        var attributes = [
            "type"                    : Message.messageType(message).analyticsTypeString,
            "action"                  : reactionType.analyticsTypeString,
            "method"                  : method.analyticsTypeString,
            "with_service"            : (conversation.includesServiceUser ? "true" : "false"),
            "user"                    : (sender.isSelfUser                ? "sender" : "receiver"),
            "reacted_to_last_message" : (lastMessage == zmMessage         ? "true"   : "false")
        ]

        if let convType = ConversationType.type(conversation) {
            attributes["conversation_type"] = convType.analyticsTypeString
        }
        
        tagEvent("conversation.reacted_to_message", attributes:attributes)
    }
}

public enum ConversationEvent: Event {

    static let toggleAllowGuestsName = "guest_rooms.allow_guests"

    case toggleAllowGuests(value: Bool)

    var attributes: [AnyHashable : Any]? {
        switch self {
        case let .toggleAllowGuests(value: value):
            return ["is_allow_guests" : value]
        }
    }

    var name: String {
        switch self {
        case .toggleAllowGuests:
            return ConversationEvent.toggleAllowGuestsName
        }
    }
}

extension Analytics {
    public func tagAllowGuests(value: Bool) {
        tag(ConversationEvent.toggleAllowGuests(value: value))
    }
}
