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

@objcMembers public final class LinkPreviewAssetDownloadRequestStrategy: AbstractRequestStrategy {

    private let requestFactory = AssetDownloadRequestFactory()

    fileprivate var assetDownstreamObjectSync: ZMDownstreamObjectSyncWithWhitelist!
    private var notificationToken: Any?

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        let downloadFilter = NSPredicate { object, _ in
            guard let message = object as? ZMClientMessage,
                let genericMessage = message.underlyingMessage,
                genericMessage.textData != nil else {
                    return false
            }
            guard let preview = genericMessage.linkPreviews.first else {
                return false
            }
            guard nil == managedObjectContext.zm_fileAssetCache.assetData(message, format: .medium, encrypted: false) else { return false }
            return preview.image.uploaded.hasAssetID
        }

        assetDownstreamObjectSync = ZMDownstreamObjectSyncWithWhitelist(
            transcoder: self,
            entityName: ZMClientMessage.entityName(),
            predicateForObjectsToDownload: downloadFilter,
            managedObjectContext: managedObjectContext
        )

        registerForWhitelistingNotification()
    }

    func registerForWhitelistingNotification() {
        self.notificationToken = NotificationInContext.addObserver(name: ZMClientMessage.linkPreviewImageDownloadNotification,
                                                                   context: self.managedObjectContext.notificationContext,
                                                                   object: nil) { [weak self] note in
            guard let objectID = note.object as? NSManagedObjectID else { return }
            self?.didWhitelistAssetDownload(objectID)
        }
    }

    func didWhitelistAssetDownload(_ objectID: NSManagedObjectID) {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }
            guard let message = try? self.managedObjectContext.existingObject(with: objectID) as? ZMClientMessage else { return }
            self.assetDownstreamObjectSync.whiteListObject(message)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return assetDownstreamObjectSync.nextRequest(for: apiVersion)
    }

    func handleResponse(_ response: ZMTransportResponse!, forMessage message: ZMClientMessage) {
        guard response.result == .success else { return }
        let cache = managedObjectContext.zm_fileAssetCache!

        let linkPreview = message.underlyingMessage?.linkPreviews.first
        guard
            let remote = linkPreview?.image.uploaded,
            let data = response.rawData else {
                return
        }
        cache.storeAssetData(message, format: .medium, encrypted: true, data: data)

        let success = cache.decryptImageIfItMatchesDigest(
            message,
            format: .medium,
            encryptionKey: remote.otrKey,
            sha256Digest: remote.sha256
        )

        guard success else { return }

        guard let uiMOC = managedObjectContext.zm_userInterface else { return }
        NotificationDispatcher.notifyNonCoreDataChanges(objectID: message.objectID,
                                                        changedKeys: [ZMClientMessage.linkPreviewKey, #keyPath(ZMAssetClientMessage.hasDownloadedPreview)],
                                                        uiContext: uiMOC)
    }

}

extension LinkPreviewAssetDownloadRequestStrategy: ZMContextChangeTrackerSource {

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [assetDownstreamObjectSync]
    }

}

extension LinkPreviewAssetDownloadRequestStrategy: ZMDownstreamTranscoder {

    public func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!, apiVersion: APIVersion) -> ZMTransportRequest! {
        guard let message = object as? ZMClientMessage else { fatal("Unable to generate request for \(object.safeForLoggingDescription)") }
        guard let linkPreview = message.underlyingMessage?.linkPreviews.first else {
            return nil
        }
        let remoteData = linkPreview.image.uploaded

        // Protobuf initializes the token to an empty string when set to nil
        let token = remoteData.hasAssetToken && remoteData.assetToken != "" ? remoteData.assetToken : nil
        let domain = remoteData.assetDomain
        let request = requestFactory.requestToGetAsset(withKey: remoteData.assetID, token: token, domain: domain, apiVersion: apiVersion)
        request?.add(ZMCompletionHandler(on: managedObjectContext) { response in
            self.handleResponse(response, forMessage: message)
        })
        return request
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // no-op
    }

}
