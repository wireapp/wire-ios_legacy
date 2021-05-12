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
import WireLinkPreview
import XCTest

final class MockCompositeMessageData: NSObject, CompositeMessageData {
    var items: [CompositeMessageItem] = []
}

final class MockTextMessageData: NSObject, ZMTextMessageData {

    var messageText: String? = ""
    var backingLinkPreview: LinkMetadata?
    var imageData: Data?
    var linkPreviewHasImage: Bool = false
    var linkPreviewImageCacheKey: String?
    var mentions = [Mention]()

    var quote: ZMMessage? {
        get {
            XCTFail("This property should not be used in tests")
            return nil
        }

        set {
            XCTFail("This property should not be used in tests")
        }
    }
    var quoteMessage: ZMConversationMessage?
    var isQuotingSelf: Bool = false
    var hasQuote: Bool = false

    var linkPreview: LinkMetadata? {
        guard let linkPreview = self.backingLinkPreview, !linkPreview.isBlacklisted else { return nil }
        return linkPreview
    }

    func fetchLinkPreviewImageData(with queue: DispatchQueue, completionHandler: @escaping ((Data?) -> Void)) {
        completionHandler(imageData)
    }

    func requestLinkPreviewImageDownload() {
        // no-op
    }

    func editText(_ text: String, mentions: [Mention], fetchLinkPreview: Bool) {
        // stub
    }
}

final class MockSystemMessageData: NSObject, ZMSystemMessageData {
    var messageTimer: NSNumber?
    var systemMessageType: ZMSystemMessageType = .invalid
    var users: Set<ZMUser> {
        get {
            XCTFail("This property should not be used in tests")
            return Set()
        }

        set {
            XCTFail("This property should not be used in tests")
        }
    }
    var userTypes: Set<AnyHashable> = Set()
    var clients: Set<AnyHashable> = Set()
    var addedUsers: Set<ZMUser> {
        get {
            XCTFail("This property should not be used in tests")
            return Set()
        }

        set {
            XCTFail("This property should not be used in tests")
        }
    }
    var addedUserTypes: Set<AnyHashable> = Set()
    var removedUsers: Set<ZMUser> {
        get {
            XCTFail("This property should not be used in tests")
            return Set()
        }

        set {
            XCTFail("This property should not be used in tests")
        }
    }
    var removedUserTypes: Set<AnyHashable> = Set()
    var text: String? = ""
    var needsUpdatingUsers: Bool = false
    var userIsTheSender: Bool = false
    var decryptionErrorCode: NSNumber?
    var isDecryptionErrorRecoverable: Bool = true
    var senderClientID: String? = "452367891023123"

    var duration: TimeInterval = 0
    var childMessages = Set<AnyHashable>()
    var parentMessage: ZMSystemMessageData?

    init(systemMessageType: ZMSystemMessageType) {
        self.systemMessageType = systemMessageType
    }
}

protocol MockFileMessageDataType: ZMFileMessageData {
    var size: UInt64 { get set }
    var mimeType: String? { get set }
    var filename: String? { get set }
    var fileURL: URL? { get set }
    var previewData: Data? { get set }
    var durationMilliseconds: UInt64 { get set }
    var normalizedLoudness: [Float]? { get set }
    var transferState: AssetTransferState { get set }
    var downloadState: AssetDownloadState { get set }
}

extension MockPassFileMessageData: MockFileMessageDataType { }
extension MockFileMessageData: MockFileMessageDataType { }

final class MockPassFileMessageData: NSObject, ZMFileMessageData {

    var mimeType: String? = "application/vnd.apple.pkpass"
    var size: UInt64 = 1024 * 1024 * 2
    var transferState: AssetTransferState = .uploaded
    var downloadState: AssetDownloadState = .remote
    var filename: String? = "ticket.pkpass"
    var progress: Float = 0
    var fileURL: URL? {
        get {
            let path = Bundle(for: type(of: self)).path(forResource: "sample", ofType: "pkpass")!
            return URL(fileURLWithPath: path)
        }

        set {

        }
    }
    var thumbnailAssetID: String? = ""
    var imagePreviewDataIdentifier: String? = "preview-identifier-123"
    var durationMilliseconds: UInt64 = 0
    var videoDimensions: CGSize = CGSize.zero
    var normalizedLoudness: [Float]? = []
    var previewData: Data?

    var isPass: Bool {
        return mimeType == "application/vnd.apple.pkpass"
    }

    var isVideo: Bool {
        return mimeType == "video/mp4"
    }

    var isAudio: Bool {
        return mimeType == "audio/x-m4a"
    }

    var isPDF: Bool {
        return mimeType == "application/pdf"
    }

    var v3_isImage: Bool {
        return false
    }

    func requestFileDownload() {
        // no-op
    }

    func cancelTransfer() {
        // no-op
    }

    func fetchImagePreviewData(queue: DispatchQueue, completionHandler: @escaping (Data?) -> Void) {
        completionHandler(previewData)
    }

    func requestImagePreviewDownload() {
        // no-op
    }

    func signPDFDocument(observer: SignatureObserver) -> Any? {
        return nil
    }

    func retrievePDFSignature() {
        // no-op
    }
}

