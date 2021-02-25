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
import WireCommonComponents
import WireDataModel

enum AvailabilityLabelStyle: Int {
    case list, participants, placeholder
}

extension Availability {
    var canonicalName: String {
        switch self {
            case .none:         return "none"
            case .available:    return "available"
            case .away:         return "away"
            case .busy:         return "busy"
        }
    }

    var localizedName: String {
        return "availability.\(canonicalName)".localized
    }

    var iconType: StyleKitIcon? {
        switch self {
            case .none:         return nil
            case .available:    return .statusAvailable
            case .away:         return .statusAway
            case .busy:         return .statusBusy
        }
    }
}
