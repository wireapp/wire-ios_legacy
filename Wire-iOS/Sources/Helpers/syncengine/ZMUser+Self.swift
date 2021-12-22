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
import WireSyncEngine

#if targetEnvironment(simulator)
typealias EditableUser = ZMUser & ZMEditableUser

protocol SelfUserProviderUI {
    static var selfUser: EditableUser { get }
}

extension ZMUser {

    /// Return self's User object
    /// Notice: This should be replaced with SelfUser.current
    ///
    /// - Returns: a ZMUser<ZMEditableUser> object for app target, or a MockUser object for test.
    static func selfUser() -> EditableUser! {

        if let mockUserClass = NSClassFromString("MockUser") as? SelfUserProviderUI.Type {
            return mockUserClass.selfUser
        } else {
            guard let session = ZMUserSession.shared() else { return nil }

            return ZMUser.selfUser(inUserSession: session)
        }
    }
}
#else
extension ZMUser {

    /// Return self's User object
    ///
    /// - Returns: a ZMUser object for app target
    static func selfUser() -> ZMUser! {
        guard let session = ZMUserSession.shared() else { return nil }

        return ZMUser.selfUser(inUserSession: session)
    }
}
#endif
