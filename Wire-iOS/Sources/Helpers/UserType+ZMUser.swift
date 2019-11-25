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

    func canManagedGroupRole(of user: UserType) -> Bool {
        guard isAdminGroup else { return false }
        
        return !user.isSelfUser &&
            (user.isConnected || /// in case not belongs to the same team
                isOnSameTeam(otherUser: user) /// in case in the same team
        )
    }

    var isAdminGroup: Bool {
        ///FIXME: for debug only, isAdminGroup should be determated by new API
        
        if isSelfUser {
            return true
        }
        
        switch teamRole {
        case .admin,
             .owner:
            return true
        default:
            return false
        }
    }
}
