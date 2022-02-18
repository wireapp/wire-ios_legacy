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
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    var notificationSessions: [UUID: NotificationSession] = [:]

//    public override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
//        var currentNotificationSession: NotificationSession?
//        // TODO: Check if we have accountID in request.content.userInfo
//        guard let accountIdentifier = accountManager?.selectedAccount?.userIdentifier else {
//            return
//        }
//
//        if let session = notificationSessions[accountIdentifier] {
//            currentNotificationSession = session
//        } else {
//            let notificationSession = try? self.createNotificationSession(request.content as? UNMutableNotificationContent)
//            notificationSessions[accountIdentifier] = notificationSession
//            currentNotificationSession = notificationSession
//        }
//
//        currentNotificationSession?.processPushNotification(with: request.content.userInfo) { isAuthenticatedUser in
//            if !isAuthenticatedUser {
//                let emptyContent = UNNotificationContent()
//                contentHandler(emptyContent)
    //            }
    //        }
    //        self.contentHandler = contentHandler
    //        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
    //    }

    public override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            bestAttemptContent.title = "Sent from NE [modified]"

            contentHandler(bestAttemptContent)
        }
    }

    private var accountManager: AccountManager? {
           guard let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier else { return nil }
           let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
           let account = AccountManager(sharedDirectory: sharedContainerURL)
           return account
       }

    //TODO: discuss with product/design what should we display
    public override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        let emptyContent = UNNotificationContent()
        contentHandler?(emptyContent)
    }

    private func createNotificationSession(_ payload: UNMutableNotificationContent?) throws -> NotificationSession? {
        guard let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier,
              // TODO: Check if we have accountID in payload?.userInfo
            let accountIdentifier = accountManager?.selectedAccount?.userIdentifier
            else { return nil}
        return  try NotificationSession(applicationGroupIdentifier: applicationGroupIdentifier,
                                        accountIdentifier: accountIdentifier,
                                        environment: BackendEnvironment.shared,
                                        analytics: nil,
                                        delegate: self,
                                        useLegacyPushNotifications: false)
    }
}

extension NotificationService: NotificationSessionDelegate {
    public func modifyNotification(_ alert: ClientNotification, messageCount: Int) {
        if let bestAttemptContent = bestAttemptContent {
            switch messageCount {
            case 0:
               // let emptyContent = UNNotificationContent()
//                contentHandler?(emptyContent)
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
