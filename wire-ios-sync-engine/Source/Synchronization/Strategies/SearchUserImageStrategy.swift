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

private let userPath = "/users?ids="

public class SearchUserImageStrategy: AbstractRequestStrategy {

    fileprivate unowned var uiContext: NSManagedObjectContext
    fileprivate unowned var syncContext: NSManagedObjectContext

    fileprivate var requestedMissingFullProfiles: Set<UUID> = Set()
    fileprivate var requestedMissingFullProfilesInProgress: Set<UUID> = Set()

    fileprivate var requestedPreviewAssets: [UUID: SearchUserAssetKeys?] = [:]
    fileprivate var requestedCompleteAssets: [UUID: SearchUserAssetKeys?] = [:]
    fileprivate var requestedUserDomain: [UUID: String] = [:]
    fileprivate var requestedPreviewAssetsInProgress: Set<UUID> = Set()
    fileprivate var requestedCompleteAssetsInProgress: Set<UUID> = Set()

    fileprivate var observers: [Any] = []

    @available (*, unavailable)
    public override init(withManagedObjectContext moc: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        fatalError()
    }

    public init(applicationStatus: ApplicationStatus, managedObjectContext: NSManagedObjectContext) {

        self.syncContext = managedObjectContext
        self.uiContext = managedObjectContext.zm_userInterface

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        observers.append(NotificationInContext.addObserver(
            name: .searchUserDidRequestPreviewAsset,
            context: managedObjectContext.notificationContext,
            using: { [weak self] in
                self?.requestAsset(with: $0)
            })
        )

        observers.append(NotificationInContext.addObserver(
            name: .searchUserDidRequestCompleteAsset,
            context: managedObjectContext.notificationContext,
            using: { [weak self] in
                self?.requestAsset(with: $0)
            })
        )
    }

    public func requestAsset(with note: NotificationInContext) {
        guard let searchUser = note.object as? ZMSearchUser, let userId = searchUser.remoteIdentifier else { return }

        if !searchUser.hasDownloadedFullUserProfile {
            requestedMissingFullProfiles.insert(userId)
        }

        switch note.name {
        case .searchUserDidRequestPreviewAsset:
            requestedPreviewAssets[userId] = searchUser.assetKeys
        case .searchUserDidRequestCompleteAsset:
            requestedCompleteAssets[userId] = searchUser.assetKeys
        default:
            break
        }

        if let domain = searchUser.domain {
            requestedUserDomain[userId] = domain
        }

        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        let request = fetchUserProfilesRequest(apiVersion: apiVersion) ?? fetchAssetRequest(apiVersion: apiVersion)
        request?.setDebugInformationTranscoder(self)
        return request
    }

    func fetchAssetRequest(apiVersion: APIVersion) -> ZMTransportRequest? {
        let previewAssetRequest = requestedPreviewAssets.first(where: {
            !(self.requestedPreviewAssetsInProgress.contains($0.key) ||
                $0.value == nil)
        })

        if let previewAssetRequest = previewAssetRequest,
           let assetKeys = previewAssetRequest.value,
           let request = request(for: assetKeys, size: .preview, user: previewAssetRequest.key, apiVersion: apiVersion) {
            requestedPreviewAssetsInProgress.insert(previewAssetRequest.key)

            request.add(ZMCompletionHandler(on: syncContext, block: { [weak self] (response) in
                self?.processAsset(response: response, for: previewAssetRequest.key, size: .preview)
            }))

            return request
        }

        let completeAssetRequest = requestedCompleteAssets.first(where: {
            !(self.requestedCompleteAssetsInProgress.contains($0.key) ||
                $0.value == nil)
        })

        if let completeAssetRequest = completeAssetRequest,
           let assetKeys = completeAssetRequest.value,
           let request = request(for: assetKeys, size: .complete, user: completeAssetRequest.key, apiVersion: apiVersion) {
            requestedCompleteAssetsInProgress.insert(completeAssetRequest.key)

            request.add(ZMCompletionHandler(on: syncContext, block: { [weak self] (response) in
                self?.processAsset(response: response, for: completeAssetRequest.key, size: .complete)
            }))

            return request
        }

        return nil
    }

