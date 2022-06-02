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

@objcMembers
public class V2Asset: NSObject, ZMImageMessageData {

    public var isDownloaded: Bool {
        return moc.zm_fileAssetCache.hasDataOnDisk(assetClientMessage, format: .medium, encrypted: false) ||
               moc.zm_fileAssetCache.hasDataOnDisk(assetClientMessage, format: .original, encrypted: false)
    }

    public func fetchImageData(with queue: DispatchQueue, completionHandler: @escaping ((Data?) -> Void)) {
        let cache = moc.zm_fileAssetCache
        let mediumKey = FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .medium)
        let originalKey = FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .original)

        queue.async {
            completionHandler([mediumKey, originalKey].lazy.compactMap({ $0 }).compactMap({ cache?.assetData($0) }).first)
        }
    }

    fileprivate let assetClientMessage: ZMAssetClientMessage
    fileprivate let moc: NSManagedObjectContext

    public init?(with message: ZMAssetClientMessage) {
        guard message.version < 3 else { return nil }
        assetClientMessage = message

        guard let managedObjectContext = message.managedObjectContext else { return nil }
        moc = managedObjectContext
    }

    public var imageMessageData: ZMImageMessageData? {
        guard assetClientMessage.mediumGenericMessage != nil || assetClientMessage.previewGenericMessage != nil else { return nil }

        return self
    }

    // MARK: - ZMImageMessageData

    public var mediumData: Data? {
        if assetClientMessage.mediumGenericMessage?.imageAssetData?.width > 0 {
            return imageData(for: .medium, encrypted: false)
        }
        return nil
    }

    public var imageData: Data? {
        return mediumData ?? imageData(for: .original, encrypted: false)
    }

    public var imageDataIdentifier: String? {
        return FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .medium)
    }

    public var imagePreviewDataIdentifier: String? {
        return FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .preview)
    }

    public var previewData: Data? {
        if assetClientMessage.hasDownloadedPreview {
            // File preview data
            return imageData(for: .original) ?? imageData(for: .medium)
        }

        return nil
    }

    public var isAnimatedGIF: Bool {
        guard let mimeType = assetClientMessage.mediumGenericMessage?.imageAssetData?.mimeType else {
            return false
        }
        return UTIHelper.conformsToGifType(mime: mimeType)
    }

    public var imageType: String? {
        return assetClientMessage.mediumGenericMessage?.imageAssetData?.mimeType
    }

    public var originalSize: CGSize {
        guard let asset = assetClientMessage.mediumGenericMessage?.imageAssetData else { return .zero }
        let size = CGSize(width: Int(asset.originalWidth), height: Int(asset.originalHeight))

        if size != .zero {
            return size
        }

        return assetClientMessage.preprocessedSize

    }

    // MARK: - Helper

    private func imageData(for format: ZMImageFormat) -> Data? {
        return moc.zm_fileAssetCache.assetData(assetClientMessage, format: format, encrypted: false)
    }

    fileprivate func hasImageData(for format: ZMImageFormat) -> Bool {
        return moc.zm_fileAssetCache.hasDataOnDisk(assetClientMessage, format: format, encrypted: false)
    }

}

extension V2Asset: AssetProxyType {

    public var hasDownloadedPreview: Bool {
        guard assetClientMessage.fileMessageData != nil else { return false }
        return hasImageData(for: .medium) || hasImageData(for: .original)
    }

    public var hasDownloadedFile: Bool {
        if assetClientMessage.imageMessageData != nil {
            return hasImageData(for: .medium) || hasImageData(for: .original)
        } else {
            return moc.zm_fileAssetCache.hasDataOnDisk(assetClientMessage, encrypted: false)
        }
    }

    public var fileURL: URL? {
        return moc.zm_fileAssetCache.accessAssetURL(assetClientMessage)
    }

    public func imageData(for format: ZMImageFormat, encrypted: Bool) -> Data? {
        if format != .original {
            let message = format == .medium ? assetClientMessage.mediumGenericMessage : assetClientMessage.previewGenericMessage
            guard message?.imageAssetData?.size > 0 else { return nil }
            if encrypted && message?.imageAssetData?.otrKey.count == 0 {
                return nil
            }
        }

        return moc.zm_fileAssetCache.assetData(assetClientMessage, format: format, encrypted: encrypted)
    }

    public func requestFileDownload() {
        guard assetClientMessage.fileMessageData != nil || assetClientMessage.imageMessageData != nil else { return }
        guard !assetClientMessage.objectID.isTemporaryID, let moc = self.moc.zm_userInterface else { return }

        if assetClientMessage.imageMessageData != nil {
            NotificationInContext(name: ZMAssetClientMessage.imageDownloadNotificationName, context: moc.notificationContext, object: assetClientMessage.objectID).post()
        } else {
            NotificationInContext(name: ZMAssetClientMessage.assetDownloadNotificationName, context: moc.notificationContext, object: assetClientMessage.objectID).post()
        }
    }

    public func requestPreviewDownload() {
        guard !assetClientMessage.objectID.isTemporaryID, let moc = self.moc.zm_userInterface else { return }
        if assetClientMessage.underlyingMessage?.assetData?.hasPreview == true {
            NotificationInContext(name: ZMAssetClientMessage.imageDownloadNotificationName, context: moc.notificationContext, object: assetClientMessage.objectID).post()
        }
    }

}
