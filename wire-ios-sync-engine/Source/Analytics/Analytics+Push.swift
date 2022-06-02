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

extension AnalyticsType {

    public func tagActionOnPushNotification(conversation: ZMConversation?, action: ConversationMediaAction) {
        guard let conversation = conversation else { return }
        var attributes = conversation.ephemeralTrackingAttributes
        attributes["action"] = action.attributeValue
        attributes["conversation_type"] = conversation.conversationType.analyticsType
        attributes["with_service"] = conversation.includesServiceUser ? "true" : "false"
        tagEvent("contributed", attributes: attributes as! [String: NSObject])
    }

}

public extension ZMConversation {

    @objc
    var ephemeralTrackingAttributes: [String: Any] {
        if let timeout = activeMessageDestructionTimeoutValue {
            return [
                "is_ephemeral": true,
                "ephemeral_time": Int(timeout.rawValue)
            ]
        } else {
            return ["is_ephemeral": false]
        }
    }

    /// Whether the conversation includes at least 1 service user.
    @objc
    var includesServiceUser: Bool {
        return localParticipants.any { $0.isServiceUser }
    }
}

extension ZMConversationType {

     var analyticsType: String {
        switch self {
        case .oneOnOne:
            return "one_to_one"
        case .group:
            return "group"
        default:
            return ""
        }
    }
}

public enum ConversationMediaAction: UInt {
    case text, photo, audioCall, videoCall, gif, ping, fileTransfer, videoMessage, audioMessage, location

    public var attributeValue: String {
        switch self {
        case .text:         return "text"
        case .photo:        return "photo"
        case .audioCall:    return "audio_call"
        case .videoCall:    return "video_call"
        case .gif:          return "giphy"
        case .ping:         return "ping"
        case .fileTransfer: return "file"
        case .videoMessage: return "video"
        case .audioMessage: return "audio"
        case .location:     return "location"
        }
    }
}
