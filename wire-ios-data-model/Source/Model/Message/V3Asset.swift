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

private let zmLog = ZMSLog(tag: "AssetV3")

/// This protocol is used to hide the implementation of the different
/// asset types (v2 image & file vs. v3 file) from ZMAssetClientMessage.
/// It only includes methods in which these two versions differentiate.
@objc public protocol AssetProxyType {

    var hasDownloadedFile: Bool { get }
    var hasDownloadedPreview: Bool { get }

    var imageMessageData: ZMImageMessageData? { get }
    var fileURL: URL? { get }

    var previewData: Data? { get }
    var imagePreviewDataIdentifier: String? { get }

    @objc(imageDataForFormat:encrypted:)
    func imageData(for: ZMImageFormat, encrypted: Bool) -> Data?

    func requestFileDownload()
    func requestPreviewDownload()

    @objc(fetchImageDataWithQueue:completionHandler:)
    func fetchImageData(with queue: DispatchQueue!, completionHandler: ((Data?) -> Void)!)

}

@objcMembers public class V3Asset: NSObject, ZMImageMessageData {
    @objc(fetchImageDataWithQueue:completionHandler:)
    public func fetchImageData(with queue: DispatchQueue, completionHandler: @escaping ((Data?) -> Void)) {
        let cache = moc.zm_fileAssetCache
        let mediumKey = FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .medium)
        let originalKey = FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .original)

        queue.async {
            completionHandler([mediumKey, originalKey].lazy.compactMap({ $0 }).compactMap({ cache?.assetData($0) }).first)
        }
    }

    public var isDownloaded: Bool {
        return hasDownloadedFile
    }

    fileprivate let assetClientMessage: ZMAssetClientMessage
    fileprivate let moc: NSManagedObjectContext

    fileprivate var isImage: Bool {
        return assetClientMessage.underlyingMessage?.v3_isImage ?? false
    }

    public init?(with message: ZMAssetClientMessage) {
        guard message.version == 3 else { return nil }
        assetClientMessage = message
        moc = message.managedObjectContext!
    }

    public var imageMessageData: ZMImageMessageData? {
        guard isImage else { return nil }
        return self
    }

    public var mediumData: Data? {
        guard nil != assetClientMessage.fileMessageData, isImage else { return nil }
        return imageData(for: .medium, encrypted: false)
    }

    public var imageData: Data? {
        guard nil != assetClientMessage.fileMessageData, isImage else { return nil }
        return mediumData ?? imageData(for: .original, encrypted: false)
    }

    public var imageDataIdentifier: String? {
        return FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .medium)
    }

    public var imagePreviewDataIdentifier: String? {
        return FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .preview)
    }

    public var previewData: Data? {
        guard nil != assetClientMessage.fileMessageData, !isImage, hasDownloadedPreview else { return nil }
        return imageData(for: .medium, encrypted: false) ?? imageData(for: .original, encrypted: false)
    }

    public var isAnimatedGIF: Bool {
        guard let mimeType = assetClientMessage.underlyingMessage?.assetData?.original.mimeType else {
            return false
        }
        return UTIHelper.conformsToGifType(mime: mimeType)
    }

    public var imageType: String? {
        guard isImage else { return nil }
        return assetClientMessage.underlyingMessage?.assetData?.original.mimeType
    }

    public var originalSize: CGSize {
        guard nil != assetClientMessage.fileMessageData, isImage else { return .zero }
        guard let asset = assetClientMessage.underlyingMessage?.assetData else { return .zero }
        let size = CGSize(width: Int(asset.original.image.width), height: Int(asset.original.image.height))

        if size != .zero {
            return size
        }

        return assetClientMessage.preprocessedSize
    }

}

extension V3Asset: AssetProxyType {

    public var hasDownloadedPreview: Bool {
        guard !isImage else { return false }

        return moc.zm_fileAssetCache.hasDataOnDisk(assetClientMessage, format: .medium, encrypted: false) ||
               moc.zm_fileAssetCache.hasDataOnDisk(assetClientMessage, format: .original, encrypted: false)
    }

    public var hasDownloadedFile: Bool {
        if isImage {
            return moc.zm_fileAssetCache.hasDataOnDisk(assetClientMessage, format: .medium, encrypted: false) ||
                   moc.zm_fileAssetCache.hasDataOnDisk(assetClientMessage, format: .original, encrypted: false)
        } else {
            return moc.zm_fileAssetCache.hasDataOnDisk(assetClientMessage, encrypted: false)
        }

    }

    public var fileURL: URL? {
        return moc.zm_fileAssetCache.accessAssetURL(assetClientMessage)
    }

    public func imageData(for format: ZMImageFormat, encrypted: Bool) -> Data? {
        guard assetClientMessage.fileMessageData != nil else { return nil }
        return moc.zm_fileAssetCache.assetData(assetClientMessage, format: format, encrypted: encrypted)
    }

    public func requestFileDownload() {
        guard !assetClientMessage.objectID.isTemporaryID else { return }
        NotificationInContext(name: ZMAssetClientMessage.assetDownloadNotificationName,
                              context: self.moc.notificationContext,
                              object: assetClientMessage.objectID).post()
    }

    public func requestPreviewDownload() {
        if assetClientMessage.underlyingMessage?.assetData?.hasPreview == true {
            guard !assetClientMessage.objectID.isTemporaryID else { return }
            NotificationInContext(name: ZMAssetClientMessage.imageDownloadNotificationName,
                                  context: self.moc.notificationContext,
                                  object: assetClientMessage.objectID
                                ).post()
        } else {
            return zmLog.info("Called \(#function) on a v3 asset that doesn't represent an image or has a preview")
        }
    }

}
