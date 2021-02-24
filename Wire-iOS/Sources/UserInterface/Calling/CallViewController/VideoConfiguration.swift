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

    fileprivate static let maxActiveSpeakers: Int = 4
    fileprivate static let maxVideoStreams: Int = 12

    let floatingVideoStream: VideoStream?
    let videoStreams: [VideoStream]
    let videoState: VideoState
    let networkQuality: NetworkQuality
    let shouldShowActiveSpeakerFrame: Bool
    let presentationMode: VideoGridPresentationMode
    
    init(voiceChannel: VoiceChannel) {
        let videoStreamArrangment = voiceChannel.createVideoStreamArrangment()
       
        floatingVideoStream = videoStreamArrangment.preview
        videoStreams = videoStreamArrangment.grid
        videoState = voiceChannel.videoState
        networkQuality = voiceChannel.networkQuality
        shouldShowActiveSpeakerFrame = voiceChannel.shouldShowActiveSpeakerFrame
        presentationMode = voiceChannel.videoGridPresentationMode
    }
}

extension CallParticipant {
    var streamId: AVSClient {
        return AVSClient(userId: userId, clientId: clientId)
    }
}

extension VoiceChannel {
    
    // MARK: - Video Stream Arrangment
    
    typealias VideoStreamArrangment = (preview: VideoStream?, grid: [VideoStream])
        
    fileprivate func createVideoStreamArrangment() -> VideoStreamArrangment {
        guard isEstablished else { return videoStreamArrangementForNonEstablishedCall }
        
        let participants = self.participants(forPresentationMode: videoGridPresentationMode)
        
        let videoStreams = Array(activeVideoStreams(from: participants).prefix(VideoConfiguration.maxVideoStreams))
    
        let selfStream = self.selfStream(
            from: videoStreams,
            createIfNeeded: videoGridPresentationMode.needsSelfStream
        )

        return arrangeVideoStreams(for: selfStream, participantsStreams: videoStreams)
    }
    
    func arrangeVideoStreams(for selfStream: VideoStream?, participantsStreams: [VideoStream]) -> VideoStreamArrangment {
        let streamsExcludingSelf = participantsStreams.filter { $0.stream.streamId != selfStreamId }
        
        guard let selfStream = selfStream else {
            return (nil, streamsExcludingSelf)
        }
        
        if callHasTwoParticipants && streamsExcludingSelf.count == 1 {
            return (selfStream, streamsExcludingSelf)
        } else {
            return (nil, [selfStream] + streamsExcludingSelf)
        }
    }
    
    private var videoStreamArrangementForNonEstablishedCall: VideoStreamArrangment {
        guard videoGridPresentationMode.needsSelfStream, let stream = createSelfStream() else {
            return (nil, [])
        }
        return (nil, [stream])
    }
    
    func participants(forPresentationMode mode: VideoGridPresentationMode) -> [CallParticipant] {
        var participants = self.participants(
            ofKind: mode.callParticipantsListKind,
            activeSpeakersLimit: VideoConfiguration.maxActiveSpeakers
        )
        
        if mode == .allVideoStreams {
            participants.sortByName(selfStreamId: selfStreamId)
        }
        
        return participants
    }
    
    func activeVideoStreams(from participants: [CallParticipant]) -> [VideoStream] {
        return participants.compactMap { participant in
            switch participant.state {
            case .connected(let videoState, let microphoneState) where videoState != .stopped:
                let stream = Stream(streamId: participant.streamId,
                                    participantName: participant.user.name,
                                    microphoneState: microphoneState,
                                    videoState: videoState,
                                    activeSpeakerState: participant.activeSpeakerState)
                return VideoStream(stream: stream, isPaused: videoState == .paused)
            default:
                return nil
            }
        }
    }
    
    // MARK: - Self Stream
    
    private func createSelfStream() -> VideoStream? {
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
                            microphoneState: .unmuted,
                            videoState: videoState,
                            activeSpeakerState: .inactive)
        
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

    private func selfStream(from videoStreams: [VideoStream], createIfNeeded: Bool) -> VideoStream? {
        guard let selfStream = videoStreams.first(where: { $0.stream.streamId == selfStreamId }) else {
            return createIfNeeded ? createSelfStream() : nil
        }
        
        return selfStream
    }
    
    // MARK: - Helpers
    
    private var isEstablished: Bool {
        return state == .established
    }
    
    private var callHasTwoParticipants: Bool {
        return connectedParticipants.count == 2
    }
    
    fileprivate var shouldShowActiveSpeakerFrame: Bool {
        return connectedParticipants.count > 2 && videoGridPresentationMode == .allVideoStreams
    }
    
    private var isUnconnectedOutgoingVideoCall: Bool {
        switch (state, isVideoCall) {
        case (.outgoing, true): return true
        default: return false
        }
    }
}

private extension VideoGridPresentationMode {
    var callParticipantsListKind: CallParticipantsListKind {
        switch self {
        case .activeSpeakers:
            return .smoothedActiveSpeakers
        case .allVideoStreams:
            return .all
        }
    }
    
    var needsSelfStream: Bool {
        return self == .allVideoStreams
    }
}

private extension Array where Element == CallParticipant {
    mutating func sortByName(selfStreamId: AVSClient?) {
        self = self.sorted {
            $0.streamId == selfStreamId ||
            $0.user.name?.lowercased() < $1.user.name?.lowercased()
        }
    }
}
