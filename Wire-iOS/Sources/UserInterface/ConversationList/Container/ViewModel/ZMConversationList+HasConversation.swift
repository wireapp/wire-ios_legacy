
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ZMConversationList {
    static var hasConversations: Bool {
        guard let session = ZMUserSession.shared() else { return false }

        let conversationsCount = ZMConversationList.conversations(inUserSession: session).count + ZMConversationList.pendingConnectionConversations(inUserSession: session).count
        return conversationsCount > 0
    }
}

extension ZMConversationList: ConversationListType {
    static var hasArchivedConversations: Bool {
        guard let session = ZMUserSession.shared() else { return false }

        return ZMConversationList.archivedConversations(inUserSession: session).count > 0
    }
}

protocol ConversationListType {
    static var hasArchivedConversations: Bool { get }
    static func archivedConversations(inUserSession session: ZMManagedObjectContextProvider) -> ZMConversationList
    static func clearedConversations(inUserSession session: ZMManagedObjectContextProvider) -> ZMConversationList
}
