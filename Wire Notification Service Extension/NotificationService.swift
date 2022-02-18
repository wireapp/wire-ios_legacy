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
import WireNotificationEngine
import WireCommonComponents
import WireDataModel
import WireRequestStrategy
import WireSyncEngine

public class NotificationService: UNNotificationServiceExtension {

    // MARK: - Properties

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private var notificationSessions = [UUID: NotificationSession]()

    // MARK: - Methods

    public override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        var currentNotificationSession: NotificationSession?

        // TODO: Check if we have accountID in request.content.userInfo
        guard let accountIdentifier = accountManager?.selectedAccount?.userIdentifier else {
            return
        }

        if let session = notificationSessions[accountIdentifier] {
            currentNotificationSession = session
        } else {
            // TODO: handle failure
            let notificationSession = try? self.createNotificationSession(accountIdentifier: accountIdentifier)
            notificationSessions[accountIdentifier] = notificationSession
            currentNotificationSession = notificationSession
        }

        currentNotificationSession?.processPushNotification(with: request.content.userInfo) { isUserAuthenticated in
            if !isUserAuthenticated {
                let emptyContent = UNNotificationContent()
                contentHandler(emptyContent)
            }
        }

        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
    }

    public override func serviceExtensionTimeWillExpire() {
        // TODO: discuss with product/design what should we display
        let emptyContent = UNNotificationContent()
        contentHandler?(emptyContent)
    }

    // MARK: - Helpers

    private var appGroupId: String? {
        return Bundle.main.appGroupIdentifier
    }

    private var accountManager: AccountManager? {
        guard let applicationGroupIdentifier = appGroupId else { return nil }
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        let account = AccountManager(sharedDirectory: sharedContainerURL)
        return account
    }

    private func createNotificationSession(accountIdentifier: UUID) throws -> NotificationSession? {
        guard let applicationGroupIdentifier = appGroupId else { return nil }

        return try NotificationSession(
            applicationGroupIdentifier: applicationGroupIdentifier,
            accountIdentifier: accountIdentifier,
            environment: BackendEnvironment.shared,
            analytics: nil,
            delegate: self,
            useLegacyPushNotifications: false
        )
    }
}

// MARK: - Notification Session Delegate

extension NotificationService: NotificationSessionDelegate {
    public func modifyNotification(_ alert: ClientNotification, messageCount: Int) {
        if let bestAttemptContent = bestAttemptContent {
            switch messageCount {
            case 0:
                bestAttemptContent.title = "alert.title"
                bestAttemptContent.body = "alert.body"
                contentHandler?(bestAttemptContent)
            case 1:
                bestAttemptContent.title = alert.title
                bestAttemptContent.body = alert.body
                contentHandler?(bestAttemptContent)
            default:
                bestAttemptContent.title = alert.title
                bestAttemptContent.body = String(format: "push.notifications.bundled_message.title".localized, messageCount)
                contentHandler?(bestAttemptContent)
            }
        }
    }
}
