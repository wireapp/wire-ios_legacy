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

public enum CallParticipantsListKind {

    /// All the active participants, including the real time active speakers

    case all

    /// Only the smoothed active speakers

    case smoothedActiveSpeakers

}

extension CallParticipantsListKind {

    func state(ofActiveSpeaker activeSpeaker: AVSActiveSpeakersChange.ActiveSpeaker) -> ActiveSpeakerState {
        switch self {
        case .all where activeSpeaker.audioLevelNow > 0,
             .smoothedActiveSpeakers where activeSpeaker.audioLevel > 0:
            return .active(audioLevelNow: activeSpeaker.audioLevelNow)
        default:
            return .inactive
        }
    }

}
