//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

private class Box<T> {
    let f: T
    init (_ f: T) { self.f = f }
}

extension Timer {

    /// ScheduledTimer with block for iOS10+ and iOS9.
    ///
    /// - Parameters:
    ///   - withTimeInterval: The number of seconds between firings of the timer. If seconds is less than or equal to 0.0, this method chooses the nonnegative value of 0.1 milliseconds instead
    ///   - repeats: repeats  If YES, the timer will repeatedly reschedule itself until invalidated. If NO, the timer will be invalidated after it fires.
    ///   - block: The execution body of the timer; the timer itself is passed as the parameter to this block when executed to aid in avoiding cyclical references
    /// - Returns: a new NSTimer object initialized with the specified block object and schedules it on the current run loop in the default mode.
    static func allVersionCompatibleScheduledTimer(withTimeInterval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        if #available(iOS 10.0, *) {
            return .scheduledTimer(withTimeInterval: withTimeInterval, repeats: true,
                                   block: block)
        } else {
            return .iOS9ScheduledTimer(withTimeInterval: withTimeInterval, repeats: true, block: block)
        }
    }

    fileprivate static func iOS9ScheduledTimer(withTimeInterval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        return self.scheduledTimer(timeInterval: withTimeInterval, target:
            self, selector: #selector(timerBlockInvoke), userInfo: Box(block), repeats: repeats)
    }

    @objc fileprivate static func timerBlockInvoke(timer: Timer) {
        if let box = timer.userInfo as? Box<(Timer) -> Void> {
            box.f(timer)
        }
    }
}

