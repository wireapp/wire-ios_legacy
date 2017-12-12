//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

    public func wr_formattedDate() -> String {
        return (self as NSDate).wr_formattedDate()
    }

    /// Create a NSDateFormatter depends on the date is in this year or not
    ///
    /// - Parameter locale: this parameter is for Unit tests
    /// - Returns: a NSDateFormatter object. If the date's year is same as today,
    ///            return a NSDateFormatter without year component, otherwise return a NSDateFormatter with year component.
    public func localizedDateFormatter() -> DateFormatter {
        let locale = Locale.current
        let today = Date()
        let isThisYear = Calendar.current.isDate(self, equalTo: today, toGranularity: .year)

        var formatString: String?

        /// The order of the components in fromTemplate do not affect the output of DateFormatter.dateFormat()
        if isThisYear {
            formatString = DateFormatter.dateFormat(fromTemplate: "EEEEdMMMM", options: 0, locale: locale)
        } else {
            formatString = DateFormatter.dateFormat(fromTemplate: "EEEEdMMMMYYYY", options: 0, locale: locale)
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatString
        return dateFormatter
    }
}

