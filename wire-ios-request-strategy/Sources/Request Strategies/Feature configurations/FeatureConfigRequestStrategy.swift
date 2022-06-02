//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "feature configurations")

@objcMembers
public final class FeatureConfigRequestStrategy: AbstractRequestStrategy {

    // MARK: - Properties

    private let getFeatureConfigsActionHandler: GetFeatureConfigsActionHandler
    private let actionSync: EntityActionSync

    // MARK: - Life cycle

    public override init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        getFeatureConfigsActionHandler = GetFeatureConfigsActionHandler(context: managedObjectContext)
        actionSync = EntityActionSync(actionHandlers: [getFeatureConfigsActionHandler])

        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )

        configuration = [
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsWhileWaitingForWebsocket,
            .allowsRequestsWhileInBackground
        ]
    }

    // MARK: - Request

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return actionSync.nextRequest(for: apiVersion)
    }

}

// MARK: - Event processing

extension FeatureConfigRequestStrategy: ZMEventConsumer {

    public func processEvents(
        _ events: [ZMUpdateEvent],
        liveEvents: Bool,
        prefetchResult: ZMFetchRequestBatchResult?
    ) {
        events.forEach(processEvent)
    }

    private func processEvent(_ event: ZMUpdateEvent) {
        guard
            event.type == .featureConfigUpdate,
            let name = event.payload["name"] as? String,
            let featureName = Feature.Name(rawValue: name),
            let data = event.payload["data"]
        else {
            return
        }

        do {
            let payload = try JSONSerialization.data(withJSONObject: data, options: [])
            try processResponse(featureName: featureName, data: payload)
        } catch {
            zmLog.error("Failed to process feature config update event: \(error.localizedDescription)")
        }
    }

    private func processResponse(featureName: Feature.Name, data: Data) throws {
        let featureService = FeatureService(context: managedObjectContext)
        let decoder = JSONDecoder()

        switch featureName {
        case .conferenceCalling:
            let response = try decoder.decode(FeatureStatus.self, from: data)
            featureService.storeConferenceCalling(.init(status: response.status))

        case .fileSharing:
            let response = try decoder.decode(FeatureStatus.self, from: data)
            featureService.storeFileSharing(.init(status: response.status))

        case .appLock:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.AppLock.Config>.self, from: data)
            featureService.storeAppLock(.init(status: response.status, config: response.config))

        case .selfDeletingMessages:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.SelfDeletingMessages.Config>.self, from: data)
            featureService.storeSelfDeletingMessages(.init(status: response.status, config: response.config))

        case .conversationGuestLinks:
            let response = try decoder.decode(FeatureStatus.self, from: data)
            featureService.storeConversationGuestLinks(.init(status: response.status))

        case .classifiedDomains:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.ClassifiedDomains.Config>.self, from: data)
            featureService.storeClassifiedDomains(.init(status: response.status, config: response.config))

        case .digitalSignature:
            let response = try decoder.decode(FeatureStatus.self, from: data)
            featureService.storeDigitalSignature(.init(status: response.status))
        }
    }

}

struct FeatureStatus: Codable {

    let status: Feature.Status

}

struct FeatureStatusWithConfig<Config: Codable>: Codable {

    let status: Feature.Status
    let config: Config

}
