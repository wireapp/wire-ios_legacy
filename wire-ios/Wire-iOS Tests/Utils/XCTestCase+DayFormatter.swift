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

import XCTest
@testable import Wire

extension Message {
    static func dayFormatter(date: Date) -> DateFormatter {
        return date.olderThanOneWeekdateFormatter
    }
}

extension XCTestCase {
    /// change the locale of the DateFormatter for snapshot
    /// Notice: this method changes WRDateFormatter's static formatters, call resetDayFormatter in tearDown() to reset the changes
    ///
    /// - Parameters:
    ///   - identifier: locale identifier
    ///   - date: date to determine in with or without yera component
    func setDayFormatterLocale(identifier: String, date: Date) {
        let dayFormatter = Message.dayFormatter(date: date)

        /// overwrite dayFormatter's locale and update the date format string
        let locale = Locale(identifier: identifier)
        let formatString = DateFormatter.dateFormat(fromTemplate: dayFormatter.dateFormat, options: 0, locale: locale)

        dayFormatter.dateFormat = formatString
    }

    class func resetDayFormatter() {
        let locale = Locale(identifier: "en_US")
        WRDateFormatter.thisYearFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEEdMMMM", options: 0, locale: locale)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full

        WRDateFormatter.otherYearFormatter = dateFormatter
    }
}
