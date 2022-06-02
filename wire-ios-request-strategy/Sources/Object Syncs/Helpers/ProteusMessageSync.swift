//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

public protocol ProteusMessage: OTREntity, EncryptedPayloadGenerator, Hashable {}

extension ZMClientMessage: ProteusMessage {}
extension ZMAssetClientMessage: ProteusMessage {}

/**
 ProteusMessageSync synchronizes messages with the backend using the Proteus encryption protocol.

 This only works with objects which implements the `ProteusMessage` protocol.
 */
public class ProteusMessageSync<Message: ProteusMessage>: NSObject, EntityTranscoder, ZMContextChangeTrackerSource, ZMRequestGenerator {

    public typealias Entity = Message
    public typealias OnRequestScheduledHandler = (_ message: Message, _ request: ZMTransportRequest) -> Void

    var dependencySync: DependencyEntitySync<ProteusMessageSync>!
    let requestFactory = ClientMessageRequestFactory()
    let applicationStatus: ApplicationStatus
    let context: NSManagedObjectContext
    var onRequestScheduledHandler: OnRequestScheduledHandler?

    public init(context: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        self.context = context
        self.applicationStatus = applicationStatus

        super.init()

        self.dependencySync = DependencyEntitySync<ProteusMessageSync>(transcoder: self, context: context)
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [dependencySync]
    }

    public func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return dependencySync.nextRequest(for: apiVersion)
    }

    public func onRequestScheduled(_ handler: @escaping OnRequestScheduledHandler) {
        onRequestScheduledHandler = handler
    }

    public func sync(_ message: Message, completion: @escaping EntitySyncHandler) {
        dependencySync.synchronize(entity: message, completion: completion)
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

    public func expireMessages(withDependency dependency: NSObject) {
        dependencySync.expireEntities(withDependency: dependency)
    }

    public func request(forEntity entity: Message, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            let conversation = entity.conversation,
            let request = requestFactory.upstreamRequestForMessage(entity, in: conversation, apiVersion: apiVersion)
        else {
            return nil
        }

        if let expirationDate = entity.expirationDate {
            request.expire(at: expirationDate)
        }

        onRequestScheduledHandler?(entity, request)

        return request
    }

    public func request(forEntity entity: Message, didCompleteWithResponse response: ZMTransportResponse) {
        entity.delivered(with: response)

        guard let apiVersion = APIVersion(rawValue: response.apiVersion) else { return }

        switch apiVersion {
        case .v0:
            _ = entity.parseUploadResponse(response, clientRegistrationDelegate: applicationStatus.clientRegistrationDelegate)
        case .v1:
            let payload = Payload.MessageSendingStatus(response, decoder: .defaultDecoder)
            _ = payload?.updateClientsChanges(for: entity)
        }

        purgeEncryptedPayloadCache()
    }

    public func shouldTryToResend(entity: Message, afterFailureWithResponse response: ZMTransportResponse) -> Bool {
        guard let apiVersion = APIVersion(rawValue: response.apiVersion) else { return false }

        switch response.httpStatus {
        case 412:
            switch apiVersion {
            case .v0:
                return entity.parseUploadResponse(response, clientRegistrationDelegate: applicationStatus.clientRegistrationDelegate).contains(.missing)
            case .v1:
                let payload = Payload.MessageSendingStatus(response, decoder: .defaultDecoder)
                return payload?.updateClientsChanges(for: entity) ?? false
            }

        default:
            let payload = Payload.ResponseFailure(response, decoder: .defaultDecoder)
            if payload?.label == .unknownClient {
                applicationStatus.clientRegistrationDelegate.didDetectCurrentClientDeletion()
            }

            if case .permanentError = response.result {
                return false
            } else {
                return true
            }
        }
    }

    fileprivate func purgeEncryptedPayloadCache() {
        guard let selfClient = ZMUser.selfUser(in: context).selfClient() else {
            return
        }
        selfClient.keysStore.encryptionContext.perform { (session) in
            session.purgeEncryptedPayloadCache()
        }
    }

}
