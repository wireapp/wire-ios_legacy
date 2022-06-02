////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireTransport

extension MockTransportSession {
    @objc(processPushTokenRequest:)
    public func processPushTokenRequest(_ request: ZMTransportRequest) -> ZMTransportResponse {
        guard let apiVersion = APIVersion(rawValue: request.apiVersion) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: request.apiVersion)
        }

        switch (request, request.method) {
        case ("/push/tokens", .methodGET):
            return processGetPushTokens(apiVersion: apiVersion)
        case ("/push/tokens", .methodPOST):
            return processPostPushToken(request.payload, apiVersion: apiVersion)
        case ("/push/tokens/*", .methodDELETE):
            return processDeletePushToken(request.RESTComponents(index: 2), apiVersion: apiVersion)
        default:
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: request.apiVersion)
        }
    }

    func processGetPushTokens(apiVersion: APIVersion) -> ZMTransportResponse {
        let payload = [
            "tokens" : Array(pushTokens.values)
        ] as NSDictionary
        return ZMTransportResponse(payload: payload, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }

    func processDeletePushToken(_ token: String?, apiVersion: APIVersion) -> ZMTransportResponse {
        if let token = token {
            if pushTokens[token] != nil {
                removePushToken(token)
                return ZMTransportResponse(payload: nil, httpStatus: 204, transportSessionError: nil, apiVersion: apiVersion.rawValue)
            } else {
                return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: apiVersion.rawValue)
            }
        }
        return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }

    func processPostPushToken(_ payload: ZMTransportData?, apiVersion: APIVersion) -> ZMTransportResponse {
        let transportType = useLegaclyPushNotifications ? "APNS_VOIP" : "APNS"

        guard
            let payload = payload?.asDictionary() as? [String: String],
            let token = payload["token"],
            let _ = payload["app"],
            let transport = payload["transport"], transport == transportType
        else {
            return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        }

        addPushToken(token, payload: payload)
        return ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 201, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }
}
