
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

protocol ConversationInterface: class {
    var conversationType: ZMConversationType { get }
    var teamRemoteIdentifier: UUID? { get set }
    var connectedUser: ZMUser? { get }
    var displayName: String { get }
    var isArchived: Bool { get set }
    var isReadOnly: Bool { get }
    var isFavorite: Bool { get }
    var mutedMessageTypes: MutedMessageTypes { get set }
    var activeParticipants: Set<ZMUser> { get }
    var folderName: String? { get }
    var unreadMessages: [ZMConversationMessage] { get }

    func canMarkAsUnread() -> Bool
}

extension ZMConversation: ConversationInterface {}
