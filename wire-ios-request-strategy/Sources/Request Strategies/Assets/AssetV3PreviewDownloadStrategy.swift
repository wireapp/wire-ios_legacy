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

import WireImages
import WireTransport

private let zmLog = ZMSLog(tag: "AssetPreviewDownloading")

@objcMembers public final class AssetV3PreviewDownloadRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {

    private let requestFactory = AssetDownloadRequestFactory()

    fileprivate var downstreamSync: ZMDownstreamObjectSyncWithWhitelist!
    private var token: Any?

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        let filter = NSPredicate { object, _ in
            guard let message = object as? ZMAssetClientMessage, nil != message.fileMessageData else { return false }
            guard message.version >= 3, message.visibleInConversation != nil else { return false }
            guard nil != message.underlyingMessage?.previewAssetId else { return false }
            return !message.hasDownloadedPreview
        }

        downstreamSync = ZMDownstreamObjectSyncWithWhitelist(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            predicateForObjectsToDownload: filter,
            managedObjectContext: managedObjectContext
        )
        registerForWhitelistingNotification()
    }

    func registerForWhitelistingNotification() {

        self.token = NotificationInContext.addObserver(name: ZMAssetClientMessage.imageDownloadNotificationName,
                                                       context: self.managedObjectContext.notificationContext,
                                                       object: nil) { [weak self] note in
            guard let objectID = note.object as? NSManagedObjectID else { return }
            self?.didRequestToDownloadImage(objectID)
        }
    }

    func didRequestToDownloadImage(_ objectID: NSManagedObjectID) {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }
            guard let object = try? self.managedObjectContext.existingObject(with: objectID) else { return }
            guard let message = object as? ZMAssetClientMessage else { return }
            self.downstreamSync.whiteListObject(message)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return downstreamSync.nextRequest(for: apiVersion)
    }

    fileprivate func handleResponse(_ response: ZMTransportResponse, forMessage assetClientMessage: ZMAssetClientMessage) {
        guard let asset = assetClientMessage.underlyingMessage?.assetData, response.result == .success else { return }
        guard assetClientMessage.visibleInConversation != nil else { return }

        let remote = asset.preview.remote
        let cache = managedObjectContext.zm_fileAssetCache!
        cache.storeAssetData(assetClientMessage, format: .medium, encrypted: true, data: response.rawData!)

        // Decrypt the preview image file
        let success = cache.decryptImageIfItMatchesDigest(
            assetClientMessage,
            format: .medium,
            encryptionKey: remote.otrKey,
            sha256Digest: remote.sha256
        )

        if !success {
            managedObjectContext.delete(assetClientMessage)
            zmLog.error("Unable to decrypt preview image for file message: \(assetClientMessage), \(asset)")
        }

        // Notify about the changes
        guard let uiMOC = managedObjectContext.zm_userInterface else { return }
        NotificationDispatcher.notifyNonCoreDataChanges(objectID: assetClientMessage.objectID,
                                                        changedKeys: [#keyPath(ZMAssetClientMessage.hasDownloadedPreview)],
                                                        uiContext: uiMOC)
    }

    // MARK: - ZMContextChangeTrackerSource

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [downstreamSync]
    }

}

// MARK: - ZMDownstreamTranscoder

extension AssetV3PreviewDownloadRequestStrategy: ZMDownstreamTranscoder {

    public func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!, apiVersion: APIVersion) -> ZMTransportRequest! {
        if let assetClientMessage = object as? ZMAssetClientMessage,
            let asset = assetClientMessage.underlyingMessage?.assetData,
            assetClientMessage.version >= 3 {

            let remote = asset.preview.remote
            let token = remote.hasAssetToken ? remote.assetToken : nil
            if let request = requestFactory.requestToGetAsset(withKey: remote.assetID, token: token, domain: remote.assetDomain, apiVersion: apiVersion) {
                request.add(ZMCompletionHandler(on: self.managedObjectContext) { response in
                    self.handleResponse(response, forMessage: assetClientMessage)
                })
                return request
            }
        }

        fatal("Cannot generate request to download v3/v4 file preview for \(object.safeForLoggingDescription)")
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }

}
