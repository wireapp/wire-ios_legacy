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
@testable import Wire

class VideoStreamStubProvider {
    func videoStream(
        participantName: String = "Bob",
        client: AVSClient = AVSClient(userId: UUID(), clientId: UUID().transportString()),
        muted: Bool = false,
        videoState: VideoState = .started,
        active: Bool = false,
        paused: Bool = false) -> VideoStream
    {        
        let stream = Wire.Stream(
            streamId: client,
            participantName: participantName,
            microphoneState: muted ? .muted : .unmuted,
            videoState: videoState,
            isParticipantActiveSpeaker: active
        )
        return VideoStream(stream: stream, isPaused: paused)
    }
}
