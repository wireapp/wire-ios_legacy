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
import WireDataModel

extension UserChangeInfo {

    // MARK: - Registering an observer for a user

    /// Adds an observer for a user conforming to UserType. You must hold on to the token until you want to stop
    /// observing.
    ///
    public static func add(observer: ZMUserObserver, for user: UserType, in userSession: ZMUserSession) -> NSObjectProtocol? {
        return add(observer: observer, for: user, in: userSession.managedObjectContext)
    }

    // MARK: - Registering UserObservers

    /// Adds an observer for changes in all ZMUsers. You must hold on to the token until you want to stop observing.
    ///
    public static func add(userObserver observer: ZMUserObserver, in userSession: ZMUserSession) -> NSObjectProtocol {
        return add(userObserver: observer, in: userSession.managedObjectContext)
    }

    // MARK: - Registering SearchUserObservers

    /// Adds an observer for changes in all ZMSearchUsers. You must hold on to the token until you want to stop
    /// observing.
    ///
    public static func add(searchUserObserver observer: ZMUserObserver, in userSession: ZMUserSession) -> NSObjectProtocol {
        return add(searchUserObserver: observer, in: userSession.managedObjectContext)
    }

}
