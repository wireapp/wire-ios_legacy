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

    func string(from interval: TimeInterval) -> String? {
        return timeString(from: interval).map {
            "content.system.ephemeral_time_remaining".localized(args: $0)
        }
    }

    private func timeString(from interval: TimeInterval) -> String? {
        switch interval {
        case 0..<60: return secondsFormatter.string(from: interval)
        case 60..<3600: return minuteFormatter.string(from: interval)
        default: return hourFormatter.string(from: interval)
        }
    }
    
}
