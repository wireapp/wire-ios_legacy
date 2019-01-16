//
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

extension ZMUser {
    
    // TODO: needs testing
    
    /// Returns the permission of the self user, if any.
    static func selfPermissions() -> Permissions? {
        return ZMUser.selfUser()?.permissions
    }
    
    /// Returns true if the self user has owner permissions.
    static func selfIsOwner() -> Bool {
        return selfIs(role: .owner)
    }
    
    /// Returns true if the self user has admin permissions.
    static func selfIsAdmin() -> Bool {
        return selfIs(role: .admin)
    }
    
    /// Returns true if the self user has member permissions.
    static func selfIsMember() -> Bool {
        return selfIs(role: .member)
    }
    
    // TODO: selfIsCollaborator()
    
    /// Returns true if the self user's permission are encompassed by
    /// the given role. Eg. An Owner is also a Member, but a Member is not
    /// an owner.
    private static func selfIs(role: Permissions) -> Bool {
        guard let permissions = selfPermissions() else { return false }
        return role.isSubset(of: permissions)
    }

}
