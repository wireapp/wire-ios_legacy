//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import WireSyncEngine

extension UserType {

    /// Return the ZMUser associated with the generic user, if available.
    var zmUser: ZMUser? {
        if let searchUser = self as? ZMSearchUser {
            return searchUser.user
        } else if let zmUser = self as? ZMUser {
            return zmUser
        } else {
            return nil
        }
    }

    func canManagedGroupRole(of user: UserType, conversation: ZMConversation?) -> Bool {
        guard isAdminGroup(conversation: conversation) else { return false }
        
        return !user.isSelfUser &&
            (user.isConnected || /// in case not belongs to the same team
                isOnSameTeam(otherUser: user) /// in case in the same team
        )
    }

    ///TODO: mv to data model
    func isAdminGroup(conversation: ZMConversation?) -> Bool {
        let roleName = zmUser?.participantRoles.first(where: { $0.conversation == conversation })?.role?.name
        return roleName == ZMConversation.defaultAdminRoleName
    }

    ///TODO: mv to data model
    func participantRole(in conversation: ZMConversation?) -> ParticipantRole? {
        return zmUser?.participantRoles.first(where: { $0.conversation == conversation })
    }

    ///TODO: mv to data model
    func role(in conversation: ZMConversation?) -> Role? {
        return participantRole(in: conversation)?.role
    }

    var isExternalPartner: Bool {
        return teamRole == .partner
    }
}

