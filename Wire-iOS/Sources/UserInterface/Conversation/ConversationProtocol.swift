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
import WireDataModel

protocol InputBarConversation {
    var typingUsers: [UserType] { get }
    var hasDraftMessage: Bool { get }
    var draftMessage: DraftMessage? { get }

    var messageDestructionTimeoutValue: TimeInterval { get }
    var messageDestructionTimeout: MessageDestructionTimeout? { get }

    var conversationType: ZMConversationType { get }

    func setIsTyping(_ isTyping: Bool)

    var isReadOnly: Bool { get }
    var displayName: String { get }
}

protocol ConnectedUserContainer {
    var connectedUserType: UserType? { get }
}

typealias InputBarConversationType = InputBarConversation & ConnectedUserContainer

extension ZMConversation: ConnectedUserContainer {
    var connectedUserType: UserType? {
        return connectedUser
    }
}

extension ZMConversation: InputBarConversation {}
