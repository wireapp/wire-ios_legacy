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
    public var zmUser: ZMUser? {
        if let searchUser = self as? ZMSearchUser {
            return searchUser.user
        } else if let zmUser = self as? ZMUser {
            return zmUser
        } else {
            return nil
        }
    }

    /// The accent color of the user, if one is available.
    var indexedAccentColor: UIColor {
        return (self as? AccentColorProvider)?.accentColor ?? .defaultAccent
    }

}
