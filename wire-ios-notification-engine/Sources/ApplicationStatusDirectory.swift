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
import WireRequestStrategy

class ApplicationStatusDirectory: ApplicationStatus {

    // MARK: - Properties

    let transportSession: ZMTransportSession

    /// The authentication status used to verify a user is authenticated.

    public let authenticationStatus: AuthenticationStatusProvider

    /// The client registration status used to lookup if a user has registered a self client.

    public let clientRegistrationStatus: ClientRegistrationDelegate

    public let linkPreviewDetector: LinkPreviewDetectorType

    public var pushNotificationStatus: PushNotificationStatus

    // MARK: - Life cycle

    public convenience init(
        syncContext: NSManagedObjectContext,
        transportSession: ZMTransportSession
    ) {
        let authenticationStatus = AuthenticationStatus(transportSession: transportSession)
        let clientRegistrationStatus = ClientRegistrationStatus(context: syncContext)
        let linkPreviewDetector = LinkPreviewDetector()

        self.init(
            managedObjectContext: syncContext,
            transportSession: transportSession,
            authenticationStatus: authenticationStatus,
            clientRegistrationStatus: clientRegistrationStatus,
            linkPreviewDetector: linkPreviewDetector
        )
    }

    public init(
        managedObjectContext: NSManagedObjectContext,
        transportSession: ZMTransportSession,
        authenticationStatus: AuthenticationStatusProvider,
        clientRegistrationStatus: ClientRegistrationStatus,
        linkPreviewDetector: LinkPreviewDetectorType
    ) {
        self.transportSession = transportSession
        self.authenticationStatus = authenticationStatus
        self.clientRegistrationStatus = clientRegistrationStatus
        self.linkPreviewDetector = linkPreviewDetector
        self.pushNotificationStatus = PushNotificationStatus(managedObjectContext: managedObjectContext)
    }

    // MARK: - Methods

    public var synchronizationState: SynchronizationState {
        if clientRegistrationStatus.clientIsReadyForRequests {
            return .online
        } else {
            return .unauthenticated
        }
    }

    public var operationState: OperationState {
        return .background
    }

    public var clientRegistrationDelegate: ClientRegistrationDelegate {
        return self.clientRegistrationStatus
    }

    public var requestCancellation: ZMRequestCancellation {
        return transportSession
    }

    func requestSlowSync() {
        // We don't do slow syncing in the notification engine.
    }

}
