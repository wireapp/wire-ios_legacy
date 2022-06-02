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

// MARK: - Failed Messages

extension ZMLocalNotification {

    convenience init?(expiredMessage: ZMMessage, moc: NSManagedObjectContext) {
        guard let conversation = expiredMessage.conversation else { return nil }
        self.init(expiredMessageIn: conversation, moc: moc)
    }

    convenience init?(expiredMessageIn conversation: ZMConversation, moc: NSManagedObjectContext) {
        guard let builder = FailedMessageNotificationBuilder(conversation: conversation) else { return nil }
        self.init(builder: builder, moc: moc)
    }

    private class FailedMessageNotificationBuilder: NotificationBuilder {

        fileprivate let conversation: ZMConversation
        fileprivate let managedObjectContext: NSManagedObjectContext

        var notificationType: LocalNotificationType {
            return LocalNotificationType.failedMessage
        }

        init?(conversation: ZMConversation?) {
            guard let conversation = conversation, let managedObjectContext = conversation.managedObjectContext else { return nil }

            self.conversation = conversation
            self.managedObjectContext = managedObjectContext
        }

        func shouldCreateNotification() -> Bool {
            return true
        }

        func titleText() -> String? {
            return notificationType.titleText(selfUser: ZMUser.selfUser(in: managedObjectContext), conversation: conversation)
        }

        func bodyText() -> String {
            return notificationType.messageBodyText(sender: ZMUser.selfUser(in: managedObjectContext), conversation: conversation)
        }

        func userInfo() -> NotificationUserInfo? {
            let selfUser = ZMUser.selfUser(in: managedObjectContext)

            guard let selfUserID = selfUser.remoteIdentifier,
                  let conversationID = conversation.remoteIdentifier else { return nil }

            let userInfo = NotificationUserInfo()
            userInfo.selfUserID = selfUserID
            userInfo.conversationID = conversationID
            userInfo.conversationName = conversation.meaningfulDisplayName
            userInfo.teamName = selfUser.team?.name

            return userInfo
        }
    }
}