    func request(for assetKeys: SearchUserAssetKeys, size: ProfileImageSize, user: UUID, apiVersion: APIVersion) -> ZMTransportRequest? {
        if let key = size == .preview ? assetKeys.preview : assetKeys.complete {
            let path: String

            switch apiVersion {
            case .v0:
                path = "/assets/v3/\(key)"
            case .v1:
                guard let domain = requestedUserDomain[user] ?? APIVersion.domain else {
                    return nil
                }

                path = "/assets/v4/\(domain)/\(key)"
            }

            return ZMTransportRequest(getFromPath: path, apiVersion: apiVersion.rawValue)
        }
        return nil
    }

    func processAsset(response: ZMTransportResponse, for user: UUID, size: ProfileImageSize) {

        let tryAgain = response.result != .permanentError && response.result != .success

        switch size {
        case .preview:
            if !tryAgain {
                requestedPreviewAssets.removeValue(forKey: user)
            }
            requestedPreviewAssetsInProgress.remove(user)
        case .complete:
            if !tryAgain {
                requestedCompleteAssets.removeValue(forKey: user)
            }
            requestedCompleteAssetsInProgress.remove(user)
        }

        uiContext.performGroupedBlock {
            guard let searchUser = self.uiContext.zm_searchUserCache?.object(forKey: user as NSUUID) else { return }

            if response.result == .success {
                if let imageData = response.imageData ?? response.rawData {
                    searchUser.updateImageData(for: size, imageData: imageData)
                }
            } else if response.result == .permanentError {
                searchUser.reportImageDataHasBeenDeleted()
            }
        }
    }

    func fetchUserProfilesRequest(apiVersion: APIVersion) -> ZMTransportRequest? {
        let missingFullProfiles = requestedMissingFullProfiles.subtracting(requestedMissingFullProfilesInProgress)

        guard missingFullProfiles.count > 0 else { return nil }

        requestedMissingFullProfilesInProgress.formUnion(missingFullProfiles)

        return SearchUserImageStrategy.requestForFetchingFullProfile(for: missingFullProfiles, apiVersion: apiVersion, completionHandler: ZMCompletionHandler(on: managedObjectContext, block: { (response) in

            self.requestedMissingFullProfilesInProgress.subtract(missingFullProfiles)

            // On temporary errors we keep requestedMissingFullProfiles so that we'll retry the request
            if response.result == .success || response.result == .permanentError {
                self.requestedMissingFullProfiles.subtract(missingFullProfiles)
            }

            guard response.result == .success else { return }

            self.uiContext.performGroupedBlock {
                guard let userProfilePayloads = response.payload as? [[String: Any]] else { return }

                for userProfilePayload in userProfilePayloads {
                    guard let userId = (userProfilePayload["id"] as? String).flatMap(UUID.init),
                          let searchUser = self.uiContext.zm_searchUserCache?.object(forKey: userId as NSUUID) else { continue }

                    searchUser.update(from: userProfilePayload)

                    if let assetKeys = searchUser.assetKeys {
                        self.updateAssetKeys(assetKeys, for: userId)
                    }
                }
            }
        }))
    }

    func updateAssetKeys(_ assetKeys: SearchUserAssetKeys, for userId: UUID) {
        syncContext.performGroupedBlock {
            if self.requestedPreviewAssets.keys.contains(userId) {
                self.requestedPreviewAssets[userId] = assetKeys
            }

            if self.requestedCompleteAssets.keys.contains(userId) {
                self.requestedCompleteAssets[userId] = assetKeys
            }

            RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        }
    }

    public static func requestForFetchingFullProfile(for usersWithIDs: Set<UUID>, apiVersion: APIVersion, completionHandler: ZMCompletionHandler) -> ZMTransportRequest {
        let usersList = usersWithIDs.map {$0.transportString()}.joined(separator: ",")
        let request = ZMTransportRequest(getFromPath: userPath + usersList, apiVersion: apiVersion.rawValue)
        request.add(completionHandler)
        return request
    }

}
