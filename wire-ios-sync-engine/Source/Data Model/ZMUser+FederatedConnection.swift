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

extension UserType {

    /// Create fake one-to-one connection with a federated user.
    ///
    /// NOTE this is a temporary method for creating a conversation with federated users, it should
    /// be deleted before federation is launched.
    public func createFederatedOneToOne(in userSession: ZMUserSession) -> ZMConversation? {
        return materialize(in: userSession.viewContext)?.createFederatedOneToOne()
    }

}

extension ZMUser {

    /// Create fake one-to-one connection with a federated user.
    ///
    /// NOTE this is a temporary method for creating a conversation with federated users, it should
    /// be deleted before federation is launched.
    func createFederatedOneToOne() -> ZMConversation? {
        let selfUser = ZMUser.selfUser(in: managedObjectContext!)
        let otherUser = self
        let name = [otherUser.name ?? "-", selfUser.name ?? "-"].sorted().joined(separator: ", ")
        let conversation = ZMConversation.insertGroupConversation(moc: managedObjectContext!,
                                                                  participants: [selfUser, otherUser],
                                                                  name: name)

        return conversation
    }

}
