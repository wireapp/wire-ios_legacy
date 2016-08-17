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
    var imageData: NSData? = nil
    var hasImageData: Bool = false
    var imageDataIdentifier: String? = nil
}

@objc class MockSystemMessageData: NSObject, ZMSystemMessageData {
    var systemMessageType: ZMSystemMessageType = .Invalid
    var users: Set<ZMUser>! = Set()
    var clients: Set<NSObject>! = Set()
    var addedUsers: Set<ZMUser>! = Set()
    var removedUsers: Set<ZMUser>! = Set()
    var text: String! = ""
    var needsUpdatingUsers: Bool = false
    
    init(systemMessageType: ZMSystemMessageType) {
        self.systemMessageType = systemMessageType
    }
}


@objc class MockFileMessageData: NSObject, ZMFileMessageData {
    var mimeType: String! = "application/pdf"
    var size: UInt64 = 1024 * 1024 * 2
    var transferState: ZMFileTransferState = .Uploaded
    var filename: String! = "TestFile.pdf"
    var progress: Float = 0
    var fileURL: NSURL? = .None
    var previewData: NSData? = nil
    var thumbnailAssetID : String? = ""
    var imagePreviewDataIdentifier: String! = "preview-identifier-123"
    var durationMilliseconds: UInt = 233000
    var videoDimensions: CGSize = CGSizeZero
    var normalizedLoudness: [NSNumber]! = []
    
    func isVideo() -> Bool {
        return mimeType == "video/mp4"
    }
    
    func isAudio() -> Bool {
        return mimeType == "audio/x-m4a"
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
    var mockImageData = NSData()
    var mockImageDataIdentifier = String()
    
    var mediumData: NSData! = NSData()
    var previewData: NSData! = NSData()
    var imagePreviewDataIdentifier: String! = String()
    
    var isAnimatedGIF: Bool = false
    var imageType: String! = String()
    
    var imageData: NSData { return mockImageData }
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
    
    // MARK: - ZMConversationMessage
    var isEncrypted: Bool = false
    var isPlainText: Bool = true
    var sender: ZMUser? = .None
    var serverTimestamp: NSDate? = .None
    var updatedAt: NSDate? = .None
    var conversation: ZMConversation? = .None
    var deliveryState: ZMDeliveryState = .Delivered
    var imageMessageData: ZMImageMessageData? = .None
    var systemMessageData: ZMSystemMessageData? = .None
    var knockMessageData: ZMKnockMessageData? = .None
    var fileMessageData: ZMFileMessageData? {
        get {
            return backingFileMessageData
        }
    }
    
    var locationMessageData: ZMLocationMessageData? {
        get {
            return backingLocationMessageData
        }
    }
    
    var textMessageData: ZMTextMessageData? {
        get {
            return backingTextMessageData
        }
    }
    
    var backingTextMessageData: MockTextMessageData! = .None
    var backingFileMessageData: MockFileMessageData! = .None
    var backingLocationMessageData: MockLocationMessageData! = .None
    
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
        guard (self.systemMessageData) != nil else { return true }
        return false
    }
    
    var hasBeenDeleted = false
}
