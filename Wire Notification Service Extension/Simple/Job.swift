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
import UserNotifications
import WireTransport
import WireSyncEngine
import WireCommonComponents
import WireRequestStrategy

@available(iOS 15, *)
final class Job: NSObject, Loggable {

    // MARK: - Types

    enum InitializationError: Error {

        case invalidEnvironment

    }

    typealias PushPayload = (userID: UUID, eventID: UUID)

    // MARK: - Properties

    private let request: UNNotificationRequest
    private let userID: UUID
    private let eventID: UUID

    private let environment: BackendEnvironmentProvider = BackendEnvironment.shared
    private let networkSession: NetworkSessionProtocol
    private let accessAPIClient: AccessAPIClientProtocol
    private let notificationsAPIClient: NotificationsAPIClientProtocol

    // MARK: - Life cycle

    init(
        request: UNNotificationRequest,
        networkSession: NetworkSessionProtocol? = nil,
        accessAPIClient: AccessAPIClientProtocol? = nil,
        notificationsAPIClient: NotificationsAPIClientProtocol? = nil
    ) throws {
        self.request = request
        let (userID, eventID) = try Self.pushPayload(from: request)
        self.userID = userID
        self.eventID = eventID

        let session = try networkSession ?? NetworkSession(userID: userID)
        self.networkSession = session
        self.accessAPIClient = accessAPIClient ??  AccessAPIClient(networkSession: session)
        self.notificationsAPIClient = notificationsAPIClient ??  NotificationsAPIClient(networkSession: session)
        super.init()
    }

    // MARK: - Methods

    func execute() async throws -> UNNotificationContent {
        logger.trace("\(self.request.identifier, privacy: .public): executing job...")
        logger.info("\(self.request.identifier, privacy: .public): request is for user (\(self.userID, privacy: .public)) and event (\(self.eventID, privacy: .public)")

        guard isUserAuthenticated else {
            throw NotificationServiceError.userNotAuthenticated
        }

        networkSession.accessToken = try await fetchAccessToken()

        let event = try await fetchEvent(eventID: eventID)

        switch event.type {
        case .conversationOtrMessageAdd:

            guard let accountID = request.content.accountID else { throw NotificationServiceError.noAccount }
            let messageContent = try await decryptAndStoreEvent(event: event, accountIdentifier: accountID)
            logger.trace("\(self.request.identifier, privacy: .public): returning notification for new message")
            let content = UNMutableNotificationContent()
            content.body = messageContent
            return content

        default:
            logger.trace("\(self.request.identifier, privacy: .public): ignoring event of type: \(String(describing: event.type), privacy: .public)")
            return .empty
        }
    }

    private func decryptAndStoreEvent(event: ZMUpdateEvent, accountIdentifier: UUID) async throws -> String {
           guard let groupID = Bundle.main.applicationGroupIdentifier else {
               throw NotificationServiceError.noAppGroupID
           }

           let sharedContainerURL = FileManager.sharedContainerDirectory(for: groupID)
           let accountManager = AccountManager(sharedDirectory: sharedContainerURL)
           guard let account = accountManager.account(with: accountIdentifier) else {
               throw NotificationServiceError.noAccount
           }
           let coreDataStack = CoreDataStack(
               account: account,
               applicationContainer: sharedContainerURL
           )

        try await coreDataStack.loadStores()
        let eventDecoder = EventDecoder(eventMOC: coreDataStack.eventContext, syncMOC: coreDataStack.syncContext)
//            logger.trace("decode")
        let updatedEvents = await eventDecoder.decryptAndStoreEvents(events: [event])
        guard let updatedEvent = updatedEvents.first else { throw NotificationServiceError.decryptionError }
        guard let message = GenericMessage(from: updatedEvent) else { throw NotificationServiceError.decryptionError }
        guard let text = message.textData else { throw NotificationServiceError.incorrectContent }
        return text.content

    }

    private class func pushPayload(from request: UNNotificationRequest) throws -> PushPayload {
        guard
            let notificationData = request.content.userInfo["data"] as? [String: Any],
            let userIDString = notificationData["user"] as? String,
            let userID = UUID(uuidString: userIDString),
            let data = notificationData["data"] as? [String: Any],
            let eventIDString = data["id"] as? String,
            let eventID = UUID(uuidString: eventIDString)
        else {
            throw NotificationServiceError.malformedPushPayload
        }

        return (userID, eventID)
    }

    private var isUserAuthenticated: Bool {
        return networkSession.isAuthenticated
    }

    private func fetchAccessToken() async throws -> AccessToken {
        logger.trace("\(self.request.identifier, privacy: .public): fetching access token")
        return try await accessAPIClient.fetchAccessToken()
    }

    private func fetchEvent(eventID: UUID) async throws -> ZMUpdateEvent {
        logger.trace("\(self.request.identifier, privacy: .public): fetching event (\(eventID, privacy: .public))")
        return try await notificationsAPIClient.fetchEvent(eventID: eventID)
    }

}

extension CoreDataStack {

    func loadStores() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            loadStores {
                if let error = $0 {
                    continuation.resume(with: .failure(error))
                } else {
                    continuation.resume(with: .success(()))
                }
            }
        }
    }

}

extension EventDecoder {

    func decryptAndStoreEvents(events: [ZMUpdateEvent]) async -> [ZMUpdateEvent] {
        return await withCheckedContinuation { continuation in
            decryptAndStoreEvents(events) { decryptedEvents in
                continuation.resume(with: .success(decryptedEvents))
            }
        }
    }
}
