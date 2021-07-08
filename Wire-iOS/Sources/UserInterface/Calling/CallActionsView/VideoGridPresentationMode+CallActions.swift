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
import WireSyncEngine

extension VideoGridPresentationMode {
    var title: String {
        switch self {
        case .activeSpeakers:
            return "call.overlay.switch_to.speakers".localized
        case .allVideoStreams:
            return "call.overlay.switch_to.all".localized
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .activeSpeakers:
            return "speakers"
        case .allVideoStreams:
            return "all"
        }
    }

    var index: Int {
        Self.allCases.firstIndex(of: self)!
    }
}
