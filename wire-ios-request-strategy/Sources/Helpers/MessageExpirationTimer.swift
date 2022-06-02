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

public class MessageExpirationTimer: ZMMessageTimer, ZMContextChangeTracker {

    let localNotificationsDispatcher: PushMessageHandler
    let entityNames: [String]
    let filter: NSPredicate?

    public override init() {
        fatalError("Should not use this init")
    }

    public init(moc: NSManagedObjectContext, entityNames: [String], localNotificationDispatcher: PushMessageHandler, filter: NSPredicate? = nil) {
        self.localNotificationsDispatcher = localNotificationDispatcher
        self.entityNames = entityNames
        self.filter = filter
        super.init(managedObjectContext: moc)
        self.timerCompletionBlock = { [weak self] message, _ in
            if let message = message {
                self?.timerFired(for: message)
            }
        }
    }

    private func timerFired(for message: ZMMessage) {
        guard message.deliveryState != .delivered && message.deliveryState != .sent && message.deliveryState != .read else {
                return
        }
        message.expire()
        message.managedObjectContext?.enqueueDelayedSave()
        self.localNotificationsDispatcher.didFailToSend(message)
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        return ZMMessage.sortedFetchRequest(with: ZMMessage.predicateForMessagesThatWillExpire())
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        self.startTimerIfNeeded(for: objects)
    }

    public func objectsDidChange(_ object: Set<NSManagedObject>) {
        self.startTimerIfNeeded(for: object)
    }

    private func startTimerIfNeeded(for objects: Set<AnyHashable>) {
        let now = Date()
        let messages = objects.compactMap { $0 as? ZMMessage }
        messages.forEach {
            guard self.entityNames.contains(type(of: $0).entityName()) else { return }

            if let filter = self.filter, !filter.evaluate(with: $0) {
                return
            }

            guard let expirationDate = $0.expirationDate else { return }
            if expirationDate.compare(now) == .orderedAscending {
                $0.expire()
                $0.managedObjectContext?.enqueueDelayedSave()
            } else {
                super.start(forMessageIfNeeded: $0, fire: expirationDate, userInfo: [:])
            }
        }
    }
}
