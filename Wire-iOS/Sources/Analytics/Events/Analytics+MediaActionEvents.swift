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


@objc public enum ConversationMediaAction: UInt {
    case Text, Photo, AudioCall, VideoCall, Gif, Sketch, Ping, FileTransfer, VideoMessage, AudioMessage, Location
    
    var attributeValue: String {
        switch self {
        case .Text:         return "text"
        case .Photo:        return "photo"
        case .AudioCall:    return "audio_call"
        case .VideoCall:    return "video_call"
        case .Gif:          return "giphy"
        case .Sketch:       return "sketch"
        case .Ping:         return "ping"
        case .FileTransfer: return "file_transfer"
        case .VideoMessage: return "video_message"
        case .AudioMessage: return "audio_message"
        case .Location:     return "location"
        }
    }
}

@objc public enum ConversationMediaOpenEvent: UInt {
    case Location
    
    private var nameSuffix: String {
        switch self {
        case .Location: return "opened_shared_location"
        }
    }
    
    var name: String {
        return "media." + nameSuffix
    }
}

@objc public enum ConversationMediaRecordingType: UInt, CustomStringConvertible {
    case Minimised, Keyboard
    
    public var description: String {
        switch self {
        case .Minimised:
            return "minimised"
        case .Keyboard:
            return "keyboard"
        }
    }
}

extension AudioMessageContext {
    static let keyName = "context"
    
    var attributeString: String {
        switch self {
        case .AfterPreview: return "after_preview"
        case .AfterSlideUp: return "slide_up"
        case .AfterEffect:  return "effect"
        }
    }
}

let conversationMediaActionEventName                         = "media.opened_action"
let conversationMediaCompleteActionEventName                 = "media.completed_media_action"
let conversationMediaSentVideoMessageEventName               = "media.sent_video_message"
let conversationMediaPlayedVideoMessageEventName             = "media.played_video_message"
let conversationMediaStartedRecordingAudioEventName          = "media.started_recording_audio_message"
let conversationMediaCancelledRecordingAudioMessageEventName = "media.cancelled_recording_audio_message"
let conversationMediaPreviewedAudioMessageEventName          = "media.previewed_audio_message"
let conversationMediaSentAudioMessageEventName               = "media.sent_audio_message"
let conversationMediaPlayedAudioMessageEventName             = "media.played_audio_message"

let videoDurationClusterizer: TimeIntervalClusterizer = {
    return TimeIntervalClusterizer.videoDurationClusterizer()
}()

public extension Analytics {
    
    private func conversationTypeAttribute(conversation: ZMConversation) -> String? {
        if conversation.conversationType == .OneOnOne {
            return "one_to_one"
        }
        
        if conversation.conversationType == .Group {
            return "group"
        }
        
        return nil
    }

    /// User clicked on any action in cursor, giphy button or audio / video call button from toolbar.
    @objc public func tagMediaAction(action: ConversationMediaAction, inConversation conversation: ZMConversation) {
        var attributes = ["action": action.attributeValue]
        if let typeAttribute = conversationTypeAttribute(conversation) {
            attributes["conversation_type"] = typeAttribute
        }
        tagEvent(conversationMediaActionEventName, attributes: attributes)
    }
    
    @objc public func tagMediaActionCompleted(action: ConversationMediaAction, inConversation conversation: ZMConversation) {
        var attributes = ["action": action.attributeValue]
        if let typeAttribute = conversationTypeAttribute(conversation) {
            attributes["with_otto"] = conversation.firstActiveParticipantOtherThanSelf().isOtto ? "true" : "false";
            attributes["conversation_type"] = typeAttribute
        }
        tagEvent(conversationMediaCompleteActionEventName, attributes: attributes)
    }
    @objc public func tagMediaOpened(event: ConversationMediaOpenEvent, inConversation conversation: ZMConversation, sentBySelf: Bool) {
        var attributes = ["user": sentBySelf ? "sender" : "receiver"]
        if let typeAttribute = conversationTypeAttribute(conversation) {
            attributes["conversation_type"] = typeAttribute
        }
        tagEvent(event.name, attributes: attributes)
    }
    
    private class func stringFromTimeInterval(interval: NSTimeInterval) -> String {
        return NSString(format: "%.0f", interval) as String
    }
    
    /// User uploads video message
    @objc public func tagSentVideoMessage(duration: NSTimeInterval) {
        let attributes = ["duration": videoDurationClusterizer.clusterizeTimeInterval(duration),
                          "duration_actual": self.dynamicType.stringFromTimeInterval(duration)]
        tagEvent(conversationMediaSentVideoMessageEventName, attributes: attributes)
    }

    /// User plays a video message
    @objc public func tagPlayedVideoMessage(duration: NSTimeInterval) {
        let attributes = ["duration": videoDurationClusterizer.clusterizeTimeInterval(duration),
                          "duration_actual": self.dynamicType.stringFromTimeInterval(duration)]
        tagEvent(conversationMediaPlayedVideoMessageEventName, attributes: attributes)
    }
    
    // User starts recording the audio message
    @objc public func tagStartedAudioMessageRecording(inConversation conversation: ZMConversation, type: ConversationMediaRecordingType) {
        var attributes = ["state": type.description]
        if let typeAttribute = conversationTypeAttribute(conversation) {
            attributes["conversation_type"] = typeAttribute
        }
        tagEvent(conversationMediaStartedRecordingAudioEventName, attributes: attributes)
    }
    
    // User cancels the recorded audio message
    @objc public func tagCancelledAudioMessageRecording() {
        tagEvent(conversationMediaCancelledRecordingAudioMessageEventName)
    }
    
    // User previews the recorded audio message
    @objc public func tagPreviewedAudioMessageRecording(type: ConversationMediaRecordingType) {
        let attributes = ["state": type.description]
        tagEvent(conversationMediaPreviewedAudioMessageEventName, attributes: attributes)
    }
    
    /// User uploads an audio message
    public func tagSentAudioMessage(duration: NSTimeInterval, context: AudioMessageContext, filter: AVSAudioEffectType, type: ConversationMediaRecordingType) {
        let filterName = filter.description.lowercaseString
        let attributes = ["duration": videoDurationClusterizer.clusterizeTimeInterval(duration),
                          "duration_actual": self.dynamicType.stringFromTimeInterval(duration),
                          AudioMessageContext.keyName: context.attributeString,
                          "filter": filterName,
                          "state": type.description]
        tagEvent(conversationMediaSentAudioMessageEventName, attributes: attributes)
    }
    
    /// User plays an audio message
    @objc public func tagPlayedAudioMessage(duration: NSTimeInterval, extensionString: String) {
        let attributes = ["duration": videoDurationClusterizer.clusterizeTimeInterval(duration),
                          "duration_actual": self.dynamicType.stringFromTimeInterval(duration),
                          "type": extensionString]
        tagEvent(conversationMediaPlayedAudioMessageEventName, attributes: attributes)
    }
    
}
