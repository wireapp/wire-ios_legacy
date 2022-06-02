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

// MARK: - Calling

extension ZMLocalNotification {

    convenience init?(callState: CallState, conversation: ZMConversation, caller: ZMUser, moc: NSManagedObjectContext) {
        guard let builder = CallNotificationBuilder(callState: callState, caller: caller, conversation: conversation) else { return nil }
        self.init(builder: builder, moc: moc)
    }

    private class CallNotificationBuilder: NotificationBuilder {

        let callState: LocalNotificationType.CallState
        let caller: ZMUser
        let conversation: ZMConversation
        let managedObjectContext: NSManagedObjectContext

        var notificationType: LocalNotificationType {
            return .calling(callState)
        }

        init?(callState: CallState, caller: ZMUser, conversation: ZMConversation) {
            guard
                let managedObjectContext = conversation.managedObjectContext,
                conversation.remoteIdentifier != nil
            else {
                return nil
            }

            switch callState {
            case .incoming(let video, shouldRing: true, degraded: _):
                self.callState = .incomingCall(video: video)
            case .terminating(reason: .anweredElsewhere), .terminating(reason: .normal), .terminating(reason: .rejectedElsewhere):
                return nil
            case .terminating(reason: .timeout):
                self.callState = .missedCall(cancelled: false)
            case .terminating(reason: .canceled):
                self.callState = .missedCall(cancelled: true)
            default:
                return nil
            }

            self.caller = caller
            self.conversation = conversation
            self.managedObjectContext = managedObjectContext
        }

        func shouldCreateNotification() -> Bool {
            guard conversation.mutedMessageTypesIncludingAvailability != .all else { return false }
            return true
        }

        func titleText() -> String? {
            return notificationType.titleText(selfUser: ZMUser.selfUser(in: managedObjectContext), conversation: conversation)
        }

        func bodyText() -> String {
            return notificationType.messageBodyText(sender: caller, conversation: conversation)
        }

        func userInfo() -> NotificationUserInfo? {
            let selfUser = ZMUser.selfUser(in: managedObjectContext)

            guard let selfUserID = selfUser.remoteIdentifier,
                  let senderID = caller.remoteIdentifier,
                  let conversationID = conversation.remoteIdentifier
                  else { return nil }

            let userInfo = NotificationUserInfo()
            userInfo.selfUserID = selfUserID
            userInfo.senderID = senderID
            userInfo.conversationID = conversationID
            userInfo.conversationName = conversation.meaningfulDisplayName
            userInfo.teamName = selfUser.team?.name

            return userInfo
        }
    }
}
