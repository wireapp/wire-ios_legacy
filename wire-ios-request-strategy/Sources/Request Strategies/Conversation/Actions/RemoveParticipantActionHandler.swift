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

extension ConversationRemoveParticipantError {

    public init?(response: ZMTransportResponse) {
       switch (response.httpStatus, response.payloadLabel()) {
       case (403, "invalid-op"?): self = .invalidOperation
       case (404, "no-conversation"?): self = .conversationNotFound
       case (400..<499, _): self = .unknown
       default: return nil
       }
   }

}

class RemoveParticipantActionHandler: ActionHandler<RemoveParticipantAction> {

    override func request(for action: RemoveParticipantAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        switch apiVersion {
        case .v0:
            return nonFederatedRequest(for: action, apiVersion: apiVersion)
        case .v1:
            return federatedRequest(for: action, apiVersion: apiVersion)
        }
    }

    func nonFederatedRequest(for action: RemoveParticipantAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard
            apiVersion == .v0,
            let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
            let conversationID = conversation.remoteIdentifier?.transportString(),
            let user = ZMUser.existingObject(for: action.userID, in: context),
            let userID = user.remoteIdentifier?.transportString()
        else {
            action.notifyResult(.failure(.unknown))
            // Log error
            return nil
        }

        let path = "/conversations/\(conversationID)/members/\(userID)"
        return ZMTransportRequest(path: path, method: .methodDELETE, payload: nil, apiVersion: apiVersion.rawValue)
    }

    func federatedRequest(for action: RemoveParticipantAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard
            apiVersion > .v0,
            let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
            let conversationID = conversation.qualifiedID,
            let user: ZMUser = ZMUser.existingObject(for: action.userID, in: context),
            let qualifiedUserID = user.qualifiedID
        else {
            action.notifyResult(.failure(.unknown))
            // Log error
            return nil
        }
        let path = "/conversations/\(conversationID.domain)/\(conversationID.uuid)/members/\(qualifiedUserID.domain)/\(qualifiedUserID.uuid)"

        return ZMTransportRequest(path: path, method: .methodDELETE, payload: nil, apiVersion: apiVersion.rawValue)
    }

    override func handleResponse(_ response: ZMTransportResponse, action: RemoveParticipantAction) {
        var action = action

        switch response.httpStatus {
        case 200:

            guard
                let user = ZMUser.existingObject(for: action.userID, in: context),
                let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
                let payload = response.payload,
                let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil),
                let rawData = response.rawData,
                let apiVersion = APIVersion(rawValue: response.apiVersion),
                let conversationEvent = decodeResponse(data: rawData, apiVersion: apiVersion)
            else {
                Logging.network.warn("Can't process response, aborting.")
                action.notifyResult(.failure(.unknown))
                return
            }

            // TODO jacob this logic should be moved to data model
            // Update cleared timestamp if self user left and deleted history
            if let clearedTimestamp = conversation.clearedTimeStamp, clearedTimestamp == conversation.lastServerTimeStamp, user.isSelfUser {
                conversation.updateCleared(fromPostPayloadEvent: updateEvent)
            }

            conversationEvent.process(in: context, originalEvent: updateEvent)

            action.notifyResult(.success(Void()))

        case 204:
            action.notifyResult(.success(Void()))
        default:
            action.notifyResult(.failure(ConversationRemoveParticipantError(response: response) ?? .unknown))
        }
    }

    private func decodeResponse(data: Data, apiVersion: APIVersion) -> Payload.ConversationEvent<Payload.UpdateConverationMemberLeave>? {
        switch apiVersion {
        case .v0, .v1:
            return Payload.ConversationEvent<Payload.UpdateConverationMemberLeave>(data, decoder: .defaultDecoder)
        }
    }

}
