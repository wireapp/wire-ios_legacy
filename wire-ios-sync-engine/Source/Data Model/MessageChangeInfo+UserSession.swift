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

import WireDataModel

extension MessageChangeInfo {

    /// Adds a ZMMessageObserver to the specified message
    /// To observe messages and their users (senders, systemMessage users), observe the conversation window instead
    /// Messages observed with this call will not contain information about user changes
    /// You must hold on to the token and use it to unregister
    public static func add(observer: ZMMessageObserver,
                           for message: ZMConversationMessage,
                           userSession: ZMUserSession) -> NSObjectProtocol {
        return self.add(observer: observer, for: message, managedObjectContext: userSession.managedObjectContext)
    }
}

extension NewUnreadMessagesChangeInfo {

    /// Adds a ZMNewUnreadMessagesObserver
    /// You must hold on to the token and use it to unregister
    public static func add(observer: ZMNewUnreadMessagesObserver, for userSession: ZMUserSession) -> NSObjectProtocol {
        return self.add(observer: observer, managedObjectContext: userSession.managedObjectContext)
    }

}

extension NewUnreadKnockMessagesChangeInfo {
    /// Adds a ZMNewUnreadKnocksObserver
    /// You must hold on to the token and use it to unregister
    public static func add(observer: ZMNewUnreadKnocksObserver, for userSession: ZMUserSession) -> NSObjectProtocol {
        return self.add(observer: observer, managedObjectContext: userSession.managedObjectContext)
    }

}
