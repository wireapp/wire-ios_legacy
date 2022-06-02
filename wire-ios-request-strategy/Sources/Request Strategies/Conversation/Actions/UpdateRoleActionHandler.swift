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

class UpdateRoleActionHandler: ActionHandler<UpdateRoleAction> {
    override func request(for action: UpdateRoleAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
            let role = Role.existingObject(for: action.roleID, in: context),
            let participant = ZMUser.existingObject(for: action.userID, in: context),
            let roleName = role.name,
            let userId = participant.remoteIdentifier,
            let conversationId = conversation.remoteIdentifier,
            let payload = Payload.ConversationUpdateRole(role: roleName),
            let payloadData = payload.payloadData(encoder: .defaultEncoder),
            let payloadString = String(bytes: payloadData, encoding: .utf8)
        else {
            var action = action
            action.notifyResult(.failure(UpdateRoleError.unknown))
            return nil
        }

        let path = "/conversations/\(conversationId.transportString())/members/\(userId.transportString())"

        let request = ZMTransportRequest(path: path, method: .methodPUT, payload: payloadString as ZMTransportData, apiVersion: apiVersion.rawValue)
        return request
    }

    override func handleResponse(_ response: ZMTransportResponse, action: UpdateRoleAction) {
        var action = action

        switch response.httpStatus {
        case 200..<300:
            guard
                let conversation = ZMConversation.existingObject(for: action.conversationID, in: context),
                let role = Role.existingObject(for: action.roleID, in: context),
                let participant = ZMUser.existingObject(for: action.userID, in: context)
            else {
                action.notifyResult(.failure(UpdateRoleError.unknown))
                return
            }

            conversation.addParticipantAndUpdateConversationState(user: participant, role: role)
            conversation.managedObjectContext?.saveOrRollback()
            action.notifyResult(.success(()))
        default:
            action.notifyResult(.failure(UpdateRoleError.unknown))
        }
    }
}
