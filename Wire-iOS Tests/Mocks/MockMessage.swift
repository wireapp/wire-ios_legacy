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
import ZMCLinkPreview

@objc class MockTextMessageData : NSObject, ZMTextMessageData {
    var messageText: String = ""
    var linkPreview: LinkPreview? = nil
    var imageData: Data? = nil
    var hasImageData: Bool = false
    var imageDataIdentifier: String? = nil
}

@objc class MockSystemMessageData: NSObject, ZMSystemMessageData {
    var systemMessageType: ZMSystemMessageType = .invalid
    var users: Set<ZMUser>! = Set()
    var clients: Set<AnyHashable>! = Set()
    var addedUsers: Set<ZMUser>! = Set()
    var removedUsers: Set<ZMUser>! = Set()
    var text: String! = ""
    var needsUpdatingUsers: Bool = false

    var duration: TimeInterval = 0
    var childMessages = Set<AnyHashable>()
    var parentMessage: ZMSystemMessageData! = nil
    
    init(systemMessageType: ZMSystemMessageType) {
        self.systemMessageType = systemMessageType
    }
}


@objc class MockFileMessageData: NSObject, ZMFileMessageData {
    var mimeType: String! = "application/pdf"
    var size: UInt64 = 1024 * 1024 * 2
    var transferState: ZMFileTransferState = .uploaded
    var filename: String! = "TestFile.pdf"
    var progress: Float = 0
    var fileURL: URL? = .none
    var previewData: Data? = nil
    var thumbnailAssetID : String? = ""
    var imagePreviewDataIdentifier: String! = "preview-identifier-123"
    var durationMilliseconds: UInt = 233000
    var videoDimensions: CGSize = CGSize.zero
    var normalizedLoudness: [NSNumber]! = []
    
    func isVideo() -> Bool {
        return mimeType == "video/mp4"
    }
    
    func isAudio() -> Bool {
        return mimeType == "audio/x-m4a"
    }

    func v3_isImage() -> Bool {
        return false
    }
    
    func requestFileDownload() {
        // no-op
    }
    
    func cancelTransfer() {
        // no-op
    }
}

@objc class MockKnockMessageData: NSObject, ZMKnockMessageData {
    
}

@objc class MockImageMessageData : NSObject, ZMImageMessageData {
    var mockOriginalSize: CGSize = .zero
    var mockImageData = Data()
    var mockImageDataIdentifier = String()
    
    var mediumData: Data! = Data()
    var previewData: Data! = Data()
    var imagePreviewDataIdentifier: String! = String()
    
    var isAnimatedGIF: Bool = false
    var imageType: String! = String()
    
    var imageData: Data { return mockImageData }
    var imageDataIdentifier: String { return mockImageDataIdentifier }
    var originalSize: CGSize { return mockOriginalSize }
}

@objc class MockLocationMessageData: NSObject, ZMLocationMessageData {
    var longitude: Float = 0
    var latitude: Float = 0
    var name: String? = nil
    var zoomLevel: Int32 = 0
}


@objc class MockMessage: NSObject, ZMConversationMessage {

    typealias UsersByReaction = Dictionary<String, [ZMUser]>
    
    // MARK: - ZMConversationMessage
    var isEncrypted: Bool = false
    var isPlainText: Bool = true
    var sender: ZMUser? = .none
    var serverTimestamp: Date? = .none
    var updatedAt: Date? = .none
    var conversation: ZMConversation? = .none
    var deliveryState: ZMDeliveryState = .delivered
    var imageMessageData: ZMImageMessageData? = .none
    var systemMessageData: ZMSystemMessageData? = .none
    var knockMessageData: ZMKnockMessageData? = .none
    var causedSecurityLevelDegradation: Bool = false

    var fileMessageData: ZMFileMessageData? {
        return backingFileMessageData
    }
    
    var locationMessageData: ZMLocationMessageData? {
        return backingLocationMessageData
    }
    
    var usersReaction: [String: [ZMUser]] {
        return backingUsersReaction
    }
    
    var textMessageData: ZMTextMessageData? {
        return backingTextMessageData
    }
    
    var backingUsersReaction: UsersByReaction! = [:]
    var backingTextMessageData: MockTextMessageData! = .none
    var backingFileMessageData: MockFileMessageData! = .none
    var backingLocationMessageData: MockLocationMessageData! = .none

    var isEphemeral: Bool = false
    var isObfuscated: Bool = false

    var deletionTimeout: TimeInterval = -1
    public var destructionDate: Date? = nil

    func startSelfDestructionIfNeeded() -> Bool {
        return true
    }
    
    func requestFileDownload() {
        // no-op
    }
    
    func requestImageDownload() {
        // no-op
    }
    
    func resend() {
        // no-op
    }
    
    var canBeDeleted: Bool {
        return systemMessageData == nil
    }

    var hasBeenDeleted = false
    
    var systemMessageType: ZMSystemMessageType = ZMSystemMessageType.invalid
}

extension MockMessage {
    func formattedReceivedDate() -> String? {
        guard let timestamp = self.serverTimestamp else {
            return .none
        }
        let timeString = Message.longVersionTimeFormatter().string(from: timestamp)
        let oneDayInSeconds = 24.0 * 60.0 * 60.0
        let shouldShowDate = fabs(timestamp.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate) > oneDayInSeconds
        
        if shouldShowDate {
            let dateString = Message.shortVersionDateFormatter().string(from: timestamp)
            return dateString + " " + timeString
        }
        else {
            return timeString
        }
    }
}
