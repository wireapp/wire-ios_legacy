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

@objc public enum ConversationMediaPictureSource: UInt {
    case Gallery, Camera, Sketch, Giphy, Sharing, Clip, Paste
    
    static let attributeName = "source"
    
    var attributeValue: String {
        switch self {
        case .Gallery:  return "gallery"
        case .Camera:   return "camera"
        case .Sketch:   return "sketch"
        case .Giphy:    return "giphy"
        case .Sharing:  return "sharing"
        case .Clip:     return "clip"
        case .Paste:    return "paste"
        }
    }
}

@objc public enum ConversationMediaPictureTakeMethod: UInt {
    case None, Keyboard, FullFromKeyboard, QuickMenu
    
    static let attributeName = "method"
    
    var attributeValue: String {
        switch self {
        case .None:             return ""
        case .Keyboard:         return "keyboard"
        case .FullFromKeyboard: return "full_screen"
        case .QuickMenu:        return "quick_menu"
        }
    }
}

public extension ConversationMediaSketchSource {
    static let attributeName = "sketch_source"
    
    var attributeValue: String {
        switch self {
        case .None:          return ""
        case .SketchButton:  return "sketch_button"
        case .CameraGallery: return "camera_gallery"
        case .ImageFullView: return "image_full_view"
        }
    }
}

@objc public enum ConversationMediaPictureCamera: UInt {
    case None, Front, Back
    
    static let attributeName = "camera"
    
    init (camera: UIImagePickerControllerCameraDevice) {
        switch camera {
        case .Front:
            self = .Front
        case .Rear:
            self = .Back
        }
    }
    
    var attributeValue: String {
        switch self {
        case .None:  return ""
        case .Front: return "front"
        case .Back:  return "back"
        }
    }
}

@objc public enum ConversationMediaVideoContext: UInt {
    case CursorButton, FullCameraKeyboard, CameraKeyboard
    
    static let attributeName = "context"
    
    var attributeValue: String {
        switch self {
        case .CursorButton:         return "cursor_button"
        case .FullCameraKeyboard:   return "full_screen"
        case .CameraKeyboard:       return "gallery"
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

@objc public class ImageMetadata: NSObject { // could be struct in swift-only environment
    var source: ConversationMediaPictureSource = .Gallery
    var method: ConversationMediaPictureTakeMethod = .None
    var sketchSource: ConversationMediaSketchSource = .None
    var camera: ConversationMediaPictureCamera = .None
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
let conversationMediaSentPictureEventName                    = "media.sent_picture"

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
            attributes["with_bot"] = conversation.firstActiveParticipantOtherThanSelf().isBot ? "true" : "false";
            attributes["conversation_type"] = typeAttribute
        }
        tagEvent(conversationMediaCompleteActionEventName, attributes: attributes)
    }

    @objc public func tagMediaSentPictureSourceCamera(inConversation conversation: ZMConversation, method: ConversationMediaPictureTakeMethod, camera: ConversationMediaPictureCamera) {
        self.tagMediaSentPicture(inConversation: conversation, source: .Camera, method: method, sketchSource: .None, camera: camera)
    }
    
    @objc public func tagMediaSentPictureSourceSketch(inConversation conversation: ZMConversation, sketchSource: ConversationMediaSketchSource) {
        self.tagMediaSentPicture(inConversation: conversation, source: .Sketch, method: .None, sketchSource: sketchSource, camera: .None)
    }
    
    @objc public func tagMediaSentPictureSourceOther(inConversation conversation: ZMConversation, source: ConversationMediaPictureSource) {
        self.tagMediaSentPicture(inConversation: conversation, source: source, method: .None, sketchSource: .None, camera: .None)
    }
    
    private func tagMediaSentPicture(inConversation conversation: ZMConversation, source: ConversationMediaPictureSource, method: ConversationMediaPictureTakeMethod, sketchSource: ConversationMediaSketchSource, camera: ConversationMediaPictureCamera) {
        let metadata = ImageMetadata()
        metadata.source = source
        metadata.method = method
        metadata.sketchSource = sketchSource
        metadata.camera = camera
        self.tagMediaSentPicture(inConversation: conversation, metadata: metadata)
    }
    
    @objc public func tagMediaSentPicture(inConversation conversation: ZMConversation, metadata: ImageMetadata) {
        var attributes = [String: String]()
        if let typeAttribute = conversationTypeAttribute(conversation) {
            attributes["conversation_type"] = typeAttribute
        }
        
        attributes[ConversationMediaPictureSource.attributeName] = metadata.source.attributeValue
        if metadata.method != .None {
            attributes[ConversationMediaPictureTakeMethod.attributeName] = metadata.method.attributeValue
        }
        
        if metadata.source == .Sketch {
            attributes[ConversationMediaSketchSource.attributeName] = metadata.sketchSource.attributeValue
        }
        else if metadata.source == .Camera {
            attributes[ConversationMediaPictureCamera.attributeName] = metadata.camera.attributeValue
        }
        
        tagEvent(conversationMediaSentPictureEventName, attributes: attributes)
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
    @objc public func tagSentVideoMessage(inConversation conversation: ZMConversation, context: ConversationMediaVideoContext, duration: NSTimeInterval) {
        var attributes = ["duration": videoDurationClusterizer.clusterizeTimeInterval(duration),
                          "duration_actual": self.dynamicType.stringFromTimeInterval(duration)]
        
        if let typeAttribute = conversationTypeAttribute(conversation) {
            attributes["conversation_type"] = typeAttribute
        }
        
        attributes[ConversationMediaVideoContext.attributeName] = context.attributeValue
        
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
