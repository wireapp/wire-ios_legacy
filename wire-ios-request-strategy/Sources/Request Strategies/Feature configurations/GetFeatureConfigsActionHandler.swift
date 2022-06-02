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

final class GetFeatureConfigsActionHandler: ActionHandler<GetFeatureConfigsAction> {

    // MARK: - Request

    override func request(
        for action: GetFeatureConfigsActionHandler.Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        return ZMTransportRequest(getFromPath: "/feature-configs", apiVersion: apiVersion.rawValue)
    }

    // MARK: - Response

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: GetFeatureConfigsActionHandler.Action
    ) {
        var action = action

        switch (response.httpStatus, response.payloadLabel()) {
        case (200, _):
            guard
                let data = response.rawData,
                !data.isEmpty
            else {
                action.fail(with: .malformedResponse)
                return
            }

            do {
                let payload = try JSONDecoder().decode(ResponsePayload.self, from: data)
                processPayload(payload)
                action.succeed()
            } catch {
                action.fail(with: .failedToDecodeResponse(reason: error.localizedDescription))
            }

        case (403, "operation-denied"):
            action.fail(with: .insufficientPermissions)

        case (403, "no-team-member"):
            action.fail(with: .userIsNotTeamMember)

        case (404, "no-team"):
            action.fail(with: .teamNotFound)

        case let (status, label):
            action.fail(with: .unknown(status: status, label: label ?? ""))
        }
    }

    private func processPayload(_ payload: ResponsePayload) {
        let service = FeatureService(context: context)

        service.storeAppLock(
            Feature.AppLock(
                status: payload.appLock.status,
                config: payload.appLock.config
            )
        )

        service.storeClassifiedDomains(
            Feature.ClassifiedDomains(
                status: payload.classifiedDomains.status,
                config: payload.classifiedDomains.config
            )
        )

        service.storeConferenceCalling(
            Feature.ConferenceCalling(
                status: payload.conferenceCalling.status
            )
        )

        service.storeConversationGuestLinks(
            Feature.ConversationGuestLinks(
                status: payload.conversationGuestLinks.status
            )
        )

        service.storeDigitalSignature(
            Feature.DigitalSignature(
                status: payload.digitalSignatures.status
            )
        )

        service.storeFileSharing(
            Feature.FileSharing(
                status: payload.fileSharing.status
            )
        )

        service.storeSelfDeletingMessages(
            Feature.SelfDeletingMessages(
                status: payload.selfDeletingMessages.status,
                config: payload.selfDeletingMessages.config
            )
        )
    }

}

// MARK: - Response Payload

extension GetFeatureConfigsActionHandler {

    struct ResponsePayload: Codable {

        let appLock: FeatureStatusWithConfig<Feature.AppLock.Config>
        let classifiedDomains: FeatureStatusWithConfig<Feature.ClassifiedDomains.Config>
        let conferenceCalling: FeatureStatus
        let conversationGuestLinks: FeatureStatus
        let digitalSignatures: FeatureStatus
        let fileSharing: FeatureStatus
        let selfDeletingMessages: FeatureStatusWithConfig<Feature.SelfDeletingMessages.Config>
    }

}
