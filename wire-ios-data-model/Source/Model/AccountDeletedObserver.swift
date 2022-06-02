//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

public protocol AccountDeletedObserver: AnyObject {
    func accountDeleted(accountId: UUID)
}

public struct AccountDeletedNotification {
    public static let notificationName = Notification.Name("AccountDeletedNotification")
    public static var userInfoKey: String { return notificationName.rawValue }

    weak var context: NSManagedObjectContext?

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func post(in context: NotificationContext, object: AnyObject? = nil) {
        NotificationInContext(name: type(of: self).notificationName, context: context, object: object, userInfo: [type(of: self).userInfoKey: self]).post()
    }
}

extension AccountDeletedNotification {
    public static func addObserver(observer: AccountDeletedObserver,
                                   context: NSManagedObjectContext? = nil,
                                   queue: ZMSGroupQueue) -> Any {
        return NotificationInContext.addUnboundedObserver(name: AccountDeletedNotification.notificationName,
                                                          context: context?.notificationContext,
                                                          object: nil,
                                                          queue: .main) { [weak observer] note in
            guard
                let note = note.userInfo[AccountDeletedNotification.userInfoKey] as? AccountDeletedNotification,
                let context = note.context,
                let observer = observer
            else {
                return
            }
            context.performGroupedBlock {
                guard let accountID = ZMUser.selfUser(in: context).remoteIdentifier else {
                    return
                }

                queue.performGroupedBlock {
                    observer.accountDeleted(accountId: accountID)
                }
            }
        }
    }
}
