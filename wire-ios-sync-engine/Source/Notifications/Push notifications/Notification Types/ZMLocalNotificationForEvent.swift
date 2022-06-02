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
import ZMUtilities

let ZMLocalNotificationRingingDefaultSoundName = "ringing_from_them_long.caf"
let ZMLocalNotificationPingDefaultSoundName = "ping_from_them.caf"
let ZMLocalNotificationNewMessageDefaultSoundName = "new_message_apns.caf"

func ZMCustomSoundName(key: String) -> String? {
    guard let soundName = NSUserDefaults.standardUserDefaults().objectForKey(key) as? String else { return nil }
    return ZMSound(rawValue: soundName)?.filename()
}

func ZMLocalNotificationRingingSoundName() -> String {
    return ZMCustomSoundName("ZMCallSoundName") ??  ZMLocalNotificationRingingDefaultSoundName
}

func ZMLocalNotificationPingSoundName() -> String {
    return ZMCustomSoundName("ZMPingSoundName") ?? ZMLocalNotificationPingDefaultSoundName
}

func ZMLocalNotificationNewMessageSoundName() -> String {
    return ZMCustomSoundName("ZMMessageSoundName") ?? ZMLocalNotificationNewMessageDefaultSoundName
}

public extension ZMLocalNotificationForEvent {

