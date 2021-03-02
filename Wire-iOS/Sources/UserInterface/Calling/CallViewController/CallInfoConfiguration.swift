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

import Foundation
import avs
import WireSyncEngine

fileprivate extension VoiceChannel {
    func accessoryType() -> CallInfoViewControllerAccessoryType {
        if internalIsVideoCall, conversation?.conversationType == .oneOnOne {
            return .none
        }

        switch state {
        case .incoming(video: false, shouldRing: true, degraded: _):
            return initiator.map { .avatar(HashBox(value: $0)) } ?? .none
        case .incoming(video: true, shouldRing: true, degraded: _):
            return .none
        case .answered, .establishedDataChannel, .outgoing:
            if conversation?.conversationType == .oneOnOne, let remoteParticipant = conversation?.connectedUser {
                return .avatar(HashBox(value: remoteParticipant))
            } else {
                return .none
            }
        case .unknown,
             .none,
             .terminating,
             .mediaStopped,
             .established,
             .incoming(_, shouldRing: false, _):
            if conversation?.conversationType == .group {
                return .participantsList(sortedConnectedParticipants().map {
                    .callParticipant(user: HashBox(value: $0.user),
                                     videoState: $0.state.videoState,
                                     microphoneState: $0.state.microphoneState,
                                     activeSpeakerState: $0.activeSpeakerState)
                })

            } else if let remoteParticipant = conversation?.connectedUser {
                return .avatar(HashBox(value: remoteParticipant))
            } else {
                return .none
            }
        }
    }

    var internalIsVideoCall: Bool {
        switch state {
        case .established, .terminating: return isAnyParticipantSendingVideo
        default: return isVideoCall
        }
    }

    func canToggleMediaType(with permissions: CallPermissionsConfiguration,
                            selfUser: UserType) -> Bool {
        switch state {
        case .outgoing, .incoming(video: false, shouldRing: _, degraded: _):
            return false
        default:
            guard !permissions.isVideoDisabledForever && !permissions.isAudioDisabledForever else { return false }

            // The user can only re-enable their video if the conversation allows GVC
            if videoState == .stopped {
                return canUpgradeToVideo(selfUser: selfUser)
            }

            // If the user already enabled video, they should be able to disable it
            return true
        }
    }

    func mediaState(with permissions: CallPermissionsConfiguration) -> MediaState {
        let isPadOrPod = UIDevice.current.type == .iPad || UIDevice.current.type == .iPod
        let speakerEnabled = AVSMediaManager.sharedInstance().isSpeakerEnabled
        let speakerState = MediaState.SpeakerState(
            isEnabled: speakerEnabled || isPadOrPod,
            canBeToggled: !isPadOrPod
        )

        guard permissions.canAcceptVideoCalls else { return .notSendingVideo(speakerState: speakerState) }
        guard !videoState.isSending else { return .sendingVideo }
        return .notSendingVideo(speakerState: speakerState)
    }

    var videoPlaceholderState: CallVideoPlaceholderState? {
        guard internalIsVideoCall else { return .hidden }
        guard case .incoming = state else { return .hidden }
        return nil
    }

    var disableIdleTimer: Bool {
        switch state {
        case .none: return false
        default: return internalIsVideoCall && !state.isTerminating
        }
    }

}

struct CallInfoConfiguration: CallInfoViewControllerInput  {
    fileprivate static let maxActiveSpeakers: Int = 4

    let permissions: CallPermissionsConfiguration
    let isConstantBitRate: Bool
    let title: String
    let isVideoCall: Bool
    let variant: ColorSchemeVariant
    let canToggleMediaType: Bool
    let isMuted: Bool
    let mediaState: MediaState
    let accessoryType: CallInfoViewControllerAccessoryType
    let degradationState: CallDegradationState
    let videoPlaceholderState: CallVideoPlaceholderState
    let disableIdleTimer: Bool
    let cameraType: CaptureDevice
    let mediaManager: AVSMediaManagerInterface
    let networkQuality: NetworkQuality
    let userEnabledCBR: Bool
    let callState: CallStateExtending
    let videoGridPresentationMode: VideoGridPresentationMode
    let allowPresentationModeUpdates: Bool

    private let voiceChannelSnapshot: VoiceChannelSnapshot

