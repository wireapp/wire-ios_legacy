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

import Foundation

/**
 * A protocol for session managers that provides a mechanism to observe user
 * session creation.
 */

protocol ObservableSessionManager: SessionManagerType {

    /**
     * Registers an observer to monitor user session creation.
     *
     * - parameter observer: The object that is subscribing to notifications.
     * - returns: A token object that holds a reference to the observer. Keep a strong
     * reference to this object as long as the observer is allocated. You should discard it
     * when the observer is deallocated to remove the observer,
     */

    func addSessionManagerCreatedSessionObserver(_ observer: SessionManagerCreatedSessionObserver) -> Any

}

extension SessionManager: ObservableSessionManager {}
