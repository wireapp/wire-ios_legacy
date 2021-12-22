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

struct CallGridConfiguration: CallGridViewControllerInput, Equatable {

    fileprivate static let maxActiveSpeakers: Int = 4

    let floatingStream: Stream?
    let streams: [Stream]
    let videoState: VideoState
    let networkQuality: NetworkQuality
    let shouldShowActiveSpeakerFrame: Bool
    let presentationMode: VideoGridPresentationMode
    let callHasTwoParticipants: Bool

    init(voiceChannel: VoiceChannel) {
        let videoStreamArrangment = voiceChannel.createStreamArrangment()

        floatingStream = videoStreamArrangment.preview
        streams = videoStreamArrangment.grid
        videoState = voiceChannel.videoState
        networkQuality = voiceChannel.networkQuality
        shouldShowActiveSpeakerFrame = voiceChannel.shouldShowActiveSpeakerFrame
        presentationMode = voiceChannel.videoGridPresentationMode
        callHasTwoParticipants = voiceChannel.callHasTwoParticipants
    }
}

extension CallParticipant {
    var streamId: AVSClient {
        return AVSClient(userId: userId, clientId: clientId)
    }
}

extension VoiceChannel {

    // MARK: - Stream Arrangment

    typealias StreamArrangment = (preview: Stream?, grid: [Stream])

    fileprivate func createStreamArrangment() -> StreamArrangment {
        guard isEstablished else { return streamArrangementForNonEstablishedCall }

        let participants = self.participants(forPresentationMode: videoGridPresentationMode)

        var streams = activeStreams(from: participants)

        if case let .limit(amount: amount) = callingConfig.streamLimit {
            streams = Array(streams.prefix(amount))
        }

        let selfStream = self.selfStream(
            from: streams,
            createIfNeeded: videoGridPresentationMode.needsSelfStream
        )

        return arrangeStreams(for: selfStream, participantsStreams: streams)
    }

    func arrangeStreams(for selfStream: Stream?, participantsStreams: [Stream]) -> StreamArrangment {
        let streamsExcludingSelf = participantsStreams.filter { $0.streamId != selfStreamId }

        guard let selfStream = selfStream else {
            return (nil, streamsExcludingSelf)
        }

        if callHasTwoParticipants && streamsExcludingSelf.count == 1 {
            return (selfStream, streamsExcludingSelf)
        } else {
            return (nil, [selfStream] + streamsExcludingSelf)
        }
    }

    private var streamArrangementForNonEstablishedCall: StreamArrangment {
        guard videoGridPresentationMode.needsSelfStream, let stream = createSelfStream() else {
            return (nil, [])
        }
        return (nil, [stream])
    }

    func participants(forPresentationMode mode: VideoGridPresentationMode) -> [CallParticipant] {
        var participants = self.participants(
            ofKind: mode.callParticipantsListKind,
            activeSpeakersLimit: CallGridConfiguration.maxActiveSpeakers
        )

        if mode == .allVideoStreams {
            participants.sortByName(selfStreamId: selfStreamId)
        }

        return participants
    }

    func activeStreams(from participants: [CallParticipant]) -> [Stream] {
        return participants.compactMap { participant in
            switch participant.state {
            case .connected(let videoState, let microphoneState):
                if !callingConfig.audioTilesEnabled && !videoState.isSending {
                    return nil
                }
                return Stream(
                    streamId: participant.streamId,
                    user: participant.user,
                    microphoneState: microphoneState,
                    videoState: videoState,
                    activeSpeakerState: participant.activeSpeakerState,
                    isPaused: videoState == .paused
                )
            default:
                return nil
            }
        }
    }

    // MARK: - Self Stream

    private func createSelfStream() -> Stream? {
        guard
            let selfUser = ZMUser.selfUser(),
            let userId = selfUser.remoteIdentifier,
            let clientId = selfUser.selfClient()?.remoteIdentifier
        else {
            return nil
        }

        var isPaused = false
        switch (isUnconnectedOutgoingVideoCall, videoState) {
        case (true, _), (_, .started), (_, .badConnection), (_, .screenSharing):
            isPaused = false
        case (_, .paused):
            isPaused = true
        case (_, .stopped):
            return nil
        }

        return Stream(
            streamId: AVSClient(userId: userId, clientId: clientId),
            user: selfUser,
            microphoneState: .unmuted,
            videoState: videoState,
            activeSpeakerState: .inactive,
            isPaused: isPaused
        )
    }

    private var selfStreamId: AVSClient? {
        return ZMUser.selfUser()?.selfStreamId
    }

    private func selfStream(from streams: [Stream], createIfNeeded: Bool) -> Stream? {
        guard let selfStream = streams.first(where: { $0.streamId == selfStreamId }) else {
            return createIfNeeded ? createSelfStream() : nil
        }

        return selfStream
    }

    // MARK: - Helpers

    private var callingConfig: CallingConfiguration { .config }

    private var isEstablished: Bool {
        return state == .established
    }

    fileprivate var callHasTwoParticipants: Bool {
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
        @unknown default:
            return .all
        }
    }

    var needsSelfStream: Bool {
        return self == .allVideoStreams
    }
}
