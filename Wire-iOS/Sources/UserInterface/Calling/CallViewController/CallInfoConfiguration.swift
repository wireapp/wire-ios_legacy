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

fileprivate extension VoiceChannel {
    var degradationState: CallDegradationState {
        switch state {
        case .incoming(video: _, shouldRing: _, degraded: true):
            return .incoming(degradedUser: firstDegradedUser)
        case .answered(degraded: true), .outgoing(degraded: true):
            return .outgoing(degradedUser: firstDegradedUser)
        default:
            return .none
        }
    }
    
    func accessoryType(using timestamps: CallParticipantTimestamps) -> CallInfoViewControllerAccessoryType {
        if internalIsVideoCall, conversation?.conversationType == .oneOnOne {
            return .none
        }
        
        switch state {
        case .incoming(video: false, shouldRing: true, degraded: _):
            return initiator.map { .avatar($0) } ?? .none
        case .incoming(video: true, shouldRing: true, degraded: _):
            return .none
        case .answered, .establishedDataChannel, .outgoing:
            if conversation?.conversationType == .oneOnOne, let remoteParticipant = conversation?.connectedUser {
                return .avatar(remoteParticipant)
            } else {
                return .none
            }
        case .unknown, .none, .terminating, .established, .incoming(_, shouldRing: false, _):
            if conversation?.conversationType == .group {
                return .participantsList(sortedConnectedParticipants(using: timestamps).map {
                    .callParticipant(user: $0.0, sendsVideo: $0.1.isSendingVideo)
                })
            } else if let remoteParticipant = conversation?.connectedUser {
                return .avatar(remoteParticipant)
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
    
    func canToggleMediaType(with permissions: CallPermissionsConfiguration) -> Bool {
        switch state {
        case .outgoing, .incoming(video: false, shouldRing: _, degraded: _):
            return false
        default:
            guard !permissions.isVideoDisabledForever && !permissions.isAudioDisabledForever else { return false }
            
            // The user can only re-enable their video if the conversation allows GVC
            if videoState == .stopped {
                return canUpgradeToVideo
            }
            
            // If the user already enabled video, they should be able to disable it
            return true
        }
    }
    
    var isTerminating: Bool {
        switch state {
        case .terminating, .incoming(video: _, shouldRing: false, degraded: _): return true
        default: return false
        }
    }
    
    var canAccept: Bool {
        switch state {
        case .incoming(video: _, shouldRing: true, degraded: _): return true
        default: return false
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
        default: return internalIsVideoCall && !isTerminating
        }
    }

}

struct CallInfoConfiguration: CallInfoViewControllerInput  {

    let permissions: CallPermissionsConfiguration
    let isConstantBitRate: Bool
    let title: String
    let isVideoCall: Bool
    let variant: ColorSchemeVariant
    let canToggleMediaType: Bool
    let isMuted: Bool
    let isTerminating: Bool
    let canAccept: Bool
    let mediaState: MediaState
    let accessoryType: CallInfoViewControllerAccessoryType
    let degradationState: CallDegradationState
    let videoPlaceholderState: CallVideoPlaceholderState
    let disableIdleTimer: Bool
    let cameraType: CaptureDevice

    private let voiceChannelSnapshot: VoiceChannelSnapshot

    init(
        voiceChannel: VoiceChannel,
        preferedVideoPlaceholderState: CallVideoPlaceholderState,
        permissions: CallPermissionsConfiguration,
        cameraType: CaptureDevice,
        sortTimestamps: CallParticipantTimestamps
        ) {
        self.permissions = permissions
        self.cameraType = cameraType
        voiceChannelSnapshot = VoiceChannelSnapshot(voiceChannel)
        degradationState = voiceChannel.degradationState
        accessoryType = voiceChannel.accessoryType(using: sortTimestamps)
        isMuted = AVSMediaManager.sharedInstance().isMicrophoneMuted
        canToggleMediaType = voiceChannel.canToggleMediaType(with: permissions)
        canAccept = voiceChannel.canAccept
        isVideoCall = voiceChannel.internalIsVideoCall
        isTerminating = voiceChannel.isTerminating
        isConstantBitRate = voiceChannel.isConstantBitRateAudioActive
        title = voiceChannel.conversation?.displayName ?? ""
        variant = ColorScheme.default.variant
        mediaState = voiceChannel.mediaState(with: permissions)
        videoPlaceholderState = voiceChannel.videoPlaceholderState ?? preferedVideoPlaceholderState
        disableIdleTimer = voiceChannel.disableIdleTimer
    }

    // This property has to be computed in order to return the correct call duration
    var state: CallStatusViewState {
        switch voiceChannelSnapshot.state {
        case .incoming(_ , shouldRing: true, _): return .ringingIncoming(name: voiceChannelSnapshot.callerName)
        case .outgoing: return .ringingOutgoing
        case .answered, .establishedDataChannel: return .connecting
        case .established: return .established(duration: -voiceChannelSnapshot.callStartDate.timeIntervalSinceNow.rounded())
        case .terminating, .incoming(_ , shouldRing: false, _): return .terminating
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
            return voiceChannel.initiator?.displayName ?? ""
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
        case .connected(videoState: let state) where state.isSending: return true
        default: return false
        }
    }
}

fileprivate typealias UserWithParticipantState = (ZMUser, CallParticipantState)

fileprivate extension VoiceChannel {
    
    var canUpgradeToVideo: Bool {
        guard let conversation = conversation, conversation.conversationType != .oneOnOne else { return true }
        guard conversation.activeParticipants.count <= ZMConversation.maxVideoCallParticipants else { return false }
        return ZMUser.selfUser().isTeamMember || isAnyParticipantSendingVideo
    }
    
    var isAnyParticipantSendingVideo: Bool {
        return videoState.isSending                              // Current user is sending video and can toggle off
            || connectedParticipants.any { $0.1.isSendingVideo } // Other participants are sending video
            || isIncomingVideoCall                               // This is an incoming video call
    }
    
    var connectedParticipants: [UserWithParticipantState] {
        return participants
            .lazy
            .compactMap { $0 as? ZMUser }
            .map { ($0, self.state(forParticipant: $0)) }
            .filter { $0.1.isConnected }
    }

    func sortedConnectedParticipants(using timestamps: CallParticipantTimestamps) -> [UserWithParticipantState] {
        return connectedParticipants.sorted { lhs, rhs in
            timestamps[lhs.0] > timestamps[rhs.0]
        }
    }

    var firstDegradedUser: ZMUser? {
        return conversation?.activeParticipants.compactMap({ $0 as? ZMUser }).first(where: { $0.untrusted() })
    }

    private var isIncomingVideoCall: Bool {
        switch state {
        case .incoming(video: true, shouldRing: true, degraded: _): return true
        default: return false
        }
    }
    
}
