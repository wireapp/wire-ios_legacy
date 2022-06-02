//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

/// A type representing the possible timeout values.

public enum MessageDestructionTimeoutValue: RawRepresentable, Hashable {

    case none
    case tenSeconds
    case fiveMinutes
    case oneHour
    case oneDay
    case oneWeek
    case fourWeeks

    case custom(TimeInterval)

    public init(rawValue: TimeInterval) {
        switch rawValue {
        case .zero:
            self = .none

        case .tenSeconds:
            self = .tenSeconds

        case .fiveMinutes:
            self = .fiveMinutes

        case .oneHour:
            self = .oneHour

        case .oneDay:
            self = .oneDay

        case .oneWeek:
            self = .oneWeek

        case .fourWeeks:
            self = .fourWeeks

        default:
            self = .custom(rawValue)
        }
    }

    public var rawValue: TimeInterval {
        switch self {
        case .none:
            return .zero

        case .tenSeconds:
            return .tenSeconds

        case .fiveMinutes:
            return .fiveMinutes

        case .oneHour:
            return .oneHour

        case .oneDay:
            return .oneDay

        case .oneWeek:
            return .oneWeek

        case .fourWeeks:
            return .fourWeeks

        case let .custom(duration):
            return duration
        }
    }

}

public extension MessageDestructionTimeoutValue {

    static var all: [Self] {
        return [
            .none,
            .tenSeconds,
            .fiveMinutes,
            .oneHour,
            .oneDay,
            .oneWeek,
            .fourWeeks
        ]
    }

    var displayString: String? {
        guard .none != self else { return NSLocalizedString("input.ephemeral.timeout.none", comment: "") }
        return longStyleFormatter.string(from: TimeInterval(rawValue))
    }

    var shortDisplayString: String? {
        if isSeconds {
            return String(Int(rawValue))
        }

        if isMinutes {
            return String(Int(rawValue / .oneMinute))
        }

        if isHours {
            return String(Int(rawValue / .oneHour))
        }

        if isDays {
            return String(Int(rawValue / .oneDay))
        }

        if isWeeks {
            return String(Int(rawValue / .oneWeek))
        }

        if isYears {
            return String(Int(rawValue / .oneYearFromNow))
        }

        return nil
    }

    var isSeconds: Bool {
        return (.zero)..<(.oneMinute) ~= rawValue
    }

    var isMinutes: Bool {
        return (.oneMinute)..<(.oneHour) ~= rawValue
    }

    var isHours: Bool {
        return (.oneHour)..<(.oneDay) ~= rawValue
    }

    var isDays: Bool {
        return (.oneDay)..<(.oneWeek) ~= rawValue
    }

    var isWeeks: Bool {
        return (.oneWeek)..<(.oneYearFromNow) ~= rawValue
    }

    var isYears: Bool {
        return rawValue >= .oneYearFromNow
    }

}

private let longStyleFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.includesApproximationPhrase = false
    formatter.maximumUnitCount = 1
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.year, .weekOfMonth, .day, .hour, .minute, .second]
    formatter.zeroFormattingBehavior = .dropAll
    return formatter
}()

extension TimeInterval {

    static let tenSeconds: Self = 10
    static let oneMinute: Self = 60
    static let fiveMinutes: Self = 300
    static let oneHour: Self = 3600
    static let oneDay: Self = 86400
    static let oneWeek: Self = 604800
    static let fourWeeks: Self = 2419200

    // Calculate the interval to account for leap years.
    static var oneYearFromNow: Self {
        let now = Date()
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
        return oneYearFromNow.timeIntervalSince(now)
    }

}
