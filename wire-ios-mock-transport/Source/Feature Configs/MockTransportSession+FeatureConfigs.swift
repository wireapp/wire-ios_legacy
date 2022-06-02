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

extension MockTransportSession {

    @objc(processGetFeatureConfigsRequest:)
    public func processGetFeatureConfigsRequest(_ request: ZMTransportRequest) -> ZMTransportResponse {
        let payload: [String: Any] = [
            "appLock": [
                "status": "enabled",
                "config": [
                    "enforceAppLock": false,
                    "inactivityTimeoutSecs": 60
                ]
            ],
            "classifiedDomains": [
                "status": "disabled",
                "config": [
                    "domains": []
                ]
            ],
            "conferenceCalling": [
                "status": "enabled"
            ],
            "conversationGuestLinks": [
                "status": "enabled"
            ],
            "digitalSignatures": [
                "status": "disabled"
            ],
            "fileSharing": [
                "status": "enabled"
            ],
            "selfDeletingMessages": [
                "status": "enabled",
                "config": [
                    "enforcedTimeoutSeconds": 0
                ]
            ]
        ]

        return ZMTransportResponse(
            payload: payload as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: request.apiVersion
        )
    }

}
