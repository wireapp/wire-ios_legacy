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

import UserNotifications

/// Defines the various types of local notifications, some of which
/// have associated subtypes.
///
enum LocalNotificationType {
    case event(LocalNotificationEventType)
    case calling(CallState)
    case message(LocalNotificationContentType)
    case failedMessage
    case availabilityBehaviourChangeAlert(AvailabilityKind)
}

/// A notification builder provides the main components used to configure
/// a local notification. 
///
protocol NotificationBuilder {
    var notificationType: LocalNotificationType { get }
    func shouldCreateNotification() -> Bool
    func titleText() -> String?
    func bodyText() -> String
    func userInfo() -> NotificationUserInfo?
}

/// This class encapsulates all the data necessary to produce a local
/// notification. It configures and formats the textual content for
/// various notification types (message, calling, etc.) and includes
/// information regarding the conversation, sender, and team name.
///
class ZMLocalNotification: NSObject {

    /// The unique identifier for this notification. Use it to later update
    /// or remove pending or scheduled notification requests.
    let id: UUID

    let type: LocalNotificationType
    var title: String?
    var body: String
    var category: PushNotificationCategory
    var sound: NotificationSound
    var userInfo: NotificationUserInfo?

    init?(builder: NotificationBuilder, moc: NSManagedObjectContext) {
        guard builder.shouldCreateNotification() else { return nil }
        self.type = builder.notificationType
        self.title = builder.titleText()
        self.body = builder.bodyText()

        let hasTeam = ZMUser.selfUser(in: moc).hasTeam
        let encryptionAtRestEnabled = moc.encryptMessagesAtRest

        self.category = builder.notificationType.category(
            hasTeam: hasTeam,
            encryptionAtRestEnabled: encryptionAtRestEnabled
        )

        self.sound = builder.notificationType.sound
        self.userInfo = builder.userInfo()
        self.id = userInfo?.messageNonce ?? UUID()
        super.init()

        self.userInfo?.requestID = id
    }

    /// Returns a configured concrete `UNNotificationContent` object.
    lazy var content: UNNotificationContent = {
        let content = UNMutableNotificationContent()
        content.body = self.body
        content.categoryIdentifier = self.category.rawValue
        content.sound = UNNotificationSound(named: convertToUNNotificationSoundName(sound.name))

        if let title = self.title {
            content.title = title
        }

        if let userInfo = self.userInfo {
            content.userInfo = userInfo.storage
        }

        // only group non ephemeral messages
        if let conversationID = self.conversationID {
            switch self.type {
            case .message(.ephemeral): break
            default: content.threadIdentifier = conversationID.transportString()
            }
        }

        return content
    }()

    /// Returns a configured concrete `UNNotificationRequest`.
    lazy var request: UNNotificationRequest = {
        return UNNotificationRequest(identifier: id.uuidString, content: content, trigger: nil)
    }()

}

// MARK: - Properties

extension ZMLocalNotification {

    var selfUserID: UUID? { return userInfo?.selfUserID }
    var senderID: UUID? { return userInfo?.senderID }
    var messageNonce: UUID? { return userInfo?.messageNonce }
    var conversationID: UUID? { return userInfo?.conversationID }

    /// Returns true if it is a calling notification, else false.
    var isCallingNotification: Bool {
        switch type {
        case .calling: return true
        default: return false
        }
    }

    /// Returns true if it is a ephemeral notification, else false.
    var isEphemeral: Bool {
        guard case .message(.ephemeral) = type else { return false }
        return true
    }

}

// MARK: - Lookup

extension ZMLocalNotification {

    func conversation(in moc: NSManagedObjectContext) -> ZMConversation? {
        return userInfo?.conversation(in: moc)
    }

    func sender(in moc: NSManagedObjectContext) -> ZMUser? {
        return userInfo?.sender(in: moc)
    }
}

// MARK: - Unread Count

extension ZMLocalNotification {

    func increaseEstimatedUnreadCount(on conversation: ZMConversation?) {

        if type.shouldIncreaseUnreadCount {
            conversation?.internalEstimatedUnreadCount += 1
        }

        if type.shouldIncreaseUnreadMentionCount {
            conversation?.internalEstimatedUnreadSelfMentionCount += 1
        }

        if type.shouldIncreaseUnreadReplyCount {
            conversation?.internalEstimatedUnreadSelfReplyCount += 1
        }
    }

}

extension LocalNotificationType {

    var shouldIncreaseUnreadCount: Bool {
        guard case LocalNotificationType.message(let contentType) = self else {
            return false
        }

        switch contentType {
        case .messageTimerUpdate, .participantsAdded, .participantsRemoved, .reaction:
            return false
        default:
            return true
        }
    }

    var shouldIncreaseUnreadMentionCount: Bool {
        guard case LocalNotificationType.message(let contentType) = self else {
            return false
        }

        switch contentType {
        case .text(_, isMention: true, isReply: _),
             .ephemeral(isMention: true, isReply: _):
            return true
        default:
            return false
        }
    }

    var shouldIncreaseUnreadReplyCount: Bool {
        guard case LocalNotificationType.message(let contentType) = self else {
            return false
        }

        switch contentType {
        case .text(_, isMention: _, isReply: true),
             .ephemeral(isMention: _, isReply: true):
            return true
        default:
            return false
        }
    }

}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUNNotificationSoundName(_ input: String) -> UNNotificationSoundName {
	return UNNotificationSoundName(rawValue: input)
}
