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
import UserNotifications

/// Creates and cancels local notifications
@objcMembers public class LocalNotificationDispatcher: NSObject {

    public static let ZMShouldHideNotificationContentKey = "ZMShouldHideNotificationContentKey"

    let eventNotifications: ZMLocalNotificationSet
    let callingNotifications: ZMLocalNotificationSet
    let failedMessageNotifications: ZMLocalNotificationSet

    var notificationCenter: UserNotificationCenter = UNUserNotificationCenter.current()

    let syncMOC: NSManagedObjectContext
    fileprivate var observers: [Any] = []

    var localNotificationBuffer = [ZMLocalNotification]()

    @objc(initWithManagedObjectContext:)
    public init(in managedObjectContext: NSManagedObjectContext) {
        self.syncMOC = managedObjectContext
        self.eventNotifications = ZMLocalNotificationSet(archivingKey: "ZMLocalNotificationDispatcherEventNotificationsKey", keyValueStore: managedObjectContext)
        self.failedMessageNotifications = ZMLocalNotificationSet(archivingKey: "ZMLocalNotificationDispatcherFailedNotificationsKey", keyValueStore: managedObjectContext)
        self.callingNotifications = ZMLocalNotificationSet(archivingKey: "ZMLocalNotificationDispatcherCallingNotificationsKey", keyValueStore: managedObjectContext)
        super.init()
        observers.append(
            NotificationInContext.addObserver(name: ZMConversation.lastReadDidChangeNotificationName,
                                              context: managedObjectContext.notificationContext,
                                              using: { [weak self] in self?.cancelNotificationForLastReadChanged(notification: $0)})
        )
    }

    func scheduleLocalNotification(_ note: ZMLocalNotification) {
        Logging.push.safePublic("Scheduling local notification with id=\(note.id)")

        notificationCenter.add(note.request, withCompletionHandler: { error in
            if let error = error {
                Logging.push.safePublic("Error scheduling local notification")
                Logging.push.error("Scheduling Error: \(error)")
            } else {
                Logging.push.safePublic("Successfully scheduled local notification")
            }
        })
    }

    /// Determines if the notification content should be hidden as reflected in the store
    /// metatdata for the given managed object context.
    ///
    static func shouldHideNotificationContent(moc: NSManagedObjectContext?) -> Bool {
        let value = moc?.persistentStoreMetadata(forKey: ZMShouldHideNotificationContentKey) as? NSNumber
        return value?.boolValue ?? false
    }
}

extension LocalNotificationDispatcher: ZMEventConsumer {

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        // nop
    }

    public func processEventsWhileInBackground(_ events: [ZMUpdateEvent]) {
        let eventsToForward = events.filter { $0.source.isOne(of: .pushNotification, .webSocket) }
        self.didReceive(events: eventsToForward, conversationMap: [:])
    }

    func didReceive(events: [ZMUpdateEvent], conversationMap: [UUID: ZMConversation]) {
        events.forEach { event in

            var conversation: ZMConversation?
            if let conversationID = event.conversationUUID {
                // Fetch the conversation here to avoid refetching every time we try to create a notification
                conversation = conversationMap[conversationID] ?? ZMConversation.fetch(with: conversationID, domain: event.conversationDomain, in: self.syncMOC)
            }

            if let messageNonce = event.messageNonce {
                if eventNotifications.notifications.contains(where: { $0.messageNonce == messageNonce }) {
                    // ignore events which we already scheduled a notification for
                    return
                }
            }

            if let receivedMessage = GenericMessage(from: event) {

                if receivedMessage.hasReaction,
                   receivedMessage.reaction.emoji.isEmpty,
                   let messageID = UUID(uuidString: receivedMessage.reaction.messageID) {
                    // if it's an "unlike" reaction event, cancel the previous "like" notification for this message
                    eventNotifications.cancelCurrentNotifications(messageNonce: messageID)
                }

                if receivedMessage.hasHidden || receivedMessage.hasDeleted {
                    // Cancel notification for message that was deleted or hidden
                    cancelMessageForDeletedMessage(receivedMessage)
                }
            }

            let note = ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: self.syncMOC)

            note?.increaseEstimatedUnreadCount(on: conversation)
            note.apply(eventNotifications.addObject)
            note.apply(scheduleLocalNotification)
        }
    }
}

