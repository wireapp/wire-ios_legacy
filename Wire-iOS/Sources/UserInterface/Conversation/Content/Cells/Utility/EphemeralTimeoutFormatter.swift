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


class EphemeralTimeoutFormatter {


    /// A formatter to produce a string with day in full style and hour/minute in positional style
    fileprivate class DayFormatter {

        /// hour formatter with no second unit
        private let hourFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.zeroFormattingBehavior = .pad
            return formatter
        }()

        private let dayFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .full
            formatter.allowedUnits = [.year, .weekOfMonth, .day]
            formatter.zeroFormattingBehavior = .dropAll
            return formatter
        }()


        /// return a string with day in full style and hour/minute in positional style e.g. 27 days 23:43 left
        ///
        /// - Parameter timeInterval: timeInterval to convert
        /// - Returns: formatted string
        open func string(from interval: TimeInterval) -> String? {

            guard let dayString = dayFormatter.string(from: interval),
                let hourString = hourFormatter.string(from: interval) else {
                    return nil
            }

            guard !hourString.hasSuffix("0:00") else { return dayString }

            var hourStringWithoutDay = ""

            // remove the day of hourString
            do {
                let regex = try NSRegularExpression(pattern: "[0-9]+.+ ")
                let results = regex.matches(in: hourString, options: [], range: NSRange(location: 0, length: hourString.count))

                if results.count > 0 {
                    let startIndex = hourString.index(hourString.startIndex, offsetBy: results[0].range.length)

                    hourStringWithoutDay = String(hourString[startIndex...])
                } else {
                    hourStringWithoutDay = hourString
                }
            } catch {
            }

            if hourStringWithoutDay.count > 0 {
                return dayString + " ".localized + hourStringWithoutDay
            } else {
                return dayString
            }
        }
    }

    private let secondsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = .second
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    private let minuteFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private let hourFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private let dayFormatter = DayFormatter()

    func string(from interval: TimeInterval) -> String? {
        return timeString(from: interval).map {
            "content.system.ephemeral_time_remaining".localized(args: $0)
        }
    }

    private func timeString(from interval: TimeInterval) -> String? {
        let now = Date()
        let date = Date(timeIntervalSinceNow: interval)

        if date < Calendar.current.date(byAdding: .minute, value: 1, to: now) {
            return secondsFormatter.string(from: interval)
        } else if date < Calendar.current.date(byAdding: .hour, value: 1, to: now) {
            return minuteFormatter.string(from: interval)
        } else if date < Calendar.current.date(byAdding: .day, value: 1, to: now) {
            return hourFormatter.string(from: interval)
        } else {
            // clamp time interval longer than 1 year
            let oneYearFormNow = Calendar.current.date(byAdding: .year, value: 1, to: now)
            if date > oneYearFormNow {
                return dayFormatter.string(from: (oneYearFormNow?.timeIntervalSince(now))!)
            } else {
                return dayFormatter.string(from: interval)
            }
        }
    }
    
}
