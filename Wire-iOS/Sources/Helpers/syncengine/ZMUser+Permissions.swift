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
        return selfUserHas(permissions: .owner)
    }
    
    /// Returns true if the self user has admin permissions.
    static func selfIsAdmin() -> Bool {
        return selfUserHas(permissions: .admin)
    }
    
    /// Returns true if the self user has member permissions.
    static func selfIsMember() -> Bool {
        return selfUserHas(permissions: .member)
    }
    
    // TODO: selfIsPartner()
    
    /// Returns true if the self user's permissions encompass the given
    /// permissions.
    static func selfUserHas(permissions: Permissions) -> Bool {
        guard let selfPermissions = selfPermissions() else { return false }
        return selfPermissions.isSuperset(of: permissions)
    }

}

/// Conform to this protocol to mark an object as being restricted. This
/// indicates that the self user permissions need to be checked in order
/// to use the object. By defining `requiredPermissions`, the rest of the
/// protocol is implemented for free. For example, by marking a button as
/// restricted to admins only, we can check hide the button if the self
/// user is not authorized (is not an admin).
///
protocol Restricted {
    
    /// The minimum permissions required to access this object.
    var requiredPermissions: Permissions { get }
    
    /// Returns true if the self user has the required permissions.
    var selfUserIsAuthorized: Bool { get }
    
    /// Invokes the given callback if the self user is authorized.
    func authorizeSelfUser(onSuccess: () -> Void)
}

extension Restricted {
    
    var selfUserIsAuthorized: Bool {
        return ZMUser.selfUserHas(permissions: self.requiredPermissions)
    }
    
    func authorizeSelfUser(onSuccess: () -> Void) {
        if selfUserIsAuthorized { onSuccess() }
    }
}
