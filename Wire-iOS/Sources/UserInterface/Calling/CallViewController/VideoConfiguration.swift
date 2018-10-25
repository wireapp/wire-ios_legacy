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

struct VideoConfiguration: VideoGridConfiguration {
    let floatingVideoStream: ParticipantVideoState?
    let videoStreams: [ParticipantVideoState]
    let isMuted: Bool
    let networkQuality: NetworkQuality

    init(voiceChannel: VoiceChannel, mediaManager: AVSMediaManagerInterface, isOverlayVisible: Bool) {
        floatingVideoStream = voiceChannel.videoStreamArrangment.preview
        videoStreams = voiceChannel.videoStreamArrangment.grid
        isMuted = mediaManager.isMicrophoneMuted && !isOverlayVisible
        networkQuality = voiceChannel.networkQuality
    }
}

fileprivate extension VoiceChannel {
    
    var selfStream: ParticipantVideoState? {
        switch (isUnconnectedOutgoingVideoCall, videoState) {
        case (true, _), (_, .started), (_, .badConnection), (_, .screenSharing):
            return .init(stream: ZMUser.selfUser().remoteIdentifier, isPaused: false)
        case (_, .paused):
            return .init(stream: ZMUser.selfUser().remoteIdentifier, isPaused: true)
        case (_, .stopped):
            return nil
        }
    }
    
    var videoStreamArrangment: (preview: ParticipantVideoState?, grid: [ParticipantVideoState]) {
        let otherParticipants: [ParticipantVideoState] = participants.compactMap { user in
            guard let user = user as? ZMUser else { return nil }
            switch state(forParticipant: user) {
            case .connected(videoState: .started), .connected(videoState: .badConnection), .connected(videoState: .screenSharing):
                return .init(stream: user.remoteIdentifier, isPaused: false)
            case .connected(videoState: .paused):
                return .init(stream: user.remoteIdentifier, isPaused: true)
            default: return nil
            }
        }
        
        guard isEstablished else { return (nil, selfStream.map { [$0] } ?? [] ) }
        
        if let selfStream = selfStream {
            if 1 == otherParticipants.count {
                return (selfStream, otherParticipants)
            } else {
                return (nil, [selfStream] + otherParticipants)
            }
        } else {
            return (nil, otherParticipants)
        }
    }
    
    var isUnconnectedOutgoingVideoCall: Bool {
        switch (state, isVideoCall) {
        case (.outgoing, true): return true
        default: return false
        }
    }
    
    var isEstablished: Bool {
        guard case .established = state else { return false }
        return true
    }
}