// MARK: - Availability behaviour change

extension LocalNotificationDispatcher {

    public func notifyAvailabilityBehaviourChangedIfNeeded() {
        let selfUser = ZMUser.selfUser(in: syncMOC)
        var notify = selfUser.needsToNotifyAvailabilityBehaviourChange

        guard notify.contains(.notification) else { return }

        let note = ZMLocalNotification(availability: selfUser.availability, managedObjectContext: syncMOC)
        note.apply(scheduleLocalNotification)
        notify.remove(.notification)
        selfUser.needsToNotifyAvailabilityBehaviourChange = notify
        syncMOC.enqueueDelayedSave()
    }

}

// MARK: - Failed messages

extension LocalNotificationDispatcher: PushMessageHandler {

    /// Informs the user that the message failed to send
    public func didFailToSend(_ message: ZMMessage) {
        if message.visibleInConversation == nil || message.conversation?.conversationType == .self {
            return
        }
        let note = ZMLocalNotification(expiredMessage: message, moc: syncMOC)
        note.apply(scheduleLocalNotification)
        note.apply(failedMessageNotifications.addObject)
    }

    /// Informs the user that a message in a conversation failed to send
    public func didFailToSendMessage(in conversation: ZMConversation) {
        let note = ZMLocalNotification(expiredMessageIn: conversation, moc: syncMOC)
        note.apply(scheduleLocalNotification)
        note.apply(failedMessageNotifications.addObject)
    }
}

// MARK: - Canceling notifications

extension LocalNotificationDispatcher {

    private var allNotificationSets: [ZMLocalNotificationSet] {
        return [self.eventNotifications,
                self.failedMessageNotifications,
                self.callingNotifications]
    }

    /// Can be used for cancelling all conversations if need
    public func cancelAllNotifications() {
        self.allNotificationSets.forEach { $0.cancelAllNotifications() }
    }

    /// Cancels all notifications for a specific conversation
    /// - note: Notifications for a specific conversation are otherwise deleted automatically when the message window changes and
    /// ZMConversationDidChangeVisibleWindowNotification is called
    public func cancelNotification(for conversation: ZMConversation) {
        self.allNotificationSets.forEach { $0.cancelNotifications(conversation) }
    }

    func cancelMessageForDeletedMessage(_ genericMessage: GenericMessage) {
        var idToDelete: UUID?

        if genericMessage.hasDeleted {
            let deleted = genericMessage.deleted.messageID
            idToDelete = UUID(uuidString: deleted)
        } else if genericMessage.hasHidden {
            let hidden = genericMessage.hidden.messageID
            idToDelete = UUID(uuidString: hidden)
        }

        if let idToDelete = idToDelete {
            eventNotifications.cancelCurrentNotifications(messageNonce: idToDelete)
        }
    }

    /// Cancels all notification in the conversation that is speficied as object of the notification
    func cancelNotificationForLastReadChanged(notification: NotificationInContext) {
        guard let conversation = notification.object as? ZMConversation else { return }
        let isUIObject = conversation.managedObjectContext?.zm_isUserInterfaceContext ?? false

        self.syncMOC.performGroupedBlock {
            if isUIObject {
                // clear all notifications for this conversation
                if let syncConversation = (try? self.syncMOC.existingObject(with: conversation.objectID)) as? ZMConversation {
                    self.cancelNotification(for: syncConversation)
                }
            } else {
                self.cancelNotification(for: conversation)
            }
        }
    }
}
