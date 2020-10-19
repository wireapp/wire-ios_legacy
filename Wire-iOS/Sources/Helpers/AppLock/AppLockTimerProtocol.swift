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
import WireCommonComponents

protocol AppLockTimerProtocol {
    var shouldLockScreen: Bool { get }
}

final class  AppLockTimer : AppLockTimerProtocol {
    
    var shouldLockScreen: Bool {
        let screenLockIsActive = AppLock.isActive && isLockTimeoutReached
        
        return screenLockIsActive
    }
    
    private var isLockTimeoutReached: Bool {
        let lastAuthDate = AppLock.lastUnlockedDate
        
        // The app was authenticated at least N seconds ago
        let timeSinceAuth = -lastAuthDate.timeIntervalSinceNow
        let isWithinTimeoutWindow = (0..<Double(AppLock.rules.appLockTimeout)).contains(timeSinceAuth)
        return !isWithinTimeoutWindow
    }
}
