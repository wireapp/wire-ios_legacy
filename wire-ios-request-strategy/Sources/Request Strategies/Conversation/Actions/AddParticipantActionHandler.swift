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

extension ConversationAddParticipantsError {

   public init?(response: ZMTransportResponse) {
       switch (response.httpStatus, response.payloadLabel()) {
       case (403, "invalid-op"?): self = .invalidOperation
       case (403, "access-denied"?): self = .accessDenied
       case (403, "not-connected"?): self = .notConnectedToUser
       case (404, "no-conversation"?): self = .conversationNotFound
       case (403, "too-many-members"?): self = .tooManyMembers
       case (412, "missing-legalhold-consent"?): self = .missingLegalHoldConsent
       case (400..<499, _): self = .unknown
       default: return nil
       }
   }

}

class AddParticipantActionHandler: ActionHandler<AddParticipantAction> {

    override func request(for action: AddParticipantAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        switch apiVersion {
        case .v0:
            return nonFederatedRequest(for: action, apiVersion: apiVersion)
        case .v1:
            return federatedRequest(for: action, apiVersion: apiVersion)
        }
    }

    func nonFederatedRequest(for action: AddParticipantAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard
            apiVersion == .v0,
            let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
            let conversationID = conversation.remoteIdentifier?.transportString(),
            let users: [ZMUser] = action.userIDs.existingObjects(in: context),
            let payload =  Payload.ConversationAddMember(userIDs: users.compactMap(\.remoteIdentifier)),
            let payloadData = payload.payloadData(encoder: .defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            action.notifyResult(.failure(.unknown))
            // Log error
            return nil
        }

        let path = "/conversations/\(conversationID)/members"
        return ZMTransportRequest(path: path, method: .methodPOST, payload: payloadAsString as ZMTransportData, apiVersion: apiVersion.rawValue)
    }

    func federatedRequest(for action: AddParticipantAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard
            apiVersion > .v0,
            let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
            let conversationID = conversation.qualifiedID,
            let users: [ZMUser] = action.userIDs.existingObjects(in: context),
            let qualifiedUserIDs = users.qualifiedUserIDs,
            let payload = Payload.ConversationAddMember(qualifiedUserIDs: qualifiedUserIDs),
            let payloadData = payload.payloadData(encoder: .defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            action.notifyResult(.failure(.unknown))
            // Log error
            return nil
        }
        let path = "/conversations/\(conversationID.uuid)/members/v2"

        return ZMTransportRequest(path: path, method: .methodPOST, payload: payloadAsString as ZMTransportData, apiVersion: apiVersion.rawValue)
    }

    override func handleResponse(_ response: ZMTransportResponse, action: AddParticipantAction) {
        var action = action

        switch response.httpStatus {
        case 200:

            guard
                let payload = response.payload,
                let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil),
                let rawData = response.rawData,
                let conversationEvent = Payload.ConversationEvent<Payload.UpdateConverationMemberJoin>(rawData, decoder: .defaultDecoder)
            else {
                Logging.network.warn("Can't process response, aborting.")
                action.notifyResult(.failure(.unknown))
                return
            }

            conversationEvent.process(in: context, originalEvent: updateEvent)

            action.notifyResult(.success(Void()))

        case 204:
            action.notifyResult(.success(Void()))
        default:
            if response.httpStatus == 403 {
                // Refresh user data since this operation might have failed
                // due to a team member being removed/deleted from the team.
                let users: [ZMUser]? = action.userIDs.existingObjects(in: context)
                users?.filter(\.isTeamMember).forEach({ $0.refreshData() })
            }

            action.notifyResult(.failure(ConversationAddParticipantsError(response: response) ?? .unknown))
        }
    }

}
