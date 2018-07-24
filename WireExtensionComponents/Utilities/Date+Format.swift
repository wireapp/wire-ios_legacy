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
import FormatterKit

// Creating and configuring date formatters is insanely expensive.
// This is why there’s a bunch of statically configured ones here that are reused.
public class WRDateFormatter {
    static let NSTimeIntervalOneHour = 3600.0
    static let DayMonthYearUnits = Set<Calendar.Component>([.day, .month, .year])
    static let WeekMonthYearUnits = Set<Calendar.Component>([.weekOfMonth, .month, .year])

    /// use this to format clock times, so they are correctly formatted to 12/24 hours according to locale
    static var clockTimeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        return timeFormatter
    }()

    static var timeIntervalFormatter: TTTTimeIntervalFormatter = {
        let locale = Locale.current
        let timeFormatter = TTTTimeIntervalFormatter()
        timeFormatter.presentTimeIntervalMargin = 60
        timeFormatter.locale = locale
        timeFormatter.usesApproximateQualifier = false
        timeFormatter.usesIdiomaticDeicticExpressions = true

        return timeFormatter
    }()

    static var todayYesterdayFormatter: DateFormatter = {
        let locale = Locale.current
        let timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.timeStyle = .short
        timeFormatter.doesRelativeDateFormatting = true

        return timeFormatter
    }()

    static var thisWeekFormatter: DateFormatter = {
        let locale = Locale.current
        let timeFormatter = DateFormatter()
        let formatString: String? = DateFormatter.dateFormat(fromTemplate: "EEEE", options: 0, locale: locale)
        timeFormatter.dateFormat = formatString ?? ""

        return timeFormatter
    }()

    public static var thisYearFormatter: DateFormatter = {
        let locale = Locale.current
        let formatString = DateFormatter.dateFormat(fromTemplate: "EEEEdMMMM", options: 0, locale: locale)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatString

        return dateFormatter
    }()

    public static var otherYearFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full

        return dateFormatter
    }()
}

extension Date {
    public var olderThanOneWeekdateFormatter: DateFormatter {
        let today = Date()

        let isThisYear = Calendar.current.isDate(self, equalTo: today, toGranularity: .year)

        if isThisYear {
            return WRDateFormatter.thisYearFormatter
        } else {
            return WRDateFormatter.otherYearFormatter
        }
    }

    public var formattedDate: String {
        let gregorian = Calendar(identifier: .gregorian)
        // Today's date
        let today = Date()
        let todayDateComponents: DateComponents? = gregorian.dateComponents(WRDateFormatter.DayMonthYearUnits, from: today)
        // Yesterday
        var componentsToSubtract = DateComponents()
        componentsToSubtract.day = -1

        let yesterday = gregorian.date(byAdding: componentsToSubtract, to: today)
        let yesterdayComponents: DateComponents? = gregorian.dateComponents(WRDateFormatter.DayMonthYearUnits, from: yesterday!)
        // This week
        let thisWeekComponents: DateComponents? = gregorian.dateComponents(WRDateFormatter.WeekMonthYearUnits, from: today)
        // Received date
        let dateComponents: DateComponents? = gregorian.dateComponents(WRDateFormatter.DayMonthYearUnits, from: self)
        let weekComponents: DateComponents? = gregorian.dateComponents(WRDateFormatter.WeekMonthYearUnits, from: self)

        let intervalSinceDate: TimeInterval = -timeIntervalSinceNow
        let isToday: Bool = todayDateComponents == dateComponents
        let isYesterday: Bool = yesterdayComponents == dateComponents
        let isThisWeek: Bool = thisWeekComponents == weekComponents
        var dateString = String()

        // Date is within the last hour
        if (intervalSinceDate < WRDateFormatter.NSTimeIntervalOneHour) {
            dateString = WRDateFormatter.timeIntervalFormatter.string(forTimeInterval: -intervalSinceDate)
        }
            // Date is from today or yesterday
        else if isToday || isYesterday {
            let dateStyle: DateFormatter.Style = isToday ? .none : .medium
            WRDateFormatter.todayYesterdayFormatter.dateStyle = dateStyle
            dateString = WRDateFormatter.todayYesterdayFormatter.string(from: self)
        } else if isThisWeek {
            dateString = "\(WRDateFormatter.thisWeekFormatter.string(from: self)) \(WRDateFormatter.clockTimeFormatter.string(from: self))"
        } else {
            let dateFormatter = self.olderThanOneWeekdateFormatter
            dateString = "\(dateFormatter.string(from: self)) \(WRDateFormatter.clockTimeFormatter.string(from: self))"
        }

        return dateString
    }
}

