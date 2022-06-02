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
import MobileCoreServices

// MARK: - ZMFileMessageData
@objc public protocol ZMFileMessageData: NSObjectProtocol {

    /// MIME type of the file being transfered (implied from file extension)
    var mimeType: String? { get }

    /// Original file size
    var size: UInt64 { get }

    /// File transfer state
    var transferState: AssetTransferState { get }

    /// Download state (.downloaded, downloading, ...)
    var downloadState: AssetDownloadState { get }

    /// File name as was sent
    var filename: String? { get }

    /// Currend download / upload progress
    var progress: Float { get set }

    /// The file location on the filesystem
    var fileURL: URL? { get }

    /// The asset ID of the thumbnail, if any
    var thumbnailAssetID: String? { get set }

    /// Duration of the media in milliseconds
    var durationMilliseconds: UInt64 { get }

    /// Dimensions of the video
    var videoDimensions: CGSize { get }

    /// File thumbnail preview image
    var previewData: Data? { get }

    /// This can be used as a cache key for @c -previewData
    var imagePreviewDataIdentifier: String? { get }

    /// Normalized loudness of audio data
    var normalizedLoudness: [Float]? { get }

    /// Marks file to be downloaded
    func requestFileDownload()

    /// Marks file image preview to be downloaded
    func requestImagePreviewDownload()

    /// Video-message related properties
    /// if MIME type is indicating the video content
    var isVideo: Bool { get }

    /// if MIME type is indicating the PKPass content
    var isPass: Bool { get }

    /// Cancels the pending download or upload of the file.
    /// Deisgned to be used in case the file transfer on sender side is
    /// in `ZMFileMessageStateUploading` state, or in `ZMFileMessageStateDownloading`
    /// state on receiver side.
    func cancelTransfer()

    /// Audio-message related properties
    /// if MIME type is indicating the audio content
    var isAudio: Bool { get }

    /// if MIME type is indicating the pdf content
    var isPDF: Bool { get }

    /// Whether the file message represents a v3 image
    var v3_isImage: Bool { get }

    /// Fetch preview image data from disk
    func fetchImagePreviewData(queue: DispatchQueue, completionHandler: @escaping (_ imageData: Data?) -> Void)

    /// Signing a PDF document
    func signPDFDocument(observer: SignatureObserver) -> Any?

    /// retrieve a PDF signature
    func retrievePDFSignature()
}

extension ZMAssetClientMessage: ZMFileMessageData {

    /// Notification name for canceled file upload
    public static let didCancelFileDownloadNotificationName = Notification.Name(rawValue: "ZMAssetClientMessageDidCancelFileDownloadNotification")

    // MIME type of the file being transfered (implied from file extension)
    public var mimeType: String? {

        guard let asset = underlyingMessage?.assetData else {
            return nil
        }

        if asset.original.hasMimeType {
            return asset.original.mimeType
        }

        if asset.preview.hasMimeType {
            return asset.preview.mimeType
        }

        if let assetData = previewGenericMessage?.imageAssetData, assetData.hasMimeType {
            return assetData.mimeType
        }

        if let assetData = mediumGenericMessage?.imageAssetData, assetData.hasMimeType {
            return assetData.mimeType
        }

        return nil
    }

    /// If the asset is a rich file type, this returns its type.
    public var richAssetType: RichAssetFileType? {
        return mimeType.flatMap(RichAssetFileType.init)
    }

