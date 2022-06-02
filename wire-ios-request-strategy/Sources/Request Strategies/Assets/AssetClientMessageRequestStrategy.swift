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

/// The `AssetClientMessageRequestStrategy` for creating requests to insert the genericMessage of a
/// `ZMAssetClientMessage` remotely. This is only necessary for the `/assets/v3' endpoint as we
/// upload the asset, receive the asset ID in the response, manually add it to the genericMessage and
/// send it using the `/messages` endpoint like any other message. This is an additional step required
/// as the fan-out was previously done by the backend when uploading a v2 asset.
public final class AssetClientMessageRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {

    let insertedObjectSync: InsertedObjectSync<AssetClientMessageRequestStrategy>
    let messageSync: ProteusMessageSync<ZMAssetClientMessage>

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {

        self.insertedObjectSync = InsertedObjectSync(insertPredicate: Self.shouldBeSentPredicate(context: managedObjectContext))
        self.messageSync = ProteusMessageSync(context: managedObjectContext, applicationStatus: applicationStatus)

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        insertedObjectSync.transcoder = self
        configuration = [.allowsRequestsWhileOnline,
                         .allowsRequestsWhileInBackground]
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return messageSync.nextRequest(for: apiVersion)
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [insertedObjectSync] + messageSync.contextChangeTrackers
    }

    static func shouldBeSentPredicate(context: NSManagedObjectContext) -> NSPredicate {
        let notDelivered = NSPredicate(format: "%K == FALSE", DeliveredKey)
        let notExpired = NSPredicate(format: "%K == 0", ZMMessageIsExpiredKey)
        let isUploaded = NSPredicate(format: "%K == \(AssetTransferState.uploaded.rawValue)", "transferState")
        let isAssetV3 = NSPredicate(format: "version >= 3")
        let fromSelf = NSPredicate(format: "%K == %@", ZMMessageSenderKey, ZMUser.selfUser(in: context))
        return NSCompoundPredicate(andPredicateWithSubpredicates: [notDelivered, notExpired, isAssetV3, isUploaded, fromSelf])
    }

}

extension AssetClientMessageRequestStrategy: InsertedObjectSyncTranscoder {

    typealias Object = ZMAssetClientMessage

    func insert(object: ZMAssetClientMessage, completion: @escaping () -> Void) {
        messageSync.sync(object) { [weak self] (result, response) in
            switch result {
            case .success:
                object.markAsSent()
            case .failure(let error):
                switch error {
                case .expired, .gaveUpRetrying:
                    object.expire()

                    let payload = Payload.ResponseFailure(response, decoder: .defaultDecoder)
                    if response.httpStatus == 403 && payload?.label == .missingLegalholdConsent {
                        self?.managedObjectContext.zm_userInterface.performGroupedBlock {
                            guard let context = self?.managedObjectContext.notificationContext else { return }
                            NotificationInContext(name: ZMConversation.failedToSendMessageNotificationName, context: context).post()
                        }
                    }
                }
            }
        }
    }

}
