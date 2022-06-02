//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@objc
public protocol StrategyDirectoryProtocol {

    var eventConsumers: [ZMEventConsumer] { get }
    var requestStrategies: [RequestStrategy] { get }
    var contextChangeTrackers: [ZMContextChangeTracker] {get }

}

@objcMembers
public class StrategyDirectory: NSObject, StrategyDirectoryProtocol {

    let strategies: [Any]

    public let requestStrategies: [RequestStrategy]
    public let eventConsumers: [ZMEventConsumer]
    public let contextChangeTrackers: [ZMContextChangeTracker]

    init(contextProvider: ContextProvider,
         applicationStatusDirectory: ApplicationStatusDirectory,
         cookieStorage: ZMPersistentCookieStorage,
         pushMessageHandler: PushMessageHandler,
         flowManager: FlowManagerType,
         updateEventProcessor: UpdateEventProcessor,
         localNotificationDispatcher: LocalNotificationDispatcher,
         useLegacyPushNotifications: Bool) {

        self.strategies = Self.buildStrategies(contextProvider: contextProvider,
                                               applicationStatusDirectory: applicationStatusDirectory,
                                               cookieStorage: cookieStorage,
                                               pushMessageHandler: pushMessageHandler,
                                               flowManager: flowManager,
                                               updateEventProcessor: updateEventProcessor,
                                               localNotificationDispatcher: localNotificationDispatcher,
                                               useLegacyPushNotifications: useLegacyPushNotifications)

        self.requestStrategies = strategies.compactMap({ $0 as? RequestStrategy})
        self.eventConsumers = strategies.compactMap({ $0 as? ZMEventConsumer })
        self.contextChangeTrackers = strategies.flatMap({ (object: Any) -> [ZMContextChangeTracker] in
            if let source = object as? ZMContextChangeTrackerSource {
                return source.contextChangeTrackers
            } else if let tracker = object as? ZMContextChangeTracker {
                return [tracker]
            } else {
                return []
            }
        })
    }

    deinit {
        strategies.forEach { strategy in
            if let strategy = strategy as? TearDownCapable {
                strategy.tearDown()
            }
        }
    }

    static func buildStrategies(contextProvider: ContextProvider,
                                applicationStatusDirectory: ApplicationStatusDirectory,
                                cookieStorage: ZMPersistentCookieStorage,
                                pushMessageHandler: PushMessageHandler,
                                flowManager: FlowManagerType,
                                updateEventProcessor: UpdateEventProcessor,
                                localNotificationDispatcher: LocalNotificationDispatcher,
                                useLegacyPushNotifications: Bool) -> [Any] {

        let syncMOC = contextProvider.syncContext
        let strategies: [Any] = [
            UserClientRequestStrategy(
                clientRegistrationStatus: applicationStatusDirectory.clientRegistrationStatus,
                clientUpdateStatus: applicationStatusDirectory.clientUpdateStatus,
                context: syncMOC,
                userKeysStore: syncMOC.zm_cryptKeyStore),
            MissingClientsRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            ZMMissingUpdateEventsTranscoder(
                managedObjectContext: syncMOC,
                notificationsTracker: nil,
                eventProcessor: updateEventProcessor,
                previouslyReceivedEventIDsCollection: nil,
                applicationStatus: applicationStatusDirectory,
                pushNotificationStatus: applicationStatusDirectory.pushNotificationStatus,
                syncStatus: applicationStatusDirectory.syncStatus,
                operationStatus: applicationStatusDirectory.operationStatus,
                useLegacyPushNotifications: useLegacyPushNotifications),
            FetchingClientRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            VerifyLegalHoldRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            ProxiedRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                requestsStatus: applicationStatusDirectory.proxiedRequestStatus),
            DeleteAccountRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                cookieStorage: cookieStorage),
            AssetV3UploadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            AssetV2DownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            AssetV3DownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            AssetClientMessageRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            AssetV3PreviewDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            ClientMessageRequestStrategy(
                withManagedObjectContext: syncMOC,
                localNotificationDispatcher: pushMessageHandler,
                applicationStatus: applicationStatusDirectory),
            DeliveryReceiptRequestStrategy(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                clientRegistrationDelegate: applicationStatusDirectory.clientRegistrationDelegate),
            AvailabilityRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            UserPropertyRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            UserProfileUpdateRequestStrategy(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                userProfileUpdateStatus: applicationStatusDirectory.userProfileUpdateStatus),
            LinkPreviewAssetUploadRequestStrategy(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                linkPreviewPreprocessor: nil,
                previewImagePreprocessor: nil),
            LinkPreviewAssetDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            LinkPreviewUpdateRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            ImageV2DownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            PushTokenStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            TypingStrategy(
                applicationStatus: applicationStatusDirectory,
                managedObjectContext: syncMOC),
            SearchUserImageStrategy(
                applicationStatus: applicationStatusDirectory,
                managedObjectContext: syncMOC),
            ConnectionRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncProgress: applicationStatusDirectory.syncStatus),
            ConversationRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncProgress: applicationStatusDirectory.syncStatus),
            UserProfileRequestStrategy(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncProgress: applicationStatusDirectory.syncStatus),
            ZMLastUpdateEventIDTranscoder(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus),
            ZMSelfStrategy(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                clientRegistrationStatus: applicationStatusDirectory.clientRegistrationStatus,
                syncStatus: applicationStatusDirectory.syncStatus),
            CallingRequestStrategy(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                clientRegistrationDelegate: applicationStatusDirectory.clientRegistrationStatus,
                flowManager: flowManager,
                callEventStatus: applicationStatusDirectory.callEventStatus),
            LegalHoldRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus),
            TeamDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus),
            TeamRolesDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus),
            TeamMembersDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus),
            PermissionsDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            TeamInvitationRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                teamInvitationStatus: applicationStatusDirectory.teamInvitationStatus),
            AssetDeletionRequestStrategy(
                context: syncMOC,
                applicationStatus: applicationStatusDirectory,
                identifierProvider: applicationStatusDirectory.assetDeletionStatus),
            UserRichProfileRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            TeamImageAssetUpdateStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            LabelDownstreamRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus),
            LabelUpstreamRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            ConversationRoleDownstreamRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            SignatureRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            FeatureConfigRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory),
            ConversationStatusStrategy(
                managedObjectContext: syncMOC),
            UserClientEventConsumer(
                managedObjectContext: syncMOC,
                clientRegistrationStatus: applicationStatusDirectory.clientRegistrationStatus,
                clientUpdateStatus: applicationStatusDirectory.clientUpdateStatus),
            ResetSessionRequestStrategy(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                clientRegistrationDelegate: applicationStatusDirectory.clientRegistrationDelegate),
            UserImageAssetUpdateStrategy(
                managedObjectContext: syncMOC,
                applicationStatusDirectory: applicationStatusDirectory,
                userProfileImageUpdateStatus: applicationStatusDirectory.userProfileImageUpdateStatus),
            localNotificationDispatcher
        ]

        return strategies
    }

}