    public var fileURL: URL? {
        guard
            let assetURL = asset?.fileURL,
            let temporaryDirectoryURL = temporaryDirectoryURL,
            let filename = filename,
            !(filename as NSString).lastPathComponent.isEmpty
        else {
            return nil
        }

        let secureFilename = (filename as NSString).lastPathComponent
        var temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(secureFilename)

        if let mime = mimeType,
           let fileExtension = UTIHelper.convertToFileExtension(mime: mime),
            richAssetType == .audio,
            temporaryFileURL.pathExtension != fileExtension {
            temporaryFileURL.appendPathExtension(fileExtension)
        }

        if FileManager.default.fileExists(atPath: temporaryFileURL.path) {
            return temporaryFileURL
        }

        do {
            try FileManager.default.createDirectory(at: temporaryFileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.linkItem(at: assetURL, to: temporaryFileURL)
        } catch {
            return nil
        }

        return temporaryFileURL
    }

    public var temporaryDirectoryURL: URL? {
        guard let cacheKey = FileAssetCache.cacheKeyForAsset(self) else { return nil }
        var temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        temporaryURL.appendPathComponent(cacheKey)
        return temporaryURL
    }

    public var previewData: Data? {
        return asset?.previewData
    }

    public func fetchImagePreviewData(queue: DispatchQueue, completionHandler: @escaping (Data?) -> Void) {
        guard nil != fileMessageData, !isImage else { return completionHandler(nil) }

        asset?.fetchImageData(with: queue, completionHandler: completionHandler)
    }

    /// File name as was sent or `nil` in case of an image asset
    public var filename: String? {
        return underlyingMessage?.assetData?.original.name.normalizedFilename
    }

    public var thumbnailAssetID: String? {

        get {
            guard fileMessageData != nil else { return nil }
            guard let assetData = genericMessage(dataType: .thumbnail)?.assetData,
                assetData.preview.remote.hasAssetID,
                !assetData.preview.remote.assetID.isEmpty
                else { return nil }
            return assetData.preview.remote.assetID
        }

        set {
            // This method has to inject this value in the currently existing thumbnail message.
            // Unfortunately it is immutable. So I need to create a copy, modify and then replace.
            guard
                let thumbnailMessage = genericMessage(dataType: .thumbnail),
                var assetData = thumbnailMessage.assetData,
                assetData.hasPreview,
                assetData.preview.hasRemote
            else {
                return
            }

            assetData.preview.remote.assetID = newValue ?? ""

            do {
                var message = GenericMessage()
                try message.merge(serializedData: thumbnailMessage.serializedData())
                message.update(asset: assetData)
                try replaceGenericMessageForThumbnail(with: message)
            } catch {
                Logging.messageProcessing.warn("Failed to set thumbnail asset id. Reason: \(error.localizedDescription)")
            }
        }
    }

    private func replaceGenericMessageForThumbnail(with genericMessage: GenericMessage) throws {
        cachedUnderlyingAssetMessage = nil

        for data in dataSet {
            guard
                let messageData = data as? ZMGenericMessageData,
                let assetData = messageData.underlyingMessage?.assetData,
                assetData.hasPreview
            else {
                continue
            }

            do {
                try messageData.setGenericMessage(genericMessage)
            } catch {
                throw ProcessingError.failedToProcessMessageData(reason: error.localizedDescription)
            }
        }
    }

    public var imagePreviewDataIdentifier: String? {
        return asset?.imagePreviewDataIdentifier
    }

    public var isPass: Bool {
        return richAssetType == .walletPass
    }

    public var isVideo: Bool {
        return richAssetType == .video
    }

    public var isAudio: Bool {
        return richAssetType == .audio
    }

    public var isPDF: Bool {
        return mimeType == "application/pdf"
    }

    public var v3_isImage: Bool {
        return underlyingMessage?.v3_isImage ?? false
    }

    public var videoDimensions: CGSize {
        guard let assetData = underlyingMessage?.assetData else { return CGSize.zero }
        let w = assetData.original.video.width
        let h = assetData.original.video.height
        return CGSize(width: Int(w), height: Int(h))
    }

    public var durationMilliseconds: UInt64 {
        guard let assetData = underlyingMessage?.assetData else { return 0 }
        if isVideo {
            return assetData.original.video.durationInMillis
        }
        if isAudio {
            return assetData.original.audio.durationInMillis
        }
        return 0
    }

    public var normalizedLoudness: [Float]? {
        guard isAudio,
            let assetData = underlyingMessage?.assetData,
            assetData.original.audio.hasNormalizedLoudness else {
            return nil
        }
        return assetData.original.normalizedLoudnessLevels
    }

    public func requestFileDownload() {
        asset?.requestFileDownload()
    }

    public func requestImagePreviewDownload() {
        asset?.requestPreviewDownload()
    }

    public func signPDFDocument(observer: SignatureObserver) -> Any? {
        guard
            let managedObjectContext = managedObjectContext,
            let syncContext = managedObjectContext.zm_sync,
            let fileURL = fileURL,
            let PDFData = try? Data(contentsOf: fileURL)
        else {
            return nil
        }

        let token = SignatureStatus.addObserver(observer,
                                                context: managedObjectContext)

        let asset = underlyingMessage?.assetData
        syncContext.performGroupedBlock {
            let status = SignatureStatus(asset: asset,
                                         data: PDFData,
                                         managedObjectContext: syncContext)
            status.store()
            status.signDocument()
        }

        return token
    }

    public func retrievePDFSignature() {
        guard
            let managedObjectContext = managedObjectContext,
            let syncContext = managedObjectContext.zm_sync
        else {
            return
        }

        syncContext.performGroupedBlock {
            syncContext.signatureStatus?.retrieveSignature()
        }
    }
}

extension ZMAssetClientMessage {

    public func cancelTransfer() {

        switch transferState {
        case .uploading:
            expire()
            updateTransferState(.uploadingCancelled, synchronize: false)
            progress = 0
        case .uploaded:
            self.progress = 0
            self.obtainPermanentObjectID()
            self.managedObjectContext?.saveOrRollback()
            NotificationInContext(
                name: ZMAssetClientMessage.didCancelFileDownloadNotificationName,
                context: self.managedObjectContext!.notificationContext,
                object: self.objectID,
                userInfo: [:]
                ).post()
        default:
            break
        }
    }

    /// Turn temporary object ID into permanet
    private func obtainPermanentObjectID() {
        if self.objectID.isTemporaryID {
            try! self.managedObjectContext!.obtainPermanentIDs(for: [self])
        }
    }

}
