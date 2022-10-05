//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireSyncEngine

enum VideoIconStyle: String, IconImageStyle {
    case video
    case screenshare
    case hidden

    var icon: StyleKitIcon? {
        switch self {
        case .hidden:
            return .none
        case .screenshare:
            return .screenshare
        case .video:
            return .camera
        }
    }

    var accessibilitySuffix: String {
        return rawValue
    }

    var accessibilityLabel: String {
        return rawValue
    }
}

extension VideoIconStyle {
    init(state: VideoState?) {
        guard let state = state else {
            self = .hidden
            return
        }
        switch state {
        case .screenSharing:
            self = .screenshare
        case .started, .paused, .badConnection:
            self = .video
        case .stopped:
            self = .hidden
        }
    }
}
