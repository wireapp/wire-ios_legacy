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
    let networkQuality: NetworkQuality

    init(voiceChannel: VoiceChannel) {
        floatingVideoStream = voiceChannel.videoStreamArrangment.preview
        videoStreams = voiceChannel.videoStreamArrangment.grid
        networkQuality = voiceChannel.networkQuality
    }
}

extension VoiceChannel {

    private var sortedParticipants: [CallParticipant] {
        return participants.sorted { $0.user.name?.lowercased() < $1.user.name?.lowercased() }
    }
    
    private var selfStream: VideoStream? {
        guard
            let selfUser = ZMUser.selfUser(),
            let userId = selfUser.remoteIdentifier,
            let clientId = selfUser.selfClient()?.remoteIdentifier,
            let name = selfUser.name
        else {
            return nil
        }
        
        let stream = Stream(streamId: AVSClient(userId: userId, clientId: clientId),
                            participantName: name,
                            microphoneState: .unmuted)
        
        switch (isUnconnectedOutgoingVideoCall, videoState) {
        case (true, _), (_, .started), (_, .badConnection), (_, .screenSharing):
            return .init(stream: stream, isPaused: false)
        case (_, .paused):
            return .init(stream: stream, isPaused: true)
        case (_, .stopped):
            return nil
        }
    }
    
    private var selfStreamId: AVSClient? {
        return ZMUser.selfUser()?.selfStreamId
    }
    
    fileprivate var videoStreamArrangment: (preview: VideoStream?, grid: [VideoStream]) {
        guard isEstablished else { return (nil, selfStream.map { [$0] } ?? [] ) }
        
        let activeVideoStreams = sortedActiveVideoStreams
        let activeSelfStream = activeVideoStreams.first(where: { $0.stream.streamId == selfStreamId })
        
        return arrangeVideoStreams(for: activeSelfStream ?? selfStream, participantsStreams: activeVideoStreams)
    }
    
    private var isEstablished: Bool {
        return state == .established
    }
    
    func arrangeVideoStreams(for selfStream: VideoStream?, participantsStreams: [VideoStream]) -> (preview: VideoStream?, grid: [VideoStream]) {
        let streamsExcludingSelf = participantsStreams.filter { $0.stream.streamId != selfStreamId }

        guard let selfStream = selfStream else {
            return (nil, streamsExcludingSelf)
        }

        if 1 == streamsExcludingSelf.count {
            return (selfStream, streamsExcludingSelf)
        } else {
            return (nil, [selfStream] + streamsExcludingSelf)
        }
    }

    var sortedActiveVideoStreams: [VideoStream] {
        return sortedParticipants.compactMap { participant in
            switch participant.state {
            case .connected(let videoState, let microphoneState) where videoState != .stopped:
                let streamId = AVSClient(userId: participant.user.remoteIdentifier,
                                          clientId: participant.clientId)
                let stream = Stream(streamId: streamId,
                                    participantName: participant.user.name,
                                    microphoneState: microphoneState)
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
