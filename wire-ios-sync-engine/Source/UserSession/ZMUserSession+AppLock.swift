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

public protocol UserSessionAppLockInterface {

    var appLockController: AppLockType { get set }

    /// The current session lock, if any.

    var lock: SessionLock? { get }

}

public extension UserSessionAppLockInterface {

    /// Whether the session is currently locked.

    var isLocked: Bool {
        return lock != .none
    }

}

extension ZMUserSession: UserSessionAppLockInterface {

    public var lock: SessionLock? {
        if isDatabaseLocked {
            return .database
        } else if appLockController.isLocked {
            return .screen
        } else {
            return nil
        }
    }

}

/// The various types of session locks, i.e reasons why the session is inaccessible.

public enum SessionLock {

    /// The session is locked because the has been in the background for too long.

    case screen

    /// The session is locked because the database is locked and not accessible.

    case database

}

protocol UserSessionAppLockDelegate: AnyObject {

    func userSessionDidUnlock(_ session: ZMUserSession)

}

extension ZMUserSession: AppLockDelegate {

    public func appLockDidOpen(_ appLock: AppLockType) {
        delegate?.userSessionDidUnlock(self)
    }

}
