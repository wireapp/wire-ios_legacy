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

    public override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
//        let test = try! self.createSharingSession()
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
            contentHandler(bestAttemptContent)
        }
    }
    
    public override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

//    public func createSharingSession() throws -> SharingSession? {
////        guard let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier,
//////        let hostBundleIdentifier = Bundle.main.hostBundleIdentifier,
////            let accountIdentifier = accountManager?.selectedAccount?.userIdentifier
////        else { return nil}
//        print(Bundle.main.applicationGroupIdentifier)
//        print(accountManager?.selectedAccount?.userIdentifier)
//        let applicationGroupIdentifier = "group.com.wearezeta.zclient-alpha"
//        let accountIdentifier = UUID(uuidString: "58A2C906-9AF7-405C-9A3C-49B32650150B")!
//        return  try SharingSession(applicationGroupIdentifier: applicationGroupIdentifier,
//                              accountIdentifier: accountIdentifier,
//                              environment: BackendEnvironment.shared,
//                              analytics: nil,
//                              eventProcessor: self)
//    }
//
    private var accountManager: AccountManager? {
        guard let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier else { return nil }
//        let applicationGroupIdentifier = "com.wearezeta.zclient-alpha"
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        let account = AccountManager(sharedDirectory: sharedContainerURL)
        return account
    }
}

extension NotificationService: UpdateEventProcessor {
    public func process(updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
//        if ignoreBuffer || isReadyToProcessEvents {
//            consume(updateEvents: updateEvents)
//        } else {
//            Logging.eventProcessing.info("Buffering \(updateEvents.count) event(s)")
//            updateEvents.forEach(eventsBuffer.addUpdateEvent)
//        }
    }
    
//    public func consume(updateEvents: [ZMUpdateEvent]) {
//        eventDecoder.processEvents(updateEvents) { [weak self] (decryptedUpdateEvents) in
//            guard let `self` = self else { return }
//
//            let date = Date()
//            let fetchRequest = prefetchRequest(updateEvents: decryptedUpdateEvents)
//            let prefetchResult = syncMOC.executeFetchRequestBatchOrAssert(fetchRequest)
//
//            Logging.eventProcessing.info("Consuming: [\n\(decryptedUpdateEvents.map({ "\tevent: \(ZMUpdateEvent.eventTypeString(for: $0.type) ?? "Unknown")" }).joined(separator: "\n"))\n]")
//
//            for event in decryptedUpdateEvents {
//                for eventConsumer in self.eventConsumers {
//                    eventConsumer.processEvents([event], liveEvents: true, prefetchResult: prefetchResult)
//                }
//                self.eventProcessingTracker?.registerEventProcessed()
//            }
//            localNotificationDispatcher?.processEvents(decryptedUpdateEvents, liveEvents: true, prefetchResult: nil)
//
//            if let messages = fetchRequest.noncesToFetch as? Set<UUID>,
//                let conversations = fetchRequest.remoteIdentifiersToFetch as? Set<UUID> {
//                let confirmationMessages = ZMConversation.confirmDeliveredMessages(messages, in: conversations, with: syncMOC)
//                for message in confirmationMessages {
//                    self.applicationStatusDirectory?.deliveryConfirmation.needsToConfirmMessage(message.nonce!)
//                }
//            }
//
//            syncMOC.saveOrRollback()
//
//            Logging.eventProcessing.debug("Events processed in \(-date.timeIntervalSinceNow): \(self.eventProcessingTracker?.debugDescription ?? "")")
//
//        }
//
//    }
}
