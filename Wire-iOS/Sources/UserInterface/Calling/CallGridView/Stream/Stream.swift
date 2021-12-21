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
import WireSyncEngine
import DifferenceKit

struct Stream: Equatable {

    let streamId: AVSClient
    let user: UserType?
    let microphoneState: MicrophoneState?
    let videoState: VideoState?
    let activeSpeakerState: ActiveSpeakerState
    let isPaused: Bool

}

extension Stream: Differentiable {
    var differenceIdentifier: AVSClient {
        return streamId
    }
}

extension Stream {
    static func == (lhs: Stream, rhs: Stream) -> Bool {
        return lhs.streamId == rhs.streamId
            && lhs.microphoneState == rhs.microphoneState
            && lhs.videoState == rhs.videoState
            && lhs.activeSpeakerState == rhs.activeSpeakerState
    }
}
