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

import UserNotifications
import WireNotificationEngine
import WireCommonComponents
import WireDataModel
import WireRequestStrategy
import WireSyncEngine

public class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    var notificationSession: NotificationSession?

    public override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        if notificationSession == nil {
            notificationSession = try? self.createNotificationSession()
        }
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
    }
    
    public override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func createNotificationSession() throws -> NotificationSession? {
        guard let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier,
            let accountIdentifier = accountManager?.selectedAccount?.userIdentifier
            else { return nil}
        return  try NotificationSession(applicationGroupIdentifier: applicationGroupIdentifier,
                                        accountIdentifier: accountIdentifier,
                                        environment: BackendEnvironment.shared,
                                        analytics: nil,
                                        delegate: self)
    }
    
    private var accountManager: AccountManager? {
        guard let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier else { return nil }
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        let account = AccountManager(sharedDirectory: sharedContainerURL)
        return account
    }
}

extension NotificationService: LocalNotificationsDelegate {
    public func shouldCreateNotificationWith(_ alert: (title: String, body: String), showNotification: Bool) {
        if showNotification {
            if let bestAttemptContent = bestAttemptContent {
                bestAttemptContent.title = alert.title
                bestAttemptContent.body = alert.body
                
                contentHandler!(bestAttemptContent)
            }
        } else {
            let emptyContent = UNNotificationContent()
            contentHandler!(emptyContent)
        }
    }
}
