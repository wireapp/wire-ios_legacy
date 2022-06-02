//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

@objc public extension ZMConversation {

    @objc (setIsTyping:)
    func setIsTyping(_ isTyping: Bool) {
        TypingStrategy.notifyTranscoderThatUser(isTyping: isTyping, in: self)
    }

    var typingUsers: [UserType] {
        guard let users = managedObjectContext?.typingUsers?.typingUsers(in: self) else { return [] }
        return Array(users)
    }

    /// Strictly for UI tests. Remove once mockable conversation abstraction exists.
    func setTypingUsers(_ users: [UserType]) {
        guard let typingUsers = managedObjectContext?.typingUsers else { return }
        let zmUsers = users.compactMap { $0 as? ZMUser }
        typingUsers.update(typingUsers: Set(zmUsers), in: self)
    }
}
