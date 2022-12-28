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

enum MicrophoneIconStyle: String {
    case muted
    case unmuted
    case unmutedPulsing
    case hidden
}

extension MicrophoneIconStyle: IconImageStyle {
    var icon: StyleKitIcon? {
        switch self {
        case .muted:
            return .microphoneOff
        case .unmuted, .unmutedPulsing:
            return .microphone
        case .hidden:
            return .none
        }
    }

    var tintColor: UIColor? {
        switch self {
        case .unmutedPulsing:
            return .accent()
        default:
            return nil
        }
    }

    var accessibilityPrefix: String {
        return "img.microphone"
    }

    var accessibilitySuffix: String {
        return rawValue
    }

    var accessibilityLabel: String {
        return rawValue
    }
}

extension MicrophoneIconStyle: PulsingIconImageStyle {
    var shouldPulse: Bool { return self == .unmutedPulsing }
}

extension MicrophoneIconStyle {
    init(state: MicrophoneState?, shouldPulse: Bool) {
        guard let state = state else {
            self = .hidden
            return
        }
        switch state {
        case .unmuted where shouldPulse:
            self = .unmutedPulsing
        case .unmuted:
            self = .unmuted
        case .muted:
            self = .muted
        }
    }
}
