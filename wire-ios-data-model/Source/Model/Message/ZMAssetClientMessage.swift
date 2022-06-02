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

/// An asset message (image, file, ...)
@objcMembers public class ZMAssetClientMessage: ZMOTRMessage {

    /// In memory cache
    var cachedUnderlyingAssetMessage: GenericMessage?

    internal convenience init(asset: WireProtos.Asset,
                              nonce: UUID,
                              managedObjectContext: NSManagedObjectContext,
                              expiresAfter timeout: TimeInterval?) throws {

        self.init(nonce: nonce, managedObjectContext: managedObjectContext)

        transferState = .uploading
        version = 3

        let genericMessage = GenericMessage(content: asset, nonce: nonce, expiresAfterTimeInterval: timeout)
        try mergeWithExistingData(message: genericMessage)
    }

    public override var hashOfContent: Data? {
        guard let serverTimestamp = serverTimestamp else {
            return nil
        }

        return underlyingMessage?.hashOfContent(with: serverTimestamp)
    }

    /// Remote asset ID
    public var assetId: UUID? {
        get { return transientUUID(forKey: #keyPath(ZMAssetClientMessage.assetId)) }
        set { setTransientUUID(newValue, forKey: #keyPath(ZMAssetClientMessage.assetId)) }
    }

    public static func keyPathsForValuesAffectingAssetID() -> Set<String> {
        return Set(arrayLiteral: #keyPath(ZMAssetClientMessage.assetID_data))
    }

    /// Preprocessed size of image
    public var preprocessedSize: CGSize {
        get { return transientCGSize(forKey: #keyPath(ZMAssetClientMessage.preprocessedSize)) }
        set { setTransientCGSize(newValue, forKey: #keyPath(ZMAssetClientMessage.preprocessedSize)) }
    }

    public static func keyPathsForValuesPreprocessedSize() -> Set<String> {
        return Set(arrayLiteral: #keyPath(ZMAssetClientMessage.assetID_data))
    }

    /// Original file size
    public var size: UInt64 {
        guard let asset = underlyingMessage?.assetData else { return 0 }
        let originalSize = asset.original.size
        let previewSize = asset.preview.size

        if originalSize == 0 {
            return previewSize
        }
        return originalSize
    }

    /// Current download / upload progress
    @NSManaged public var progress: Float

    /// True if we are current in the process of downloading the asset
    @NSManaged public var isDownloading: Bool

    /// State of the file transfer from the uploader's perspective
    @NSManaged public internal(set) var transferState: AssetTransferState

    public func updateTransferState(_ transferState: AssetTransferState, synchronize: Bool) {
        self.transferState = transferState

        if synchronize {
            setLocallyModifiedKeys([#keyPath(ZMAssetClientMessage.transferState)])
        }
    }

    /// Download state
    public var downloadState: AssetDownloadState {
        if hasDownloadedFile {
            return .downloaded
        } else if isDownloading {
            return .downloading
        } else {
            return .remote
        }
    }

    /// Whether the image preview has been downloaded
    public var hasDownloadedPreview: Bool {
        return asset?.hasDownloadedPreview ?? false
    }

    /// Whether the file has been downloaded
    public var hasDownloadedFile: Bool {
        return asset?.hasDownloadedFile ?? false
    }

    // Wheather the referenced asset is encrypted
    public var hasEncryptedAsset: Bool {
        var hasEncryptionKeys = false

        if fileMessageData != nil {
            if let remote = underlyingMessage?.assetData?.preview.remote, remote.hasOtrKey {
                hasEncryptionKeys = true
            }
        } else if imageMessageData != nil {
            if let imageAsset = mediumGenericMessage?.imageAssetData, imageAsset.hasOtrKey {
                hasEncryptionKeys = true
            }
        }

        return hasEncryptionKeys
    }

    /// The asset endpoint version used to generate this message
    /// values lower than 3 represent an enpoint version of 2
    @NSManaged public var version: Int16

    /// Used to associate and persist the task identifier of the `NSURLSessionTask`
    /// with the upload or download of the file data. Can be used to verify that the
    /// data of a `FileMessage` is being down- or uploaded after a termination event
    public var associatedTaskIdentifier: ZMTaskIdentifier? {
        get {
            let key = #keyPath(ZMAssetClientMessage.associatedTaskIdentifier_data)
            self.willAccessValue(forKey: key)
            let data = self.primitiveValue(forKey: key) as? Data
            self.didAccessValue(forKey: key)
            let value = data.flatMap { ZMTaskIdentifier(from: $0) }
            return value
        }
        set {
            let key = #keyPath(ZMAssetClientMessage.associatedTaskIdentifier_data)
            self.willChangeValue(forKey: key)
            self.setPrimitiveValue(newValue?.data, forKey: key)
            self.didChangeValue(forKey: key)
        }
    }

    static func keyPathsForValuesAffectingAssociatedTaskIdentifier() -> Set<String> {
        return Set(arrayLiteral: #keyPath(ZMAssetClientMessage.associatedTaskIdentifier_data))
    }

    var v2Asset: V2Asset? {
        return V2Asset(with: self)
    }

    var v3Asset: V3Asset? {
        return V3Asset(with: self)
    }

    var asset: AssetProxyType? {
        return self.v2Asset ?? self.v3Asset
    }

    public override func expire() {
        super.expire()

        if transferState != .uploaded {
            transferState = .uploadingFailed
        }
    }

    public override func markAsSent() {
        super.markAsSent()
        setObfuscationTimerIfNeeded()
    }

    public override var isUpdatingExistingMessage: Bool {
        guard let genericMessage = underlyingMessage,
            let content = genericMessage.content else {
                return false
        }
        switch content {
        case .edited, .reaction:
            return true
        default:
            return false
        }
    }

    func setObfuscationTimerIfNeeded() {
        guard self.isEphemeral else {
            return
        }

        startDestructionIfNeeded()
    }

    public override func resend() {
        if transferState != .uploaded {
            transferState = .uploading
        }

        self.progress = 0
        setLocallyModifiedKeys(Set(arrayLiteral: #keyPath(ZMAssetClientMessage.transferState)))

        super.resend()
    }

    public override func update(withPostPayload payload: [AnyHashable: Any], updatedKeys: Set<AnyHashable>?) {
        if let serverTimestamp = (payload as NSDictionary).optionalDate(forKey: "time") {
            self.serverTimestamp = serverTimestamp
            self.expectsReadConfirmation = self.conversation?.hasReadReceiptsEnabled ?? false
        }

        conversation?.updateTimestampsAfterUpdatingMessage(self)

        // NOTE: Calling super since this is method overriden to handle special cases when receiving an asset
        super.startDestructionIfNeeded()
    }

    public override var isSilenced: Bool {
        return conversation?.isMessageSilenced(underlyingMessage, senderID: sender?.remoteIdentifier) ?? true
    }

    // Private implementation
    @NSManaged fileprivate var assetID_data: Data
    @NSManaged fileprivate var preprocessedSize_data: Data
    @NSManaged fileprivate var associatedTaskIdentifier_data: Data

}

// MARK: - Core data
extension ZMAssetClientMessage {

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        self.cachedUnderlyingAssetMessage = nil
    }

    override public func awakeFromFetch() {
        super.awakeFromFetch()
        self.cachedUnderlyingAssetMessage = nil
    }

    override public func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        super.awake(fromSnapshotEvents: flags)
        self.cachedUnderlyingAssetMessage = nil
    }

    override public func didTurnIntoFault() {
        super.didTurnIntoFault()
        self.cachedUnderlyingAssetMessage = nil
    }

    public override static func entityName() -> String {
        return "AssetClientMessage"
    }

    public override var ignoredKeys: Set<AnyHashable>? {
        return (super.ignoredKeys ?? Set())
            .union([
                #keyPath(ZMAssetClientMessage.assetID_data),
                #keyPath(ZMAssetClientMessage.preprocessedSize_data),
                #keyPath(ZMAssetClientMessage.hasDownloadedPreview),
                #keyPath(ZMAssetClientMessage.hasDownloadedFile),
                #keyPath(ZMAssetClientMessage.dataSet),
                #keyPath(ZMAssetClientMessage.downloadState),
                #keyPath(ZMAssetClientMessage.progress),
                #keyPath(ZMAssetClientMessage.associatedTaskIdentifier_data),
                #keyPath(ZMAssetClientMessage.version)
            ])

    }

    override static public func predicateForObjectsThatNeedToBeUpdatedUpstream() -> NSPredicate? {
        return nil
    }
}

@objc public enum AssetClientMessageDataType: UInt {
    case placeholder = 1
    case fullAsset = 2
    case thumbnail = 3
}

@objc public enum AssetDownloadState: Int16 {
    case remote = 0
    case downloaded
    case downloading
}

@objc public enum AssetTransferState: Int16 {
    case uploading = 0
    case uploaded
    case uploadingFailed
    case uploadingCancelled
}

@objc public enum AssetProcessingState: Int16 {
    case done = 0
    case preprocessing
    case uploading
}

struct CacheAsset: AssetType {

    enum AssetType {
        case image, file, thumbnail
    }

    var owner: ZMAssetClientMessage
    var type: AssetType
    var cache: FileAssetCache

    init(owner: ZMAssetClientMessage, type: AssetType, cache: FileAssetCache) {
        self.owner = owner
        self.type = type
        self.cache = cache
    }

    var needsPreprocessing: Bool {
        switch type {
        case .file:
            return false
        case .image,
             .thumbnail:
            return true
        }
    }

    var hasOriginal: Bool {
        if case .file = type {
            return cache.hasDataOnDisk(owner, encrypted: false)
        } else {
            return cache.hasDataOnDisk(owner, format: .original, encrypted: false)
        }
    }

    var original: Data? {
        if case .file = type {
            return cache.assetData(owner, encrypted: false)
        } else {
            return cache.assetData(owner, format: .original, encrypted: false)
        }
    }

    var hasPreprocessed: Bool {
        guard needsPreprocessing else { return false }

        return cache.hasDataOnDisk(owner, format: .medium, encrypted: false)
    }

    var preprocessed: Data? {
        guard needsPreprocessing else { return nil }

        return cache.assetData(owner, format: .medium, encrypted: false)
    }

    var hasEncrypted: Bool {
        switch type {
        case .file:
            return cache.hasDataOnDisk(owner, encrypted: true)
        case .image, .thumbnail:
            return cache.hasDataOnDisk(owner, format: .medium, encrypted: true)
        }
    }

    var encrypted: Data? {
        switch type {
        case .file:
            return cache.assetData(owner, encrypted: true)
        case .image, .thumbnail:
            return cache.assetData(owner, format: .medium, encrypted: true)
        }
    }

    var isUploaded: Bool {
        guard let genericMessage = owner.underlyingMessage else { return false }

        switch type {
        case .thumbnail:
            return genericMessage.assetData?.preview.remote.hasAssetID ?? false
        case .file, .image:
            return genericMessage.assetData?.uploaded.hasAssetID ?? false
        }

    }

    func updateWithAssetId(_ assetId: String, token: String?, domain: String?) {
        guard var genericMessage = owner.underlyingMessage else { return }

        switch type {
        case .thumbnail:
            genericMessage.updatePreview(assetId: assetId, token: token, domain: domain)
        case .image, .file:
            genericMessage.updateUploaded(assetId: assetId, token: token, domain: domain)
        }

        do {
            try owner.mergeWithExistingData(message: genericMessage)
        } catch {
            Logging.messageProcessing.warn("Failed to update asset id. Reason: \(error.localizedDescription)")
            return
        }

        // Now that we've stored the assetId when can safely delete the encrypted data
        switch type {
        case .file:
            cache.deleteAssetData(owner, encrypted: true)
        case .image, .thumbnail:
            cache.deleteAssetData(owner, format: .medium, encrypted: true)
        }
    }

    func updateWithPreprocessedData(_ preprocessedImageData: Data, imageProperties: ZMIImageProperties) {
        guard needsPreprocessing else { return }
        guard var genericMessage = owner.underlyingMessage else { return }

        cache.storeAssetData(owner, format: .medium, encrypted: false, data: preprocessedImageData)

        switch type {
        case .file:
            return
        case .image:
            genericMessage.updateAssetOriginal(withImageProperties: imageProperties)
        case .thumbnail:
            genericMessage.updateAssetPreview(withImageProperties: imageProperties)
        }

        do {
            try owner.setUnderlyingMessage(genericMessage)
        } catch {
            Logging.messageProcessing.warn("Failed to update preprocessed image data. Reason: \(error.localizedDescription)")
        }
    }

    func encrypt() {
        guard var genericMessage = owner.underlyingMessage else { return }

        switch type {
        case .file:
            if let keys = cache.encryptFileAndComputeSHA256Digest(owner) {
                genericMessage.updateAsset(withUploadedOTRKey: keys.otrKey, sha256: keys.sha256!)
            }
        case .image:
            if !needsPreprocessing, let original = original {
                // Even if we don't do any preprocessing on an image we still need to copy it to .medium
                cache.storeAssetData(owner, format: .medium, encrypted: false, data: original)
            }

            if let keys = cache.encryptImageAndComputeSHA256Digest(owner, format: .medium) {
                genericMessage.updateAsset(withUploadedOTRKey: keys.otrKey, sha256: keys.sha256!)
            }
        case .thumbnail:
            if let keys = cache.encryptImageAndComputeSHA256Digest(owner, format: .medium) {
                genericMessage.updateAssetPreview(withUploadedOTRKey: keys.otrKey, sha256: keys.sha256!)
            }
        }

        do {
            try owner.setUnderlyingMessage(genericMessage)
        } catch {
            Logging.messageProcessing.warn("Failed to encrypt asset message data. Reason: \(error.localizedDescription)")
        }
    }

}

extension ZMAssetClientMessage: AssetMessage {

    public var assets: [AssetType] {
        guard let cache = managedObjectContext?.zm_fileAssetCache else { return [] }

        var assets: [AssetType] = []

        if isFile {
            if cache.hasDataOnDisk(self, encrypted: false) {
                assets.append(CacheAsset(owner: self, type: .file, cache: cache))
            }

            if cache.hasDataOnDisk(self, format: .original, encrypted: false) {
                assets.append(CacheAsset(owner: self, type: .thumbnail, cache: cache))
            }
        } else {
            if cache.hasDataOnDisk(self, format: .original, encrypted: false) {
                assets.append(CacheAsset(owner: self, type: .image, cache: cache))
            }
        }

        return assets
    }

    public var processingState: AssetProcessingState {
        let assets = self.assets

        if assets.filter({$0.needsPreprocessing && !$0.hasPreprocessed || !$0.isUploaded && !$0.hasEncrypted}).count > 0 {
            return .preprocessing
        }

        if assets.filter({!$0.isUploaded}).count > 0 {
            return .uploading
        }

        return .done
    }

}

/// Exposes all the assets which are contained within a message
public protocol AssetMessage {

    /// List of assets which the message contains.
    ///
    /// NOTE: The order of this list needs to be stable.
    var assets: [AssetType] { get }

    /// Summary of the processing state for the assets
    var processingState: AssetProcessingState { get }

}

/// Represent a single asset like file, thumbnail, image and image preview.
/// rename to AssetType to prevent build error due to name conflict with Proto.Asset struct
public protocol AssetType {

    /// True if the original unprocessed data is available on disk
    var hasOriginal: Bool { get }

    /// Original unprocessed data
    var original: Data? { get }

    /// True if this asset needs image processing
    var needsPreprocessing: Bool { get }

    /// If the preprocessed data is available on disk
    var hasPreprocessed: Bool { get }

    // Preprocessed data
    var preprocessed: Data? { get }

    /// True if the encrypted data is available on disk
    var hasEncrypted: Bool { get }

    /// Encrypted data
    var encrypted: Data? { get }

    /// True if the encrypted data has been uploaded to the backend
    var isUploaded: Bool { get }

    /// Update the asset with the asset id and token received from the backend
    func updateWithAssetId(_ assetId: String, token: String?, domain: String?)

    /// Update the asset with preprocessed image data
    func updateWithPreprocessedData(_ preprocessedImageData: Data, imageProperties: ZMIImageProperties)

    /// Encrypt the original or preprocessed data
    func encrypt()

}
