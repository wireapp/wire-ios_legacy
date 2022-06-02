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

extension ZMClientMessage {

    public static let linkPreviewImageDownloadNotification = NSNotification.Name(rawValue: "ZMClientMessageLinkPreviewImageDownloadNotificationName")

    public var linkPreviewState: ZMLinkPreviewState {
        get {
            let key = #keyPath(ZMClientMessage.linkPreviewState)
            self.willAccessValue(forKey: key)
            let raw = (self.primitiveValue(forKey: key) as? NSNumber) ?? 0
            self.didAccessValue(forKey: key)
            return ZMLinkPreviewState(rawValue: raw.int16Value)!
        }
        set {
            let key = #keyPath(ZMClientMessage.linkPreviewState)
            self.willChangeValue(forKey: key)
            self.setPrimitiveValue(newValue.rawValue, forKey: key)
            self.didChangeValue(forKey: key)

            if newValue != .done {
                self.setLocallyModifiedKeys(Set([key]))
            }
        }
    }

    public var linkPreview: LinkMetadata? {
        guard let linkPreview = self.firstZMLinkPreview else { return nil }
        if case .tweet? = linkPreview.metaData {
            return TwitterStatusMetadata(protocolBuffer: linkPreview)
        } else {
            let metadata = ArticleMetadata(protocolBuffer: linkPreview)
            guard !metadata.isBlacklisted else { return nil }
            return metadata
        }
    }

    /// Returns the first link attachment that we need to embed in the UI.
    public var mainLinkAttachment: LinkAttachment? {
        return linkAttachments?.first
    }

    var firstZMLinkPreview: LinkPreview? {
        return self.underlyingMessage?.linkPreviews.first
    }

    static func keyPathsForValuesAffectingLinkPreview() -> Set<String> {
        return Set([#keyPath(ZMClientMessage.dataSet), #keyPath(ZMClientMessage.dataSet) + ".data"])
    }

    public func requestLinkPreviewImageDownload() {
        guard !self.objectID.isTemporaryID,
              self.linkPreview != nil,
              let moc = self.managedObjectContext,
              let linkPreview = self.firstZMLinkPreview else { return }

        guard linkPreview.image.uploaded.hasAssetID, !hasDownloadedImage() else { return }

        NotificationInContext(name: ZMClientMessage.linkPreviewImageDownloadNotification, context: moc.notificationContext, object: self.objectID).post()
    }

    public func fetchLinkPreviewImageData(with queue: DispatchQueue, completionHandler: @escaping (_ imageData: Data?) -> Void) {
        guard let cache = managedObjectContext?.zm_fileAssetCache else { return }
        let originalKey =  FileAssetCache.cacheKeyForAsset(self, format: .original)
        let mediumKey =  FileAssetCache.cacheKeyForAsset(self, format: .medium)

        queue.async {
            completionHandler([mediumKey, originalKey].lazy.compactMap({ $0 }).compactMap({ cache.assetData($0) }).first)
        }
    }

    @nonobjc func applyLinkPreviewUpdate(_ updatedMessage: GenericMessage, from updateEvent: ZMUpdateEvent) {
        guard
            let nonce = self.nonce,
            let senderUUID = updateEvent.senderUUID,
            let originalText = underlyingMessage?.textData,
            let updatedText = updatedMessage.textData,
            senderUUID == sender?.remoteIdentifier,
            originalText.content == updatedText.content
        else {
            return
        }

        let timeout = deletionTimeout > 0 ? deletionTimeout : nil
        let message = GenericMessage(content: originalText.updateLinkPreview(from: updatedText), nonce: nonce, expiresAfterTimeInterval: timeout)

        do {
            try setUnderlyingMessage(message)
        } catch {
            assertionFailure("Failed to set generic message: \(error.localizedDescription)")
        }
    }
}

extension ZMClientMessage: ZMImageOwner {

    @objc public func imageData(for format: ZMImageFormat) -> Data? {
        return self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: format, encrypted: false)
    }

    // The image formats that this @c ZMImageOwner wants preprocessed. Order of formats determines order in which data is preprocessed
    @objc public func requiredImageFormats() -> NSOrderedSet {
        if let genericMessage = self.underlyingMessage, genericMessage.linkPreviews.count > 0 {
            return NSOrderedSet(array: [ZMImageFormat.medium.rawValue])
        }
        return NSOrderedSet()
    }

    @objc public func originalImageData() -> Data? {
        return self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: .original, encrypted: false)
    }

    @objc public func originalImageSize() -> CGSize {
        guard let originalImageData = self.originalImageData() else { return CGSize.zero }
        return ZMImagePreprocessor.sizeOfPrerotatedImage(with: originalImageData)
    }

    @objc public func processingDidFinish() {
        self.linkPreviewState = .processed
        guard let moc = self.managedObjectContext else { return }
        moc.zm_fileAssetCache.deleteAssetData(self, format: .original, encrypted: false)
        moc.enqueueDelayedSave()
    }

    @objc public var linkPreviewImageData: Data? {
        return self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: .original, encrypted: false)
            ?? self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: .medium, encrypted: false)
    }

    public var linkPreviewHasImage: Bool {
        guard let linkPreview = self.firstZMLinkPreview else { return false }
        return linkPreview.hasImage
    }

    @objc public var linkPreviewImageCacheKey: String? {
        return self.nonce?.uuidString
    }

    @objc public func setImageData(_ imageData: Data, for format: ZMImageFormat, properties: ZMIImageProperties?) {
        guard let moc = self.managedObjectContext,
            var linkPreview = self.firstZMLinkPreview,
            format == .medium else {
                return
        }

        moc.zm_fileAssetCache.storeAssetData(self, format: format, encrypted: false, data: imageData)
        guard let keys = moc.zm_fileAssetCache.encryptImageAndComputeSHA256Digest(self, format: format) else { return }

        let imageMetaData = WireProtos.Asset.ImageMetaData(width: Int32(properties?.size.width ?? 0), height: Int32(properties?.size.height ?? 0))
        let original = WireProtos.Asset.Original(withSize: UInt64(imageData.count), mimeType: properties?.mimeType ?? "", name: nil, imageMetaData: imageMetaData)

        linkPreview.update(withOtrKey: keys.otrKey, sha256: keys.sha256!, original: original)

        if let genericMessage = self.underlyingMessage, let textMessageData = textMessageData {

            let text = Text.with {
                $0.content = textMessageData.messageText ?? ""
                $0.mentions = textMessageData.mentions.compactMap { WireProtos.Mention.createMention($0) }
                $0.linkPreview = [linkPreview]
            }

            let messageUpdate: MessageCapable
            guard
                let content = genericMessage.content,
                let nonce = nonce else {
                    return
            }
            switch content {
            case .text:
                messageUpdate = text
            case .ephemeral(let data):
                switch data.content {
                case .text?:
                    messageUpdate = Ephemeral(content: text, expiresAfter: deletionTimeout)
                default:
                    return
                }
            case .edited:
                guard let replacingMessageID = UUID(uuidString: genericMessage.edited.replacingMessageID) else {
                    return
                }
                messageUpdate = MessageEdit(replacingMessageID: replacingMessageID, text: text)
            default:
                return
            }

            do {
                let genericMessage = GenericMessage(content: messageUpdate, nonce: nonce)
                try setUnderlyingMessage(genericMessage)
            } catch {
                Logging.messageProcessing.warn("Failed to link preview image data. Reason: \(error.localizedDescription)")
                return
            }
        }

        moc.enqueueDelayedSave()
    }
}
