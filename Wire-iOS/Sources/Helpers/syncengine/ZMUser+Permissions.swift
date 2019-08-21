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

    /// Returns the permissions of the self user, if any.
    static func selfPermissions() -> Permissions? {
        return ZMUser.selfUser()?.teamRole.permissions
    }

    /// Returns true if the self user's team role encompasses the given
    /// permissions.
    static func selfUserHas(permissions: Permissions) -> Bool {
        guard let user = ZMUser.selfUser() else { return false }
        return user.has(permissions: permissions)
    }

    static var selfUserIsTeamMember: Bool {
        return selfUser()?.isTeamMember ?? false
    }

}

extension UserType {

    var permissions: Permissions {
        return teamRole.permissions
    }

    /// Returns true if the user's team role encompasses the given permissions.
    func has(permissions: Permissions) -> Bool {
        return teamRole.hasPermissions(permissions)
    }
    
}

/// Conform to this protocol to mark an object as being restricted. This
/// indicates that the self user permissions need to be checked in order
/// to use the object. By defining `requiredPermissions`, the rest of the
/// protocol is implemented for free. For example, by marking a button as
/// restricted to admins only, we can check hide the button if the self
/// user is not authorized (is not an admin).
///
/// NOTE: This relates only to team members. If the self user is not a
/// team member, they are automatically authorized.
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
        guard ZMUser.selfUserIsTeamMember else { return true }
        return ZMUser.selfUserHas(permissions: requiredPermissions)
    }
    
    func authorizeSelfUser(onSuccess: () -> Void) {
        if selfUserIsAuthorized { onSuccess() }
    }
}

extension Restricted where Self: UIButton {
    var shouldHide: Bool {
        return !selfUserIsAuthorized
    }

    func updateHidden() {
        if shouldHide {
            isHidden = true
        }
    }
}
