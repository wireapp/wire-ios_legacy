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
    case text, photo, audioCall, videoCall, gif, sketch, ping, fileTransfer, videoMessage, audioMessage, location, ephemeral
    
    var attributeValue: String {
        switch self {
        case .text:         return "text"
        case .photo:        return "photo"
        case .audioCall:    return "audio_call"
        case .videoCall:    return "video_call"
        case .gif:          return "giphy"
        case .sketch:       return "sketch"
        case .ping:         return "ping"
        case .fileTransfer: return "file_transfer"
        case .videoMessage: return "video_message"
        case .audioMessage: return "audio_message"
        case .location:     return "location"
        case .ephemeral:    return "ephemeral"
        }
    }
}

@objc public enum ConversationMediaPictureSource: UInt {
    case gallery, camera, sketch, giphy, sharing, clip, paste
    
    static let attributeName = "source"
    
    var attributeValue: String {
        switch self {
        case .gallery:  return "gallery"
        case .camera:   return "camera"
        case .sketch:   return "sketch"
        case .giphy:    return "giphy"
        case .sharing:  return "sharing"
        case .clip:     return "clip"
        case .paste:    return "paste"
        }
    }
}

@objc public enum ConversationMediaPictureTakeMethod: UInt {
    case none, keyboard, fullFromKeyboard, quickMenu
    
    static let attributeName = "method"
    
    var attributeValue: String {
        switch self {
        case .none:             return ""
        case .keyboard:         return "keyboard"
        case .fullFromKeyboard: return "full_screen"
        case .quickMenu:        return "quick_menu"
        }
    }
}

public extension ConversationMediaSketchSource {
    static let attributeName = "sketch_source"
    
    var attributeValue: String {
        switch self {
        case .none:          return ""
        case .sketchButton:  return "sketch_button"
        case .cameraGallery: return "camera_gallery"
        case .imageFullView: return "image_full_view"
        }
    }
}

@objc public enum ConversationMediaPictureCamera: UInt {
    case none, front, back
    
    static let attributeName = "camera"
    
    init (camera: UIImagePickerControllerCameraDevice) {
        switch camera {
        case .front:
            self = .front
        case .rear:
            self = .back
        }
    }
    
    var attributeValue: String {
        switch self {
        case .none:  return ""
        case .front: return "front"
        case .back:  return "back"
        }
    }
}

@objc public enum ConversationMediaVideoContext: UInt {
    case cursorButton, fullCameraKeyboard, cameraKeyboard
    
    static let attributeName = "context"
    
    var attributeValue: String {
        switch self {
        case .cursorButton:         return "cursor_button"
        case .fullCameraKeyboard:   return "full_screen"
        case .cameraKeyboard:       return "gallery"
        }
    }
}

@objc public enum ConversationMediaOpenEvent: UInt {
    case location
    
    fileprivate var nameSuffix: String {
        switch self {
        case .location: return "opened_shared_location"
        }
    }
    
    var name: String {
        return "media." + nameSuffix
    }
}

@objc public enum ConversationMediaRecordingType: UInt, CustomStringConvertible {
    case minimised, keyboard
    
    public var description: String {
        switch self {
        case .minimised:
            return "minimised"
        case .keyboard:
            return "keyboard"
        }
    }
}

@objc open class ImageMetadata: NSObject { // could be struct in swift-only environment
    var source: ConversationMediaPictureSource = .gallery
    var method: ConversationMediaPictureTakeMethod = .none
    var sketchSource: ConversationMediaSketchSource = .none
    var camera: ConversationMediaPictureCamera = .none
}

extension AudioMessageContext {
    static let keyName = "context"
    
