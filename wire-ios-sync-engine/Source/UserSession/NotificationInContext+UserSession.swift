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

import WireDataModel

// MARK: - Initial sync

@objc public protocol ZMInitialSyncCompletionObserver: NSObjectProtocol {
    func initialSyncCompleted()
}

private let initialSyncCompletionNotificationName = Notification.Name(rawValue: "ZMInitialSyncCompletedNotification")

extension ZMUserSession: NotificationContext { } // Mark ZMUserSession as valid notification context

extension ZMUserSession {

    @objc public static func notifyInitialSyncCompleted(context: NSManagedObjectContext) {
        NotificationInContext(name: initialSyncCompletionNotificationName, context: context.notificationContext).post()
    }

    public func addInitialSyncCompletionObserver(_ observer: ZMInitialSyncCompletionObserver) -> Any {
        return ZMUserSession.addInitialSyncCompletionObserver(observer, context: managedObjectContext)
    }

    @objc public static func addInitialSyncCompletionObserver(_ observer: ZMInitialSyncCompletionObserver, context: NSManagedObjectContext) -> Any {
        return NotificationInContext.addObserver(name: initialSyncCompletionNotificationName, context: context.notificationContext) { [weak observer] _ in
            context.performGroupedBlock {
                observer?.initialSyncCompleted()
            }
        }
    }

    @objc public static func addInitialSyncCompletionObserver(_ observer: ZMInitialSyncCompletionObserver, userSession: ZMUserSession) -> Any {
        return self.addInitialSyncCompletionObserver(observer, context: userSession.managedObjectContext)
    }
}

// MARK: - Network Availability

@objcMembers public class ZMNetworkAvailabilityChangeNotification: NSObject {

    private static let name = Notification.Name(rawValue: "ZMNetworkAvailabilityChangeNotification")

    private static let stateKey = "networkState"

    public static func addNetworkAvailabilityObserver(_ observer: ZMNetworkAvailabilityObserver, userSession: ZMUserSession) -> Any {
        return NotificationInContext.addObserver(name: name,
                                                 context: userSession) { [weak observer] note in
            observer?.didChangeAvailability(newState: note.userInfo[stateKey] as! ZMNetworkState)
        }
    }

    public static func notify(networkState: ZMNetworkState, userSession: ZMUserSession) {
        NotificationInContext(name: name, context: userSession, userInfo: [stateKey: networkState]).post()
    }

}

@objc public protocol ZMNetworkAvailabilityObserver: NSObjectProtocol {
    func didChangeAvailability(newState: ZMNetworkState)
}

// MARK: - Typing

private let typingNotificationUsersKey = "typingUsers"

extension ZMConversation {

    @objc
    public func addTypingObserver(_ observer: ZMTypingChangeObserver) -> Any {
        return NotificationInContext.addObserver(name: ZMConversation.typingNotificationName,
                                                 context: self.managedObjectContext!.notificationContext,
                                                 object: self) { [weak observer, weak self] note in
            guard let `self` = self else { return }

            let users = note.userInfo[typingNotificationUsersKey] as? Set<ZMUser> ?? Set()
            observer?.typingDidChange(conversation: self, typingUsers: Array(users))
        }
    }

    @objc
    func notifyTyping(typingUsers: Set<ZMUser>) {
        NotificationInContext(name: ZMConversation.typingNotificationName,
                              context: self.managedObjectContext!.notificationContext,
                              object: self,
                              userInfo: [typingNotificationUsersKey: typingUsers]).post()
    }
}

@objc public protocol ZMTypingChangeObserver: NSObjectProtocol {

    func typingDidChange(conversation: ZMConversation, typingUsers: [UserType])
}

// MARK: - Encryption at rest

public struct DatabaseEncryptionLockNotification: SelfPostingNotification {

    static var notificationName: Notification.Name = Notification.Name("DatabaseEncryptionLockNotification")

    var databaseIsEncrypted: Bool

}
