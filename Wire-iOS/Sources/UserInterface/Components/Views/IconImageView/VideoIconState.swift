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

enum VideoIconState: IconImageState {
    case video
    case screenshare
    case hidden
    
    var icon: StyleKitIcon? {
        switch self {
        case .hidden:
            return .none
        case .screenshare:
            return .alien
        case .video:
            return .videoCall
        }
    }
}

extension VideoIconState {
    init(_ state: WireSyncEngine.CallParticipantState) {
        switch state {
        case .connected(videoState: let videoState):
            switch videoState {
            case .screenSharing:
                self = .screenshare
            case .started, .paused, .badConnection:
                self = .video
            case .stopped:
                self = .hidden
            }
        default:
            self = .hidden
        }
    }
}
