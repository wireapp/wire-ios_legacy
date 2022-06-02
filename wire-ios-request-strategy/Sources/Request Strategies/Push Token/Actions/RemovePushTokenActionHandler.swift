//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

class RemovePushTokenActionHandler: ActionHandler<RemovePushTokenAction> {

    // MARK: - Methods

    override func request(
        for action: ActionHandler<RemovePushTokenAction>.Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {

        return ZMTransportRequest(
            path: "/push/tokens/\(action.deviceToken)",
            method: .methodDELETE,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )

    }

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: ActionHandler<RemovePushTokenAction>.Action
    ) {
        var action = action

        switch response.httpStatus {
        case 201:
            action.notifyResult(.success(()))

            // Push token unregistered
        case 204:
            action.notifyResult(.success(()))

        case 404:
            action.notifyResult(.failure(.tokenDoesNotExist))

        default:
            action.notifyResult(.failure(.unknown(status: response.httpStatus)))
        }
    }

}
