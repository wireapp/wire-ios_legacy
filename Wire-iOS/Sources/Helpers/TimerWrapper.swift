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


private class Block<T> {
    let f : T
    init (_ f: T) { self.f = f }
}

extension Timer {
    static func scheduledTimer(withTimeInterval: TimeInterval, repeats: Bool, callback: (Timer) -> Void) -> Timer {
        return self.scheduledTimer(timeInterval: withTimeInterval, target:
            self, selector: #selector(timerBlcokInvoke), userInfo: Block(callback), repeats: repeats)
    }

    static func timerBlcokInvoke(timer: Timer) {
        if let block = timer.userInfo as? Block<(Timer) -> Void> {
            block.f(timer)
        }
    }
}