    var attributeString: String {
        switch self {
        case .afterPreview: return "after_preview"
        case .afterSlideUp: return "slide_up"
        case .afterEffect:  return "effect"
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
    return TimeIntervalClusterizer.videoDuration()
}()


public extension ZMConversation {

    var ephemeralTrackingAttributes: [String: String] {
        let ephemeral = destructionTimeout != .none
        var attributes = ["is_ephemeral": ephemeral ? "true" : "false"]
        guard ephemeral else { return attributes }
        attributes["ephemeral_time"] = "\(Int(destructionTimeout.rawValue))"
        return attributes
    }

}


public extension Analytics {

    /// User clicked on any action in cursor, giphy button or audio / video call button from toolbar.
    @objc public func tagMediaAction(_ action: ConversationMediaAction, inConversation conversation: ZMConversation) {
        var attributes = ["action": action.attributeValue]
        if let typeAttribute = conversation.analyticsTypeString() {
            attributes["conversation_type"] = typeAttribute
        }
        tagEvent(conversationMediaActionEventName, attributes: attributes)
    }
    
    @objc public func tagMediaActionCompleted(_ action: ConversationMediaAction, inConversation conversation: ZMConversation) {
        var attributes = conversation.ephemeralTrackingAttributes
        attributes["action"] = action.attributeValue

        if let typeAttribute = conversation.analyticsTypeString() {
            attributes["with_bot"] = conversation.isBotConversation ? "true" : "false";
            attributes["conversation_type"] = typeAttribute
        }
        tagEvent(conversationMediaCompleteActionEventName, attributes: attributes)
    }

    @objc public func tagMediaSentPictureSourceCamera(inConversation conversation: ZMConversation, method: ConversationMediaPictureTakeMethod, camera: ConversationMediaPictureCamera) {
        self.tagMediaSentPicture(inConversation: conversation, source: .camera, method: method, sketchSource: .none, camera: camera)
    }
    
    @objc public func tagMediaSentPictureSourceSketch(inConversation conversation: ZMConversation, sketchSource: ConversationMediaSketchSource) {
        self.tagMediaSentPicture(inConversation: conversation, source: .sketch, method: .none, sketchSource: sketchSource, camera: .none)
    }
    
    @objc public func tagMediaSentPictureSourceOther(inConversation conversation: ZMConversation, source: ConversationMediaPictureSource) {
        self.tagMediaSentPicture(inConversation: conversation, source: source, method: .none, sketchSource: .none, camera: .none)
    }
    
    fileprivate func tagMediaSentPicture(inConversation conversation: ZMConversation, source: ConversationMediaPictureSource, method: ConversationMediaPictureTakeMethod, sketchSource: ConversationMediaSketchSource, camera: ConversationMediaPictureCamera) {
        let metadata = ImageMetadata()
        metadata.source = source
        metadata.method = method
        metadata.sketchSource = sketchSource
        metadata.camera = camera
        self.tagMediaSentPicture(inConversation: conversation, metadata: metadata)
    }
    
    @objc public func tagMediaSentPicture(inConversation conversation: ZMConversation, metadata: ImageMetadata) {
        var attributes = conversation.ephemeralTrackingAttributes
        if let typeAttribute = conversation.analyticsTypeString() {
            attributes["conversation_type"] = typeAttribute
        }
        
        attributes[ConversationMediaPictureSource.attributeName] = metadata.source.attributeValue
        if metadata.method != .none {
            attributes[ConversationMediaPictureTakeMethod.attributeName] = metadata.method.attributeValue
        }
        
        if metadata.source == .sketch {
            attributes[ConversationMediaSketchSource.attributeName] = metadata.sketchSource.attributeValue
        }
        else if metadata.source == .camera {
            attributes[ConversationMediaPictureCamera.attributeName] = metadata.camera.attributeValue
        }
        
        tagEvent(conversationMediaSentPictureEventName, attributes: attributes)
    }
    
    @objc public func tagMediaOpened(_ event: ConversationMediaOpenEvent, inConversation conversation: ZMConversation, sentBySelf: Bool) {
        var attributes = ["user": sentBySelf ? "sender" : "receiver"]
        if let typeAttribute = conversation.analyticsTypeString() {
            attributes["conversation_type"] = typeAttribute
        }
        tagEvent(event.name, attributes: attributes)
    }
    
    fileprivate class func stringFromTimeInterval(_ interval: TimeInterval) -> String {
        return NSString(format: "%.0f", interval) as String
    }
    
    /// User uploads video message
    @objc public func tagSentVideoMessage(inConversation conversation: ZMConversation, context: ConversationMediaVideoContext, duration: TimeInterval) {

        var attributes = conversation.ephemeralTrackingAttributes
        attributes["duration"] = videoDurationClusterizer.clusterizeTimeInterval(duration)
        attributes["duration_actual"] = type(of: self).stringFromTimeInterval(duration)
        
        if let typeAttribute = conversation.analyticsTypeString() {
            attributes["conversation_type"] = typeAttribute
        }
        
        attributes[ConversationMediaVideoContext.attributeName] = context.attributeValue
        
        tagEvent(conversationMediaSentVideoMessageEventName, attributes: attributes)
    }

    /// User plays a video message
    @objc public func tagPlayedVideoMessage(_ duration: TimeInterval) {
        let attributes: [String: String] = ["duration": videoDurationClusterizer.clusterizeTimeInterval(duration),
                                            "duration_actual": type(of: self).stringFromTimeInterval(duration)]
        tagEvent(conversationMediaPlayedVideoMessageEventName, attributes: attributes)
    }
    
    // User starts recording the audio message
    @objc public func tagStartedAudioMessageRecording(inConversation conversation: ZMConversation, type: ConversationMediaRecordingType) {
        var attributes = ["state": type.description]
        if let typeAttribute = conversation.analyticsTypeString() {
            attributes["conversation_type"] = typeAttribute
        }
        tagEvent(conversationMediaStartedRecordingAudioEventName, attributes: attributes)
    }
    
    // User cancels the recorded audio message
    @objc public func tagCancelledAudioMessageRecording() {
        tagEvent(conversationMediaCancelledRecordingAudioMessageEventName)
    }
    
    // User previews the recorded audio message
    @objc public func tagPreviewedAudioMessageRecording(_ type: ConversationMediaRecordingType) {
        let attributes = ["state": type.description]
        tagEvent(conversationMediaPreviewedAudioMessageEventName, attributes: attributes)
    }
    
    /// User uploads an audio message
    public func tagSentAudioMessage(in conversation: ZMConversation, duration: TimeInterval, context: AudioMessageContext, filter: AVSAudioEffectType, type: ConversationMediaRecordingType) {
        let filterName = filter.description.lowercased()
        var  attributes: [String: String] = [
            "duration": videoDurationClusterizer.clusterizeTimeInterval(duration),
            "duration_actual": type(of: self).stringFromTimeInterval(duration),
            AudioMessageContext.keyName: context.attributeString,
            "filter": filterName,
            "state": type.description
        ]

        conversation.ephemeralTrackingAttributes.forEach { key, value in
            attributes[key] = value
        }

        tagEvent(conversationMediaSentAudioMessageEventName, attributes: attributes)
    }
    
    /// User plays an audio message
    @objc public func tagPlayedAudioMessage(_ duration: TimeInterval, extensionString: String) {
        let attributes: [String: String] = [
            "duration": videoDurationClusterizer.clusterizeTimeInterval(duration),
            "duration_actual": type(of: self).stringFromTimeInterval(duration),
            "type": extensionString
        ]
        tagEvent(conversationMediaPlayedAudioMessageEventName, attributes: attributes)
    }
    
}
