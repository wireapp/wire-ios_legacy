//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import CoreData
import WireRequestStrategy

@objcMembers
public final class ApplicationStatusDirectory: NSObject, ApplicationStatus {

    public let userProfileImageUpdateStatus: UserProfileImageUpdateStatus
    public let userProfileUpdateStatus: UserProfileUpdateStatus
    public let clientRegistrationStatus: ZMClientRegistrationStatus
    public let clientUpdateStatus: ClientUpdateStatus
    public let pushNotificationStatus: PushNotificationStatus
    public let proxiedRequestStatus: ProxiedRequestsStatus
    public let syncStatus: SyncStatus
    public let operationStatus: OperationStatus
    public let requestCancellation: ZMRequestCancellation
    public let analytics: AnalyticsType?
    public let teamInvitationStatus: TeamInvitationStatus
    public let assetDeletionStatus: AssetDeletionStatus
    public let callEventStatus: CallEventStatus

    fileprivate var callInProgressObserverToken: Any?

    public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, cookieStorage: ZMPersistentCookieStorage, requestCancellation: ZMRequestCancellation, application: ZMApplication, syncStateDelegate: ZMSyncStateDelegate, analytics: AnalyticsType? = nil) {
        self.requestCancellation = requestCancellation
        self.operationStatus = OperationStatus()
        self.callEventStatus = CallEventStatus()
        self.analytics = analytics
        self.teamInvitationStatus = TeamInvitationStatus()
        self.operationStatus.isInBackground = application.applicationState == .background
        self.syncStatus = SyncStatus(managedObjectContext: managedObjectContext, syncStateDelegate: syncStateDelegate)
        self.userProfileUpdateStatus = UserProfileUpdateStatus(managedObjectContext: managedObjectContext)
        self.clientUpdateStatus = ClientUpdateStatus(syncManagedObjectContext: managedObjectContext)
        self.clientRegistrationStatus = ZMClientRegistrationStatus(managedObjectContext: managedObjectContext,
                                                                   cookieStorage: cookieStorage,
                                                                   registrationStatusDelegate: syncStateDelegate)
        self.pushNotificationStatus = PushNotificationStatus(managedObjectContext: managedObjectContext)
        self.proxiedRequestStatus = ProxiedRequestsStatus(requestCancellation: requestCancellation)
        self.userProfileImageUpdateStatus = UserProfileImageUpdateStatus(managedObjectContext: managedObjectContext)
        self.assetDeletionStatus = AssetDeletionStatus(provider: managedObjectContext, queue: managedObjectContext)
        super.init()

        callInProgressObserverToken = NotificationInContext.addObserver(name: CallStateObserver.CallInProgressNotification, context: managedObjectContext.notificationContext) { [weak self] (note) in
            managedObjectContext.performGroupedBlock {
                if let callInProgress = note.userInfo[CallStateObserver.CallInProgressKey] as? Bool {
                    self?.operationStatus.hasOngoingCall = callInProgress
                }
            }
        }
    }

    deinit {
        clientRegistrationStatus.tearDown()
    }

    public var clientRegistrationDelegate: ClientRegistrationDelegate {
        return clientRegistrationStatus
    }

    public var operationState: OperationState {
        switch operationStatus.operationState {
        case .foreground:
            return .foreground
        case .background, .backgroundCall, .backgroundFetch, .backgroundTask:
            return .background
        }
    }

    public var synchronizationState: SynchronizationState {
        if !clientRegistrationStatus.clientIsReadyForRequests() {
            return .unauthenticated
        } else if syncStatus.isSlowSyncing {
            return .slowSyncing
        } else if syncStatus.isFetchingNotificationStream {
            return .quickSyncing
        } else if syncStatus.isSyncing {
            return .establishingWebsocket
        } else {
            return .online
        }
    }

    public func requestSlowSync() {
        syncStatus.forceSlowSync()
    }

}
