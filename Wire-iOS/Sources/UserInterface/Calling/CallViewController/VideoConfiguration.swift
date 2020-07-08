//
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

import WireSyncEngine

struct VideoConfiguration: VideoGridConfiguration {
    let floatingVideoStream: VideoStream?
    let videoStreams: [VideoStream]
    let isMuted: Bool
    let networkQuality: NetworkQuality

    init(voiceChannel: VoiceChannel, mediaManager: AVSMediaManagerInterface, isOverlayVisible: Bool) {
        floatingVideoStream = voiceChannel.videoStreamArrangment.preview
        videoStreams = voiceChannel.videoStreamArrangment.grid
        isMuted = mediaManager.isMicrophoneMuted && !isOverlayVisible
        networkQuality = voiceChannel.networkQuality
    }
}

extension VoiceChannel {
    
    private var selfStream: VideoStream? {
        switch (isUnconnectedOutgoingVideoCall, videoState) {
        case (true, _), (_, .started), (_, .badConnection), (_, .screenSharing):
            return .init(stream: ZMUser.selfUser().selfStream, isPaused: false)
        case (_, .paused):
            return .init(stream: ZMUser.selfUser().selfStream, isPaused: true)
        case (_, .stopped):
            return nil
        }
    }
    
    fileprivate var videoStreamArrangment: (preview: VideoStream?, grid: [VideoStream]) {
        guard isEstablished else { return (nil, selfStream.map { [$0] } ?? [] ) }
        
        return arrangeVideoStreams(for: selfStream, participantsStreams: participantsActiveVideoStreams)
    }
    
    private var isEstablished: Bool {
        return state == .established
    }
    
    func arrangeVideoStreams(for selfStream: VideoStream?, participantsStreams: [VideoStream]) -> (preview: VideoStream?, grid: [VideoStream]) {
        let streamsExcludingSelf = participantsStreams.filter { $0.stream != selfStream?.stream }

        guard let selfStream = selfStream else {
            return (nil, streamsExcludingSelf)
        }
        
        if 1 == streamsExcludingSelf.count {
            return (selfStream, streamsExcludingSelf)
        } else {
            return (nil, [selfStream] + streamsExcludingSelf)
        }
    }
    
    var participantsActiveVideoStreams: [VideoStream] {
        return participants.compactMap { participant in
            switch participant.state {
            case .connected(let videoState, _) where videoState != .stopped:
                let stream = Stream(userId: participant.user.remoteIdentifier,
                                    clientId: participant.clientId)
                return VideoStream(stream: stream, isPaused: videoState == .paused)
            default:
                return nil
            }
        }
    }
    
   private var isUnconnectedOutgoingVideoCall: Bool {
        switch (state, isVideoCall) {
        case (.outgoing, true): return true
        default: return false
        }
    }
}
