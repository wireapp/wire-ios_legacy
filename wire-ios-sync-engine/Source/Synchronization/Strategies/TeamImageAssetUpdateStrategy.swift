//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireRequestStrategy

/// TeamImageAssetUpdateStrategy is responsible for downloading the image associated with a team

public final class TeamImageAssetUpdateStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource, ZMDownstreamTranscoder {

    fileprivate var downstreamRequestSync: ZMDownstreamObjectSyncWithWhitelist!
    fileprivate var observer: Any!

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        downstreamRequestSync = ZMDownstreamObjectSyncWithWhitelist(transcoder: self,
                                                                    entityName: Team.entityName(),
                                                                    predicateForObjectsToDownload: Team.imageDownloadFilter,
                                                                    managedObjectContext: managedObjectContext)

        observer = NotificationInContext.addObserver(name: .teamDidRequestAsset, context: managedObjectContext.notificationContext, using: { [weak self] in self?.requestAssetForNotification(note: $0) })
    }

    private func requestAssetForNotification(note: NotificationInContext) {
        managedObjectContext.performGroupedBlock {
            guard let objectID = note.object as? NSManagedObjectID,
                  let object = self.managedObjectContext.object(with: objectID) as? ZMManagedObject else { return }

            self.downstreamRequestSync.whiteListObject(object)
            RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        }
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return downstreamRequestSync?.nextRequest(for: apiVersion)
    }

    // MARK: - ZMContextChangeTrackerSource {

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [downstreamRequestSync]
    }

    // MARK: - ZMDownstreamTranscoder

    public func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!, apiVersion: APIVersion) -> ZMTransportRequest! {
        guard let team = object as? Team, let assetId = team.pictureAssetId else { return nil }

        return ZMTransportRequest.imageGet(fromPath: "/assets/v3/\(assetId)", apiVersion: apiVersion.rawValue)
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard let team = object as? Team else { return }

        team.pictureAssetId = nil
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard let team = object as? Team else { return }

        team.imageData = response.rawData
    }

}
