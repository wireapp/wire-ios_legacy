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

protocol SelfUserFromSession {
    static func selfUser(inUserSession session: ZMManagedObjectContextProvider?) -> ZMUser & ZMEditableUser
}

extension ZMUser {

    /// Return self's User object
    ///
    /// - Returns: a ZMUser<ZMEditableUser> object for app target, or a MockUser object for test.
    @objc
    static func selfUser() -> (ZMUser & ZMEditableUser)! {

        if let mockUserClass = NSClassFromString("MockUser") as? SelfUserFromSession.Type {
            return mockUserClass.selfUser(inUserSession: ZMUserSession.shared())
        } else {
            guard let session = ZMUserSession.shared() else { return nil }

            return ZMUser.selfUser(inUserSession: session)
        }
    }
}
