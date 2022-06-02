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

import Foundation
import UserNotifications

/**
 * User info keys for notifications.
 */

private enum NotificationUserInfoKey: String {
    case requestID = "requestIDString"
    case conversationID = "conversationIDString"
    case messageNonce = "messageNonceString"
    case senderID = "senderIDString"
    case eventTime = "eventTime"
    case selfUserID = "selfUserIDString"
    case conversationName = "conversationNameString"
    case teamName = "teamNameString"
}

/**
 * A structure that describes the content of the user info payload
 * of user notifications.
 */

public class NotificationUserInfo: NSObject, NSCoding {

    /// The key under which the storage property is encoded.
    private static let storageKey = "storageKey"

    /// The raw values of the user info. These must contain property list
    /// data types only, otherwise scheduled UNNotificationRequest objects
    /// using this user info within its content will fail.
    public private(set) var storage: [AnyHashable: Any]

    /// Creates the user info from its raw value.
    public init(storage: [AnyHashable: Any]) {
        self.storage = storage
        super.init()
    }

    /// Creates an empty notification user info payload.
    public override convenience init() {
        self.init(storage: [:])
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        guard let data = aDecoder.decodeObject(forKey: type(of: self).storageKey) as? [AnyHashable: Any] else {
            return nil
        }

        self.init(storage: data)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(storage, forKey: type(of: self).storageKey)
    }

    // MARK: - Properties

    private func uuid(for key: NotificationUserInfoKey) -> UUID? {
        guard let uuidString = self[key] as? String else { return nil }
        return UUID(uuidString: uuidString)
    }

    public var requestID: UUID? {
        get { return uuid(for: .requestID) }
        set { self[.requestID] = newValue?.uuidString }
    }

    public var conversationID: UUID? {
        get { return uuid(for: .conversationID)}
        set { self[.conversationID] = newValue?.uuidString }
    }

    public var conversationName: String? {
        get { return self[.conversationName] as? String }
        set { self[.conversationName] = newValue }
    }

    public var teamName: String? {
        get { return self[.teamName] as? String }
        set { self[.teamName] = newValue }
    }

    public var messageNonce: UUID? {
        get { return uuid(for: .messageNonce) }
        set { self[.messageNonce] = newValue?.uuidString }
    }

    public var senderID: UUID? {
        get { return uuid(for: .senderID) }
        set { self[.senderID] = newValue?.uuidString }
    }

    public var eventTime: Date? {
        get {
            guard let interval = self[.eventTime] as? TimeInterval else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set { self[.eventTime] = newValue?.timeIntervalSince1970 }
    }

    public var selfUserID: UUID? {
        get { return uuid(for: .selfUserID) }
        set { self[.selfUserID] = newValue?.uuidString }
    }
}

// MARK: - Utilities

extension NotificationUserInfo {

    fileprivate subscript(_ key: NotificationUserInfoKey) -> Any? {
        get {
            return storage[key.rawValue]
        }
        set {
            storage[key.rawValue] = newValue
        }
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NotificationUserInfo else { return false }
        return self == other
    }

    static func == (lhs: NotificationUserInfo, rhs: NotificationUserInfo) -> Bool {
        return  lhs.requestID == rhs.requestID &&
                lhs.conversationID == rhs.conversationID &&
                lhs.conversationName == rhs.conversationName &&
                lhs.teamName == rhs.teamName &&
                lhs.messageNonce == rhs.messageNonce &&
                lhs.senderID == rhs.senderID &&
                lhs.eventTime == rhs.eventTime &&
                lhs.selfUserID == rhs.selfUserID
    }
}

// MARK: - Lookup

extension NotificationUserInfo {

    /**
     * Fetches the conversion that matches the description stored in this user info fields.
     *
     * - parameter managedObjectContext: The context that should be used to perform the lookup.
     * - returns: The conversation, if found.
     */

    public func conversation(in managedObjectContext: NSManagedObjectContext) -> ZMConversation? {
        guard let remoteID = conversationID else {
            return nil
        }

        return ZMConversation.fetch(with: remoteID, domain: nil, in: managedObjectContext)
    }

    /**
     * Fetches the message that matches the description stored in this user info fields.
     *
     * - parameter conversation: The conversation where the message should be searched.
     * - parameter managedObjectContext: The context that should be used to perform the lookup.
     * - returns: The message, if found.
     */

    public func message(in conversation: ZMConversation, managedObjectContext: NSManagedObjectContext) -> ZMMessage? {
        guard let nonce = messageNonce else {
            return nil
        }

        return ZMMessage.fetch(withNonce: nonce, for: conversation, in: managedObjectContext)
    }

    /**
     * Fetches the sender that matches the description stored in this user info fields.
     *
     * - parameter managedObjectContext: The context that should be used to perform the lookup.
     * - returns: The sender of the event, if found.
     */

    func sender(in managedObjectContext: NSManagedObjectContext) -> ZMUser? {
        guard let senderID = senderID else {
            return nil
        }

        return ZMUser.fetch(with: senderID, domain: nil, in: managedObjectContext)
    }

}

// MARK: - Configuration

extension NotificationUserInfo {

    func setupUserInfo(for conversation: ZMConversation, sender: ZMUser) {
        addSelfUserInfo(using: conversation)
        self.conversationID = conversation.remoteIdentifier
        self.senderID = sender.remoteIdentifier
    }

    func setupUserInfo(for conversation: ZMConversation, event: ZMUpdateEvent) {
        addSelfUserInfo(using: conversation)
        self.conversationID = conversation.remoteIdentifier
        self.senderID = event.senderUUID
        self.messageNonce = event.messageNonce
        self.eventTime = event.timestamp
    }

    func setupUserInfo(for message: ZMMessage) {
        addSelfUserInfo(using: message)
        self.conversationID = message.conversation?.remoteIdentifier
        self.senderID = message.sender?.remoteIdentifier
        self.messageNonce = message.nonce
        self.eventTime = message.serverTimestamp
    }

    /// Adds the description of the self user using the given managed object.
    private func addSelfUserInfo(using object: NSManagedObject) {
        guard let context = object.managedObjectContext else {
            fatalError("Object doesn't have a managed context.")
        }

        let selfUser = ZMUser.selfUser(in: context)
        self[.selfUserID] = selfUser.remoteIdentifier
    }

}

// MARK: - Accessors

extension UNNotification {

    /// The user info describing the notification context.
    public var userInfo: NotificationUserInfo {
        return NotificationUserInfo(storage: request.content.userInfo)
    }

}

extension UNNotificationResponse {

    /// The user info describing the notification context.
    public var userInfo: NotificationUserInfo {
        return notification.userInfo
    }

}
