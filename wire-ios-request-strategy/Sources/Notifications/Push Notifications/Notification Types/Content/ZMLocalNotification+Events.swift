//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import WireDataModel

public extension ZMLocalNotification {

    static let ZMShouldHideNotificationContentKey = "ZMShouldHideNotificationContentKey"

    convenience init?(event: ZMUpdateEvent, conversation: ZMConversation?, managedObjectContext moc: NSManagedObjectContext) {
        var builderType: EventNotificationBuilder.Type?

        switch event.type {
        case .conversationOtrMessageAdd:
            guard let message = GenericMessage(from: event) else { break }
            builderType = message.hasReaction ? ReactionEventNotificationBuilder.self : NewMessageNotificationBuilder.self

        case .conversationCreate:
            builderType = ConversationCreateEventNotificationBuilder.self

        case .conversationDelete:
            builderType = ConversationDeleteEventNotificationBuilder.self

        case .userConnection:
            builderType = UserConnectionEventNotificationBuilder.self

        case .userContactJoin:
            builderType = NewUserEventNotificationBuilder.self

        case .conversationMemberJoin, .conversationMemberLeave, .conversationMessageTimerUpdate:
            guard conversation?.remoteIdentifier != nil else { return nil }
            builderType = NewSystemMessageNotificationBuilder.self

        default:
            break
        }

        if let builder = builderType?.init(event: event, conversation: conversation, managedObjectContext: moc) {
            self.init(builder: builder, moc: moc)
        } else {
            return nil
        }
    }

    // Determines if the notification content should be hidden as reflected in the store
    // metatdata for the given managed object context.
    static func shouldHideNotificationContent(moc: NSManagedObjectContext?) -> Bool {
        let value = moc?.persistentStoreMetadata(forKey: ZMShouldHideNotificationContentKey) as? NSNumber
        return value?.boolValue ?? false
    }

}

// Base class for event notification builders. Subclass this for each
// event type, and override the components specific for that type.
private class EventNotificationBuilder: NotificationBuilder {

    let event: ZMUpdateEvent
    let moc: NSManagedObjectContext
    var sender: ZMUser?
    var conversation: ZMConversation?

    var notificationType: LocalNotificationType {
        fatal("You must override this property in a subclass")
    }

    required init?(event: ZMUpdateEvent, conversation: ZMConversation?, managedObjectContext: NSManagedObjectContext) {
        self.event = event
        self.conversation = conversation
        self.moc = managedObjectContext

        if let senderID = event.senderUUID {
            self.sender = ZMUser.fetch(with: senderID, domain: event.senderDomain, in: moc)
        }
    }

    func shouldCreateNotification() -> Bool {
        // if there is a sender, it's not the selfUser
        if let sender = self.sender, sender.isSelfUser { return false }

        if let conversation = conversation {
            if conversation.mutedMessageTypesIncludingAvailability != .none {
                return false
            }

            if let timeStamp = event.timestamp,
                let lastRead = conversation.lastReadServerTimeStamp, lastRead.compare(timeStamp) != .orderedAscending {
                // don't show notifications that have already been read
                return false
            }
        }

        return true
    }

    func titleText() -> String? {
        return notificationType.titleText(selfUser: ZMUser.selfUser(in: moc), conversation: conversation)
    }

    func bodyText() -> String {
        return notificationType.messageBodyText(sender: sender, conversation: conversation)
    }

    func userInfo() -> NotificationUserInfo? {
        let selfUser = ZMUser.selfUser(in: moc)
        guard let selfUserRemoteID = selfUser.remoteIdentifier else { return nil }

        let userInfo = NotificationUserInfo()
        userInfo.selfUserID = selfUserRemoteID
        userInfo.senderID = event.senderUUID
        userInfo.conversationID = conversation?.remoteIdentifier
        userInfo.messageNonce = event.messageNonce
        userInfo.eventTime = event.timestamp
        userInfo.conversationName = conversation?.meaningfulDisplayName
        userInfo.teamName = selfUser.team?.name

        return userInfo
    }
}

// MARK: - Reaction Event

private class ReactionEventNotificationBuilder: EventNotificationBuilder {

    private let emoji: String
    private let nonce: UUID
    private let message: GenericMessage

    override var notificationType: LocalNotificationType {
        if ZMLocalNotification.shouldHideNotificationContent(moc: self.moc) {
            return LocalNotificationType.message(.hidden)
        } else {
            return LocalNotificationType.message(.reaction(emoji: emoji))
        }
    }

    required init?(event: ZMUpdateEvent, conversation: ZMConversation?, managedObjectContext: NSManagedObjectContext) {
        guard
            let message = GenericMessage(from: event), message.hasReaction,
            let nonce = UUID(uuidString: message.reaction.messageID)
        else {
            return nil
        }

        self.message = message
        self.emoji = message.reaction.emoji
        self.nonce = nonce

        super.init(event: event, conversation: conversation, managedObjectContext: managedObjectContext)
    }

    override func shouldCreateNotification() -> Bool {
        guard super.shouldCreateNotification() else { return false }

        // If the message is an "unlike", we don't want to display a notification
        guard message.reaction.emoji != "" else { return false }

        // fetch message that was reacted to and make sure the sender of the original message is the selfUser
        guard let conversation = conversation,
              let reactionMessage = ZMMessage.fetch(withNonce: UUID(uuidString: message.reaction.messageID), for: conversation, in: moc),
            reactionMessage.sender == ZMUser.selfUser(in: moc) else { return false }

        return true
    }

