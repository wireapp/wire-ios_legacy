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

class GetPushTokensActionHandler: ActionHandler<GetPushTokensAction> {

    // MARK: - Methods

    override func request(
        for action: ActionHandler<GetPushTokensAction>.Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {

        return ZMTransportRequest(
            path: "/push/tokens",
            method: .methodGET,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: ActionHandler<GetPushTokensAction>.Action
    ) {
        var action = action

        switch response.httpStatus {
        case 200:
            guard
                let data = response.rawData,
                let payload = try? JSONDecoder().decode(ResponsePayload.self, from: data)
            else {
                action.notifyResult(.failure(.malformedResponse))
                return
            }

            let tokens = payload.tokens
                .filter {
                    $0.client == action.clientID && ($0.isStandardAPNSToken || $0.isVoIPToken)
                }
                .map { token in
                    PushToken(
                        deviceToken: token.token.zmHexDecodedData()!,
                        appIdentifier: token.app,
                        transportType: token.transport,
                        tokenType: token.isStandardAPNSToken ? .standard : .voip
                    )
            }

            action.notifyResult(.success(tokens))

        default:
            action.notifyResult(.failure(.unknown(status: response.httpStatus)))
        }
    }

}

extension GetPushTokensActionHandler {

    struct ResponsePayload: Codable {

        let tokens: [Token]

    }

    struct Token: Codable {

        let app: String
        let client: String?
        let token: String
        let transport: String

        var isStandardAPNSToken: Bool {
            return transport.isOne(of: ["APNS", "APNS_SANDBOX"])
        }

        var isVoIPToken: Bool {
            return transport.isOne(of: ["APNS_VOIP", "APNS_VOIP_SANDBOX"])
        }

    }

}
