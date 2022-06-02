//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

public class AvailabilityRequestStrategy: AbstractRequestStrategy {

    var modifiedSync: ZMUpstreamModifiedObjectSync!

    private let maximumBroadcastRecipients = 500

    override public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.modifiedSync = ZMUpstreamModifiedObjectSync(transcoder: self,
                                                         entityName: ZMUser.entityName(),
                                                         update: nil,
                                                         filter: ZMUser.predicateForSelfUser(),
                                                         keysToSync: [AvailabilityKey],
                                                         managedObjectContext: managedObjectContext)
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return modifiedSync.nextRequest(for: apiVersion)
    }

}

extension AvailabilityRequestStrategy: ZMUpstreamTranscoder {

    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>, apiVersion: APIVersion) -> ZMUpstreamRequest? {
        guard let selfUser = managedObject as? ZMUser else { return nil }

        let originalPath = "/broadcast/otr/messages"
        let message = GenericMessage(content: WireProtos.Availability(selfUser.availability))
        let recipients = ZMUser.recipientsForAvailabilityStatusBroadcast(in: context, maxCount: maximumBroadcastRecipients)

        guard let dataAndMissingClientStrategy = message.encryptForTransport(forBroadcastRecipients: recipients, in: context) else {
            return nil
        }

        let protobufContentType = "application/x-protobuf"
        let path = originalPath.pathWithMissingClientStrategy(strategy: dataAndMissingClientStrategy.strategy)

        let request = ZMTransportRequest(path: path,
                                         method: .methodPOST,
                                         binaryData: dataAndMissingClientStrategy.data,
                                         type: protobufContentType,
                                         contentDisposition: nil,
                                         apiVersion: apiVersion.rawValue)

        return ZMUpstreamRequest(keys: keys, transportRequest: request)
    }

    public func dependentObjectNeedingUpdate(beforeProcessingObject dependant: ZMManagedObject) -> Any? {
        return dependentObjectNeedingUpdateBeforeProcessing
    }

    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable: Any]? = nil, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {
        guard let clientRegistrationDelegate = applicationStatus?.clientRegistrationDelegate else { return false }

        _ = parseUploadResponse(response, clientRegistrationDelegate: clientRegistrationDelegate)

        return false
    }

    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse, keysToParse keys: Set<String>) -> Bool {
        guard let clientRegistrationDelegate = applicationStatus?.clientRegistrationDelegate else { return false }

        return parseUploadResponse(response, clientRegistrationDelegate: clientRegistrationDelegate).contains(.missing)
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }

    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?, apiVersion: APIVersion) -> ZMUpstreamRequest? {
        return nil // we will never insert objects
    }

    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        // we will never insert objects
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }

}

extension AvailabilityRequestStrategy: OTREntity {

    public var context: NSManagedObjectContext {
        return managedObjectContext
    }

    public var conversation: ZMConversation? {
        return nil
    }

    public func missesRecipients(_ recipients: Set<UserClient>!) {
        // BE notified us about a new client. A session will be established and then we'll try again
    }

    public func detectedRedundantUsers(_ users: [ZMUser]) {
        // We were sending a message to clients which should not receive it. To recover
        // from this we must restart the slow sync.
        applicationStatus?.requestSlowSync()
    }

    public func delivered(with response: ZMTransportResponse) {
        // no-op
    }

    public var dependentObjectNeedingUpdateBeforeProcessing: NSObject? {
        let recipients = ZMUser.recipientsForAvailabilityStatusBroadcast(in: context, maxCount: maximumBroadcastRecipients)
        return self.dependentObjectNeedingUpdateBeforeProcessingOTREntity(recipients: recipients)
    }

    public var isExpired: Bool {
        return false
    }

    public var expirationDate: Date? {
        return nil
    }

    public func expire() {
        // nop
    }

}

extension AvailabilityRequestStrategy: ZMContextChangeTrackerSource {

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [modifiedSync]
    }

}

extension AvailabilityRequestStrategy: ZMEventConsumer {

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        for event in events {
            guard
                let senderUUID = event.senderUUID, event.isGenericMessageEvent,
                let message = GenericMessage(from: event), message.hasAvailability
            else {
                continue
            }

            let user = ZMUser.fetch(with: senderUUID, in: managedObjectContext)
            user?.updateAvailability(from: message)
        }
    }

}
