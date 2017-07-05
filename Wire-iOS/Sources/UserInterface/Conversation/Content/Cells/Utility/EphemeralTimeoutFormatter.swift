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

    private let secondsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = .second
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    func string(from interval: TimeInterval) -> String? {
        return timeString(from: interval).map {
            "content.system.ephemeral_time_remaining".localized(args: $0)
        }
    }

    private func timeString(from interval: TimeInterval) -> String? {
        // DateComponentsFormatter ZeroFormattingBehavior.pad unfortunately does
        // not add a leading 0 to the first unit (e.g. 5:21 instead of 05:21), which
        // is the reason we need to fallback to manual formatting here.
        let (hour, min, sec) = interval.decomposed()
        if interval < 60 {
            return secondsFormatter.string(from: interval + 1) // We need to add one second to start with the correct value
        } else if interval < 3600 {
            return String(format: "%02u:%02u", min, sec)
        } else {
            return String(format: "%02u:%02u:%02u", hour, min, sec)
        }
    }
    
}

fileprivate extension TimeInterval {

    func decomposed() -> (hour: Int, min: Int, sec: Int) {
        let total = Int(rounded())
        return (total / 3600, (total / 60) % 60, total % 60)
    }

}
