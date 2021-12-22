////
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
import WireDataModel

fileprivate extension TimeInterval {
    var hours: Double {
        return self / 3600
    }

    var minutes: Double {
        return self / 60
    }
}

final class WirelessExpirationTimeFormatter {
    static let shared = WirelessExpirationTimeFormatter()
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    func string(for user: UserType) -> String? {
        return string(for: user.expiresAfter)
    }

    func string(for interval: TimeInterval) -> String? {
        guard interval > 0 else { return nil }
        let (hoursLeft, minutesLeft) = (interval.hours, interval.minutes)
        guard hoursLeft < 2 else { return localizedHours(floor(hoursLeft) + 1) }

        if hoursLeft > 1 {
            let extraMinutes = minutesLeft - 60
            return localizedHours(extraMinutes > 30 ? 2 : 1.5)
        }

        switch minutesLeft {
        case 45...Double.greatestFiniteMagnitude: return localizedHours(1)
        case 30..<45: return localizedMinutes(45)
        case 15..<30: return localizedMinutes(30)
        default: return localizedMinutes(15)
        }
    }

    private func localizedMinutes(_ minutes: Double) -> String {
        return "guest_room.expiration.less_than_minutes_left".localized(args: String(format: "%.0f", minutes))
    }

    private func localizedHours(_ hours: Double) -> String {
        let localizedHoursString = numberFormatter.string(from: NSNumber(value: hours)) ?? "\(hours)"
        return "guest_room.expiration.hours_left".localized(args: localizedHoursString)
    }
}

extension UserType {

    var expirationDisplayString: String? {
        return WirelessExpirationTimeFormatter.shared.string(for: self)
    }

}