    init(
        voiceChannel: VoiceChannel,
        preferedVideoPlaceholderState: CallVideoPlaceholderState,
        permissions: CallPermissionsConfiguration,
        cameraType: CaptureDevice,
        mediaManager: AVSMediaManagerInterface = AVSMediaManager.sharedInstance(),
        userEnabledCBR: Bool,
        selfUser: UserType) {
        self.permissions = permissions
        self.cameraType = cameraType
        self.mediaManager = mediaManager
        self.userEnabledCBR = userEnabledCBR
        voiceChannelSnapshot = VoiceChannelSnapshot(voiceChannel)
        degradationState = voiceChannel.degradationState
        accessoryType = voiceChannel.accessoryType()
        isMuted = mediaManager.isMicrophoneMuted
        canToggleMediaType = voiceChannel.canToggleMediaType(with: permissions, selfUser: selfUser)
        isVideoCall = voiceChannel.internalIsVideoCall
        isConstantBitRate = voiceChannel.isConstantBitRateAudioActive
        title = voiceChannel.conversation?.displayName ?? ""
        variant = ColorScheme.default.variant
        mediaState = voiceChannel.mediaState(with: permissions)
        videoPlaceholderState = voiceChannel.videoPlaceholderState ?? preferedVideoPlaceholderState
        disableIdleTimer = voiceChannel.disableIdleTimer
        networkQuality = voiceChannel.networkQuality
        callState = voiceChannel.state
        videoGridPresentationMode = voiceChannel.videoGridPresentationMode
        allowPresentationModeUpdates = voiceChannel.allowPresentationModeUpdates
    }

    // This property has to be computed in order to return the correct call duration
    var state: CallStatusViewState {
        switch voiceChannelSnapshot.state {
        case .incoming(_, shouldRing: true, _): return .ringingIncoming(name: voiceChannelSnapshot.callerName)
        case .outgoing: return .ringingOutgoing
        case .answered, .establishedDataChannel: return .connecting
        case .established: return .established(duration: -voiceChannelSnapshot.callStartDate.timeIntervalSinceNow.rounded())
        case .terminating, .mediaStopped, .incoming(_, shouldRing: false, _): return .terminating
        case .none, .unknown: return .none
        }
    }

}

fileprivate struct VoiceChannelSnapshot {
    let callerName: String?
    let state: CallState
    let callStartDate: Date

    init(_ voiceChannel: VoiceChannel) {
        callerName = {
            guard voiceChannel.conversation?.conversationType != .oneOnOne else { return nil }
            return voiceChannel.initiator?.name ?? ""
        }()
        state = voiceChannel.state
        callStartDate = voiceChannel.callStartDate ?? .init()
    }
}

// MARK: - Helper

extension CallParticipantState {
    var isConnected: Bool {
        guard case .connected = self else { return false }
        return true
    }

    var isSendingVideo: Bool {
        switch self {
        case .connected(videoState: let state, _) where state.isSending: return true
        default: return false
        }
    }

    var videoState: VideoState? {
        switch self {
        case .connected(videoState: let state, _):
            return state
        default:
            return nil
        }
    }

    var microphoneState: MicrophoneState? {
        switch self {
        case .connected(_, microphoneState: let state):
            return state
        default:
            return nil
        }
    }
}

fileprivate extension VoiceChannel {

    func canUpgradeToVideo(selfUser: UserType) -> Bool {
        guard !isConferenceCall else {
            return true
        }

        guard let conversation = conversation, conversation.conversationType != .oneOnOne else {
            return true
        }

        guard !isLegacyGroupVideoParticipantLimitReached else {
            return false
        }

        return selfUser.isTeamMember || isAnyParticipantSendingVideo
    }

    var isAnyParticipantSendingVideo: Bool {
        return videoState.isSending                                  // Current user is sending video and can toggle off
            || connectedParticipants.any { $0.state.isSendingVideo } // Other participants are sending video
            || isIncomingVideoCall                                   // This is an incoming video call
    }

    func sortedConnectedParticipants() -> [CallParticipant] {
        return connectedParticipants.sorted { lhs, rhs in
            lhs.user.name?.lowercased() < rhs.user.name?.lowercased()
        }
    }

    private var isIncomingVideoCall: Bool {
        switch state {
        case .incoming(video: true, shouldRing: true, degraded: _): return true
        default: return false
        }
    }

    var allowPresentationModeUpdates: Bool {
        return connectedParticipants.count > 2
            && internalIsVideoCall
            && isActiveSpeakersTabEnabled
    }
    private var isActiveSpeakersTabEnabled: Bool { true }
}

extension VoiceChannel {
    var connectedParticipants: [CallParticipant] {
        return participants(ofKind: .all, activeSpeakersLimit: CallInfoConfiguration.maxActiveSpeakers).filter(\.state.isConnected)
    }

    private var hashboxFirstDegradedUser: HashBoxUser? {
        guard let firstDegradedUser = firstDegradedUser else {
            return nil
        }

        return HashBox(value: firstDegradedUser)
    }

    var degradationState: CallDegradationState {
        switch state {
        case .incoming(video: _, shouldRing: _, degraded: true):
            return .incoming(degradedUser: hashboxFirstDegradedUser)
        case .answered(degraded: true), .outgoing(degraded: true):
            return .outgoing(degradedUser: hashboxFirstDegradedUser)
        default:
            return .none
        }
    }

    var isLegacyGroupVideoParticipantLimitReached: Bool {
        guard let conversation = conversation else { return false }
        return conversation.localParticipants.count > ZMConversation.legacyGroupVideoParticipantLimit
    }
}