    override func userInfo() -> NotificationUserInfo? {
        // we want to store the nonce of the message being reacted to, not the event nonce
        let info = super.userInfo()
        info?.messageNonce = nonce
        return info
    }
}

// MARK: - Conversation Create Event

private class ConversationCreateEventNotificationBuilder: EventNotificationBuilder {

    override var notificationType: LocalNotificationType {
        return LocalNotificationType.event(.conversationCreated)
    }

    override func shouldCreateNotification() -> Bool {
        return super.shouldCreateNotification()
    }

}

// MARK: - Conversation Delete Event

private class ConversationDeleteEventNotificationBuilder: EventNotificationBuilder {

    override var notificationType: LocalNotificationType {
        return LocalNotificationType.event(.conversationDeleted)
    }

    override func shouldCreateNotification() -> Bool {
        return super.shouldCreateNotification() && conversation?.conversationType == .group
    }

}

// MARK: - User Connection Event

private class UserConnectionEventNotificationBuilder: EventNotificationBuilder {

    var eventType: LocalNotificationEventType
    var senderName: String?

    override var notificationType: LocalNotificationType {
        return LocalNotificationType.event(eventType)
    }

    required init?(event: ZMUpdateEvent, conversation: ZMConversation?, managedObjectContext: NSManagedObjectContext) {

        if let status = (event.payload["connection"] as? [String: AnyObject] )?["status"] as? String {
            if status == "accepted" {
                self.eventType = .connectionRequestAccepted
            } else if status == "pending" {
                self.eventType = .connectionRequestPending
            } else {
                return nil
            }
        } else {
            return nil
        }

        super.init(event: event, conversation: conversation, managedObjectContext: managedObjectContext)

        senderName = sender?.name ?? (event.payload["user"] as? [String: Any])?["name"] as? String
    }

    override func titleText() -> String? {
        return nil
    }

    override func bodyText() -> String {
        return notificationType.messageBodyText(senderName: senderName)
    }

}

// MARK: - New User Event

private class NewUserEventNotificationBuilder: EventNotificationBuilder {

    override var notificationType: LocalNotificationType {
        return LocalNotificationType.event(.newConnection)
    }

    override func titleText() -> String? {
        return nil
    }

    override func bodyText() -> String {
        let name = (event.payload["user"] as? [String: Any])?["name"] as? String
        return notificationType.messageBodyText(senderName: name)
    }
}

// MARK: - Message

private class NewMessageNotificationBuilder: EventNotificationBuilder {

    private let message: GenericMessage
    private let contentType: LocalNotificationContentType

    required init?(event: ZMUpdateEvent, conversation: ZMConversation?, managedObjectContext: NSManagedObjectContext) {
        guard
            let message = GenericMessage(from: event),
            let contentType = LocalNotificationContentType(message: message, conversation: conversation, in: managedObjectContext)
        else {
            return nil
        }

        self.message = message
        self.contentType = contentType
        super.init(event: event, conversation: conversation, managedObjectContext: managedObjectContext)
    }

    override func titleText() -> String? {
        return notificationType.titleText(selfUser: ZMUser.selfUser(in: moc), conversation: conversation)
    }

    override func bodyText() -> String {
        return notificationType.messageBodyText(sender: sender, conversation: conversation).trimmingCharacters(in: .whitespaces)
    }

    override var notificationType: LocalNotificationType {
        return shouldHideNotificationContent
            ? .message(.hidden)
            : .message(contentType)
    }

    private var shouldHideNotificationContent: Bool {
        switch contentType {
        case .ephemeral:
            return false
        default:
            return ZMLocalNotification.shouldHideNotificationContent(moc: moc)
        }
    }

    override func shouldCreateNotification() -> Bool {
        if let conversation = conversation,
            let senderUUID = event.senderUUID,
            conversation.isMessageSilenced(message, senderID: senderUUID) {
            Logging.push.safePublic("Not creating local notification for message with nonce = \(event.messageNonce) because conversation is silenced")
            return false
        }

        if let timeStamp = event.timestamp,
            let lastRead = conversation?.lastReadServerTimeStamp,
            lastRead.compare(timeStamp) != .orderedAscending {
            return false
        }
        return true
    }
}

// MARK: - System Message

private class NewSystemMessageNotificationBuilder: EventNotificationBuilder {
    let contentType: LocalNotificationContentType

    required init?(event: ZMUpdateEvent, conversation: ZMConversation?, managedObjectContext: NSManagedObjectContext) {
        guard let contentType = LocalNotificationContentType(event: event, conversation: conversation, in: managedObjectContext) else {
            return nil
        }

        self.contentType = contentType
        super.init(event: event, conversation: conversation, managedObjectContext: managedObjectContext)
    }

    override func titleText() -> String? {
        return notificationType.titleText(selfUser: ZMUser.selfUser(in: moc), conversation: conversation)
    }

    override func bodyText() -> String {
        return notificationType.messageBodyText(sender: sender, conversation: conversation).trimmingCharacters(in: .whitespaces)
    }

    override var notificationType: LocalNotificationType {
        return LocalNotificationType.message(contentType)
    }

    override func shouldCreateNotification() -> Bool {
        // we don't want to create notifications when other people join or leave conversation
        let concernsSelfUser = event.userIDs.contains(ZMUser.selfUser(in: moc).remoteIdentifier)

        switch contentType {
        case .participantsAdded where concernsSelfUser == false, .participantsRemoved where concernsSelfUser == false:
            return false
        default:
            break
        }
         return super.shouldCreateNotification()
    }
}
