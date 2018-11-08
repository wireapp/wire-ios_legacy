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

extension Date {

    static func today(at hour: Int, _ minutes: Int) -> Date {
        let today = Date()
        let calendar = Calendar.current

        var components = calendar.dateComponents([.era, .year, .month, .day], from: today)
        components.setValue(hour, for: .hour)
        components.setValue(minutes, for: .minute)
        components.setValue(0, for: .second)

        return calendar.date(from: components)!
    }
    
    /// Return first day of the current year at 8am
    ///
    /// - Returns: a Date at ThisYear/1/1 8am
    func startOfYear() -> Date {
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: self)
        components.month = 1
        components.day = 1
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components)!
    }
}
