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
        notificationSession = try! self.createNotificationSession()
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

//        if let bestAttemptContent = bestAttemptContent {
//            // Modify the notification content here...
//            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
//            contentHandler(bestAttemptContent)
//        }
    }
    
    public override func serviceExtensionTimeWillExpire() {

        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    public func createNotificationSession() throws -> NotificationSession? {
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

extension NotificationService: UpdateEventsDelegate {
    public func didReceive(events: [ZMUpdateEvent], in moc: NSManagedObjectContext) {
        if let bestAttemptContent = bestAttemptContent {
            let localNotifications = processEvents(events, liveEvents: true, prefetchResult: nil, moc: moc).compactMap { $0 }
            var bodyText = ""
            var titleText = ""
            switch localNotifications.count {
            case 0:
                let emptyContent = UNNotificationContent()
                contentHandler!(emptyContent)
            case 1:
                if let notification = localNotifications.first {
                    print(notification)
                    bodyText = notification.body
                    titleText = notification.title ?? ""
                }
            default:
                bodyText = "\(localNotifications.count) Notifications"
            }
            bestAttemptContent.body = bodyText
            bestAttemptContent.title = titleText
            
            
            //            if localNotifications.count > 1 {
            //                bestAttemptContent.body = "\(localNotifications.count) Notifications"
            //            } else {
            //                if let notification = localNotifications.first {
            //                    print(notification)
            //                }
            //            }
            contentHandler!(bestAttemptContent)
        }
    }
}



extension NotificationService {

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?, moc: NSManagedObjectContext) -> [ZMLocalNotification?] {
        let eventsToForward = events.filter { $0.source.isOne(of: .pushNotification, .webSocket) }
        return self.didConvert(events: eventsToForward, conversationMap: prefetchResult?.conversationsByRemoteIdentifier ?? [:], moc: moc)
    }

    private func didConvert(events: [ZMUpdateEvent], conversationMap: [UUID: ZMConversation], moc: NSManagedObjectContext) -> [ZMLocalNotification?] {
        var localNotifications: [ZMLocalNotification?] = []
        events.forEach { event in
            var conversation: ZMConversation?
            if let conversationID = event.conversationUUID() {
                // Fetch the conversation here to avoid refetching every time we try to create a notification
                conversation = conversationMap[conversationID] ?? ZMConversation.fetch(withRemoteIdentifier: conversationID, in: moc)
            }
            
            let note = ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: moc)
            localNotifications.append(note)
        }
        return localNotifications
    }
}
