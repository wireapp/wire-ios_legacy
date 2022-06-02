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

@objcMembers public final class AssetV2DownloadRequestStrategy: AbstractRequestStrategy, ZMDownstreamTranscoder, ZMContextChangeTrackerSource {

    fileprivate var assetDownstreamObjectSync: ZMDownstreamObjectSyncWithWhitelist!
    private var notificationTokens: [Any] = []

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        configuration = [.allowsRequestsWhileOnline]

        let downloadPredicate = NSPredicate { (object, _) -> Bool in
            guard let message = object as? ZMAssetClientMessage else { return false }
            guard message.version < 3 else { return false }

            return !message.hasDownloadedFile && message.transferState == .uploaded && message.isDownloading
        }

        assetDownstreamObjectSync = ZMDownstreamObjectSyncWithWhitelist(transcoder: self,
                                                                        entityName: ZMAssetClientMessage.entityName(),
                                                                        predicateForObjectsToDownload: downloadPredicate,
                                                                        managedObjectContext: managedObjectContext)

        registerForCancellationNotification()
        registerForWhitelistingNotification()
    }

    func registerForCancellationNotification() {

        notificationTokens.append(NotificationInContext.addObserver(name: ZMAssetClientMessage.didCancelFileDownloadNotificationName,
                                                                    context: self.managedObjectContext.notificationContext,
                                                                    object: nil) { [weak self] note in
            guard let objectID = note.object as? NSManagedObjectID else { return }
            self?.cancelOngoingRequestForAssetClientMessage(objectID)
        })
    }

    func registerForWhitelistingNotification() {
        notificationTokens.append(NotificationInContext.addObserver(name: ZMAssetClientMessage.assetDownloadNotificationName,
                                                                    context: self.managedObjectContext.notificationContext,
                                                                    object: nil) { [weak self] note in
            guard let objectID = note.object as? NSManagedObjectID else { return }
            self?.didRequestToDownloadAsset(objectID)
        })
    }

    func didRequestToDownloadAsset(_ objectID: NSManagedObjectID) {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }
            guard let object = try? self.managedObjectContext.existingObject(with: objectID) else { return }
            guard let message = object as? ZMAssetClientMessage else { return }
            message.isDownloading = true
            self.assetDownstreamObjectSync.whiteListObject(message)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    func cancelOngoingRequestForAssetClientMessage(_ objectID: NSManagedObjectID) {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }
            guard let message = self.managedObjectContext.registeredObject(for: objectID) as? ZMAssetClientMessage else { return }
            guard message.version < 3 else { return }
            guard let identifier = message.associatedTaskIdentifier else { return }
            self.applicationStatus?.requestCancellation.cancelTask(with: identifier)
            message.associatedTaskIdentifier = nil
        }
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return self.assetDownstreamObjectSync.nextRequest(for: apiVersion)
    }

    fileprivate func handleResponse(_ response: ZMTransportResponse, forMessage assetClientMessage: ZMAssetClientMessage) {
        var downloadSuccess = false

        assetClientMessage.isDownloading = false

        if response.result == .success {
            guard let asset = assetClientMessage.underlyingMessage?.assetData else { return }
            guard assetClientMessage.visibleInConversation != nil else {
                // If the assetClientMessage was "deleted" (e.g. due to ephemeral) before the download finished, 
                // we don't want to update the message
                return
            }

            // TODO: create request that streams directly to the cache file, otherwise the memory would overflow on big files
            let fileCache = self.managedObjectContext.zm_fileAssetCache!
            fileCache.storeAssetData(assetClientMessage, encrypted: true, data: response.rawData!)

            downloadSuccess = fileCache.decryptFileIfItMatchesDigest(
                assetClientMessage,
                encryptionKey: asset.uploaded.otrKey,
                sha256Digest: asset.uploaded.sha256
            )

            if downloadSuccess {
                NotificationDispatcher.notifyNonCoreDataChanges(objectID: assetClientMessage.objectID,
                                                                changedKeys: [#keyPath(ZMAssetClientMessage.hasDownloadedFile)],
                                                                uiContext: self.managedObjectContext.zm_userInterface!)
            }
        }
    }

    // MARK: - ZMContextChangeTrackerSource

    public var contextChangeTrackers: [ZMContextChangeTracker] {
            return [self.assetDownstreamObjectSync]
    }

    // MARK: - ZMDownstreamTranscoder

    public func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!, apiVersion: APIVersion) -> ZMTransportRequest! {
        if let assetClientMessage = object as? ZMAssetClientMessage {

            let taskCreationHandler = ZMTaskCreatedHandler(on: managedObjectContext) { taskIdentifier in
                assetClientMessage.associatedTaskIdentifier = taskIdentifier
            }

            let completionHandler = ZMCompletionHandler(on: self.managedObjectContext) { response in
                self.handleResponse(response, forMessage: assetClientMessage)
            }

            let progressHandler = ZMTaskProgressHandler(on: self.managedObjectContext) { progress in
                assetClientMessage.progress = progress
                self.managedObjectContext.enqueueDelayedSave()
            }

            if let request = ClientMessageRequestFactory().downstreamRequestForEcryptedOriginalFileMessage(assetClientMessage, apiVersion: apiVersion) {
                request.add(taskCreationHandler)
                request.add(completionHandler)
                request.add(progressHandler)
                return request
            }
        }

        fatalError("Cannot generate request for \(object.safeForLoggingDescription)")
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }
}
