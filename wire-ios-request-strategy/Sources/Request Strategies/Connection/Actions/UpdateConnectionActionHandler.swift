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

class UpdateConnectionActionHandler: ActionHandler<UpdateConnectionAction> {

    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    override func request(for action: ActionHandler<UpdateConnectionAction>.Action, apiVersion: APIVersion) -> ZMTransportRequest? {
        switch apiVersion {
        case .v0:
            return nonFederatedRequest(for: action, apiVersion: apiVersion)
        case .v1:
            return federatedRequest(for: action, apiVersion: apiVersion)
        }
    }

    func nonFederatedRequest(for action: ActionHandler<UpdateConnectionAction>.Action, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            apiVersion == .v0,
            let connection = ZMConnection.existingObject(for: action.connectionID, in: context),
            let userID = connection.to.remoteIdentifier?.transportString(),
            let status = Payload.ConnectionStatus(action.newStatus)
        else {
            Logging.network.error("Can't create request to update connection status")
            return nil
        }

        let payload = Payload.ConnectionUpdate(status: status)

        guard
            let payloadData = payload.payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            Logging.network.error("Can't create payload to update connection status")
            return nil
        }

        return ZMTransportRequest(path: "/connections/\(userID)", method: .methodPUT, payload: payloadAsString as ZMTransportData, apiVersion: apiVersion.rawValue)
    }

    func federatedRequest(for action: ActionHandler<UpdateConnectionAction>.Action, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            apiVersion > .v0,
            let connection = ZMConnection.existingObject(for: action.connectionID, in: context),
            let qualifiedID = connection.to.qualifiedID,
            let status = Payload.ConnectionStatus(action.newStatus)
        else {
            Logging.network.error("Can't create request to update connection status")
            return nil
        }

        let payload = Payload.ConnectionUpdate(status: status)

        guard
            let payloadData = payload.payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            Logging.network.error("Can't create payload to update connection status")
            return nil
        }

        return ZMTransportRequest(path: "/connections/\(qualifiedID.domain)/\(qualifiedID.uuid.transportString())", method: .methodPUT, payload: payloadAsString as ZMTransportData, apiVersion: apiVersion.rawValue)
    }

    override func handleResponse(_ response: ZMTransportResponse, action: ActionHandler<UpdateConnectionAction>.Action) {

        var action = action

        guard response.result == .success else {

            guard let failure = Payload.ResponseFailure(response, decoder: decoder) else {
                action.notifyResult(.failure(.unknown))
                return
            }

            switch (failure.code, failure.label) {
            case (403, .noIdentity):
                action.notifyResult(.failure(.noIdentity))
            case (403, .missingLegalholdConsent):
                action.notifyResult(.failure(.missingLegalholdConsent))
            case (403, .notConnected):
                action.notifyResult(.failure(.notConnected))
            case (403, .connectionLimit):
                action.notifyResult(.failure(.connectionLimitReached))
            default:
                action.notifyResult(.failure(.unknown))
            }

            return
        }

        let connection = Payload.Connection(response, decoder: decoder)
        connection?.updateOrCreate(in: context)
        context.saveOrRollback()
        action.notifyResult(.success(Void()))
    }

}