    public static func notification(forEvent event: ZMUpdateEvent, managedObjectContext: NSManagedObjectContext, application: Application) -> ZMLocalNotificationForEvent? {
        switch event.type {
        case .ConversationOtrMessageAdd:
            if let note = ZMLocalNotificationForKnockMessage(event: event, managedObjectContext: managedObjectContext, application: application) {
                return note
            }
            if let note = ZMLocalNotificationForReaction(event: event, managedObjectContext: managedObjectContext, application: application) {
                return note
            }
            return ZMLocalNotificationForMessage(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationAssetAdd, .ConversationMessageAdd, .ConversationOtrAssetAdd:
            return ZMLocalNotificationForMessage(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationConnectRequest:
            return ZMLocalNotificationForConnectionEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationKnock:
            return ZMLocalNotificationForKnockMessage(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationMemberJoin:
            return ZMLocalNotificationForMemberJoinEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationMemberLeave:
            return ZMLocalNotificationForMemberLeaveEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationRename:
            return ZMLocalNotificationForRenameEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .UserConnection:
            return ZMLocalNotificationForUserConnectionEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationCreate:
            return ZMLocalNotificationForConversationCreateEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .UserContactJoin:
            return ZMLocalNotificationForNewUserEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .CallState:
            return ZMLocalNotificationForCallEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        default:
            return nil
        }
    }
}

public class ZMLocalNotificationForEvent: ZMLocalNotification {

    public var shouldBeDiscarded: Bool = false
    public let sender: ZMUser?

    public let notificationType: ZMLocalNotificationType = ZMLocalNotificationType.Event
    internal var notifications: [UILocalNotification] = []

    public override var uiNotifications: [UILocalNotification] {
        return notifications
    }

    let application: Application
    let managedObjectContext: NSManagedObjectContext

    var events: [ZMUpdateEvent] = []

    var lastEvent: ZMUpdateEvent? {
        return events.last
    }

    var eventData: [String: AnyObject] {
        if let lastEvent = lastEvent {
            return (lastEvent.payload as? [String: AnyObject])!["data"] as! [String: AnyObject]
        }
        return [:]
    }

    public convenience init?(event: ZMUpdateEvent, managedObjectContext: NSManagedObjectContext, application: Application) {
        let conversation = ZMLocalNotificationForEvent.fetchConversation(event, managedObjectContext: managedObjectContext)
        self.init(events: [event], conversation: conversation, managedObjectContext: managedObjectContext, application: application)
    }

    required public init?(events: [ZMUpdateEvent], conversation: ZMConversation?, managedObjectContext: NSManagedObjectContext, application: Application, copyFromNote: ZMLocalNotificationForEvent? = nil) {
        self.application = application
        self.events = events
        if let senderUUID = events.last?.senderUUID() {
            self.sender = ZMUser(remoteID: senderUUID, createIfNeeded: false, inContext: managedObjectContext)
        } else {
            self.sender = nil
        }
        self.managedObjectContext = managedObjectContext
        super.init()

        self.conversation = conversation

        if let note = copyFromNote {
            prepareForCopy(note)
        }

        if !canCreateNotification() { return nil }
        if shouldCreateNoficiationForLastEvent {
            let notification = configureNotification()
            notifications.append(notification)
        }
    }

    public func copyByAddingEvent(event: ZMUpdateEvent) -> ZMLocalNotificationForEvent? {
        if !canAddEvent(event) { return nil }
        events.append(event)

        guard let note =  self.dynamicType.init(events: events, conversation: conversation, managedObjectContext: managedObjectContext, application: application, copyFromNote: self)
        else { return nil }

        if note.shouldCopyNotifications {
            note.notifications = notifications + note.notifications
        } else {
            cancelNotifications()
        }
        return note
    }

    func cancelNotifications() {
        notifications.forEach { application.cancelLocalNotification($0) }
    }

    func configureNotification() -> UILocalNotification {
        let notification = UILocalNotification()
        let shouldHideContent = managedObjectContext.valueForKey(ZMShouldHideNotificationContentKey)
        if let shouldHideContent = shouldHideContent as? NSNumber where shouldHideContent.boolValue == true {
            notification.alertBody = ZMPushStringDefault.localizedString()
            notification.soundName = ZMLocalNotificationNewMessageSoundName()
        } else {
            notification.alertBody = configureAlertBody().stringByEscapingPercentageSymbols()
            notification.soundName = soundName
            notification.category = category
        }
        notification.setupUserInfo(conversation, forEvent: lastEvent)
        return notification
    }

    var allSenderUUIDS: Set<NSUUID> {
        let senderIDs = events.flatMap { $0.senderUUID() }
        return Set(senderIDs)
    }

    var allEventsAreFromSameSender: Bool {
        return allSenderUUIDS.count < 2
    }

    static func fetchConversation(event: ZMUpdateEvent, managedObjectContext: NSManagedObjectContext) -> ZMConversation? {
        if let uuid = event.conversationUUID() {
            return ZMConversation.fetchObjectWithRemoteIdentifier(uuid, inManagedObjectContext: managedObjectContext)
        }
        return nil
    }

    func senderIsSelfUser(event: ZMUpdateEvent) -> Bool {
        let selfUser = ZMUser.selfUserInContext(managedObjectContext)
        return (sender?.remoteIdentifier == selfUser.remoteIdentifier)
    }

    public func containsIdenticalEvent(event: ZMUpdateEvent) -> Bool {
        guard copiedEventTypes.contains(event.type) || lastEvent?.type == event.type || event.messageNonce() != nil,
              let conversation = conversation where conversation.remoteIdentifier == event.conversationUUID()
        else { return false }

        let idx = findIndex(events) { $0.messageNonce() == event.messageNonce() }
        return idx != nil
    }

    /// You HAVE To override configureAlertBody() to configure the alert body
    func configureAlertBody() -> String { return "" }

    // MARK: Override these if needed

    /// if this returns true, it copies previous UILocalNotifications over, otherwise those get cancelled
    var shouldCopyNotifications: Bool { return false }
    /// set to true if notification depends / refers to a specific conversation
    var requiresConversation: Bool { return false }
    /// create a notification even if conversation is silenced
    var ignoresSilencedState: Bool { return false }
    /// if true, it will create a ZMLocalNotification but no UILocalNotification for this event, this will be true in most cases
    var shouldCreateNoficiationForLastEvent: Bool { return true }
    /// if true, it only copies events of the same sender
    var shouldCopyEventsOfSameSender: Bool { return false }

    /// if empty, it does not copy events
    var copiedEventTypes: [ZMUpdateEventType] { return [] }
    var soundName: String { return ZMLocalNotificationNewMessageSoundName() }
    var category: String { return ZMConversationCategory }

    /// you can copy additional properties from the previous notification to the new one
    func prepareForCopy(note: ZMLocalNotificationForEvent) { }

    func canCreateNotification() -> Bool {
        guard (conversation != nil || !requiresConversation),
              let lastEvent = lastEvent where (!senderIsSelfUser(lastEvent) || lastEvent.type == .CallState)
        else { return false }

        if let conversation = conversation {
            if conversation.isSilenced && !ignoresSilencedState {
                return false
            }
            if let timeStamp = lastEvent.timeStamp(),
               let lastRead = conversation.lastReadServerTimeStamp where lastRead.compare(timeStamp) != .OrderedAscending {
                // don't show notifications that have already been read
                return false
            }
        }
        return true
    }

    func canAddEvent(event: ZMUpdateEvent) -> Bool {
        guard copiedEventTypes.contains(event.type),
              let conversation = conversation where
                conversation.remoteIdentifier == event.conversationUUID() && (!conversation.isSilenced || ignoresSilencedState)
        else {
            return false
        }
        if shouldCopyEventsOfSameSender && self.allSenderUUIDS.first != event.senderUUID() {
            return false
        }
        return true
    }
}