final class MockFileMessageData: NSObject, ZMFileMessageData {
    var mimeType: String? = "application/pdf"
    var size: UInt64 = 1024 * 1024 * 2
    var transferState: AssetTransferState = .uploaded
    var downloadState: AssetDownloadState = .remote
    var filename: String? = "TestFile.pdf"
    var progress: Float = 0
    var fileURL: URL? = .none
    var thumbnailAssetID: String? = ""
    var imagePreviewDataIdentifier: String? = "preview-identifier-123"
    var durationMilliseconds: UInt64 = 233000
    var videoDimensions: CGSize = CGSize.zero
    var normalizedLoudness: [Float]? = []
    var previewData: Data?

    var isPass: Bool {
        return mimeType == "application/vnd.apple.pkpass"
    }

    var isVideo: Bool {
        return mimeType == "video/mp4"
    }

    var isAudio: Bool {
        return mimeType == "audio/x-m4a"
    }

    var isPDF: Bool {
        return mimeType == "application/pdf"
    }

    var v3_isImage: Bool {
        return false
    }

    func requestFileDownload() {
        // no-op
    }

    func cancelTransfer() {
        // no-op
    }

    func fetchImagePreviewData(queue: DispatchQueue, completionHandler: @escaping (Data?) -> Void) {
        completionHandler(previewData)
    }

    func requestImagePreviewDownload() {
        // no-op
    }

    func signPDFDocument(observer: SignatureObserver) -> Any? {
        return nil
    }

    func retrievePDFSignature() {
        // no-op
    }
}

final class MockKnockMessageData: NSObject, ZMKnockMessageData {

}

final class MockImageMessageData: NSObject, ZMImageMessageData {

    var mockOriginalSize: CGSize = .zero
    var mockImageData = Data()
    var mockImageDataIdentifier = String()

    var mediumData: Data! = Data()
    var previewData: Data! = Data()
    var imagePreviewDataIdentifier: String! = String()

    var isDownloaded: Bool = true
    var isAnimatedGIF: Bool = false
    var imageType: String? = String()

    var imageData: Data? { return mockImageData }
    var imageDataIdentifier: String? { return mockImageDataIdentifier }
    var originalSize: CGSize { return mockOriginalSize }

    func fetchImageData(with queue: DispatchQueue, completionHandler: @escaping ((Data?) -> Void)) {
        completionHandler(imageData)
    }

    func requestFileDownload() {
        // no-op
    }
}

final class MockLocationMessageData: NSObject, LocationMessageData {
    var longitude: Float = 0
    var latitude: Float = 0
    var name: String?
    var zoomLevel: Int32 = 0
}

class MockMessage: NSObject, ZMConversationMessage, ConversationCompositeMessage {
    // MARK: - ConversationCompositeMessage
    var compositeMessageData: CompositeMessageData?

    typealias UsersByReaction = [String: [UserType]]

    // MARK: - ZMConversationMessage
    var nonce: UUID? = UUID()
    var isEncrypted: Bool = false
    var isPlainText: Bool = true
    var sender: ZMUser? {
        get {
            XCTFail("This property should not be used in tests")

            return nil
        }

        set {
            XCTFail("This property should not be used in tests")
        }
    }
    var senderUser: UserType? {
        didSet {
            if senderUser is ZMUser {
                XCTFail("ZMUser should not created for tests")
            }
        }
    }
    var serverTimestamp: Date? = .none
    var updatedAt: Date? = .none

    var conversation: ZMConversation? = .none
    var conversationLike: ConversationLike? = .none

    var deliveryState: ZMDeliveryState = .delivered

    var imageMessageData: ZMImageMessageData? = .none
    var knockMessageData: ZMKnockMessageData? = .none

    var causedSecurityLevelDegradation: Bool = false
    var needsReadConfirmation: Bool = false
    let objectIdentifier: String = UUID().uuidString
    var linkAttachments: [LinkAttachment]?
    var needsLinkAttachmentsUpdate: Bool = false
    var isSilenced: Bool = false

    var isSent: Bool {
        switch deliveryState {
        case .failedToSend, .pending, .invalid:
            return false
        default:
            return true
        }
    }

    var fileMessageData: ZMFileMessageData? {
        return backingFileMessageData
    }

    var locationMessageData: LocationMessageData? {
        return backingLocationMessageData
    }

    var textMessageData: ZMTextMessageData? {
        return backingTextMessageData
    }

    var systemMessageData: ZMSystemMessageData? {
        return backingSystemMessageData
    }

    var replies: Set<ZMMessage> = Set()

    var usersReaction: [String: [UserType]] {
        return backingUsersReaction
    }

    var backingUsersReaction: UsersByReaction = [:]
    var backingTextMessageData: MockTextMessageData! = .none
    var backingFileMessageData: MockFileMessageDataType! = .none
    var backingLocationMessageData: MockLocationMessageData! = .none
    var backingSystemMessageData: MockSystemMessageData! = .none

    var isEphemeral: Bool = false
    var isObfuscated: Bool = false

    var deletionTimeout: TimeInterval = -1
    public var destructionDate: Date?

    func startSelfDestructionIfNeeded() -> Bool {
        return true
    }

    func resend() {
        // no-op
    }

    var canBeDeleted: Bool {
        return systemMessageData == nil
    }

    func markAsUnread() {
        // no-op
    }

    var readReceipts: [ReadReceipt] = []

    var canBeMarkedUnread = true

    var hasBeenDeleted = false

    var systemMessageType: ZMSystemMessageType = ZMSystemMessageType.invalid

    required override init() {

    }
}
