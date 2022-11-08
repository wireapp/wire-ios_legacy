//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel
import WireRequestStrategy

protocol NotificationContentProviderProtocol {
    func notificationContent(fromEvent event: ZMUpdateEvent) throws -> UNNotificationContent
}

class NotificationContentProvider: NotificationContentProviderProtocol {
    private let managedObjectContext: NSManagedObjectContext

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    func notificationContent(fromEvent event: ZMUpdateEvent) throws -> UNNotificationContent {
        guard let conversationID = event.conversationUUID else {
            throw NotificationServiceError.missingConversation
        }

        let conversation = ZMConversation.fetch(with: conversationID, domain: event.conversationDomain, in: managedObjectContext)
        guard let notification = ZMLocalNotification.init(event: event, conversation: conversation, managedObjectContext: managedObjectContext) else {
            throw NotificationServiceError.noDecryptedEvent
        }
        return notification.content
    }

}
