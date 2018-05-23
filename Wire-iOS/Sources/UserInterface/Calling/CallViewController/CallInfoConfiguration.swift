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

struct CallInfoConfiguration  {
    let voiceChannel: VoiceChannel
    var preferedVideoPlaceholderState: CallVideoPlaceholderState
    let permissions: CallPermissionsConfiguration
}

extension CallInfoConfiguration: CallInfoViewControllerInput {
    
    var degradationState: CallDegradationState {
        switch voiceChannel.state {
        case .incoming(video: _, shouldRing: _, degraded: true):
            return CallDegradationState.incoming(degradedUser: voiceChannel.firstDegradedUser)
        case .answered(degraded: true):
            fallthrough
        case .outgoing(degraded: true):
            return CallDegradationState.outgoing(degradedUser: voiceChannel.firstDegradedUser)
        default:
            return .none
        }
        
    }
    
    var accessoryType: CallInfoViewControllerAccessoryType {
        let conversation = voiceChannel.conversation
        
        if isVideoCall, conversation?.conversationType == .oneOnOne {
            return .none
        }
        
        switch voiceChannel.state {
        case .incoming(video: false, shouldRing: true, degraded: _):
            return voiceChannel.initiator.map { .avatar($0) } ?? .none
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
                return .participantsList(voiceChannel.connectedParticipants.map {
                    .callParticipant(user: $0.0, sendsVideo: $0.1.isSendingVideo)
                })
            } else if let remoteParticipant = conversation?.connectedUser {
                return .avatar(remoteParticipant)
            } else {
                return .none
            }
        }
    }
    
    var canToggleMediaType: Bool {
        switch voiceChannel.state {
        case .outgoing, .incoming(video: false, shouldRing: _, degraded: _):
            return false
        default:
            return (permissions.canAcceptVideoCalls || permissions.isPendingVideoPermissionRequest) && (permissions.canAcceptAudioCalls || permissions.isPendingAudioPermissionRequest)
        }
    }
    
    var isMuted: Bool {
        return AVSMediaManager.sharedInstance().isMicrophoneMuted
    }
    
    var isTerminating: Bool {
        switch voiceChannel.state {
        case .terminating, .incoming(video: _, shouldRing: false, degraded: _): return true
        default: return false
        }
    }
    
    var canAccept: Bool {
        switch voiceChannel.state {
        case .incoming(video: _, shouldRing: true, degraded: _): return true
        default: return false
        }
    }
    
    var mediaState: MediaState {
        guard !voiceChannel.videoState.isSending else { return .sendingVideo }
        return .notSendingVideo(speakerEnabled: AVSMediaManager.sharedInstance().isSpeakerEnabled)
    }
    
    var state: CallStatusViewState {
        switch voiceChannel.state {
        case .incoming(_ , shouldRing: true, _): return .ringingIncoming(name: voiceChannel.initiator?.displayName ?? "")
        case .outgoing: return .ringingOutgoing
        case .answered, .establishedDataChannel: return .connecting
        case .established: return .established(duration: -(voiceChannel.callStartDate?.timeIntervalSinceNow.rounded() ?? 0))
        case .terminating, .incoming(_ , shouldRing: false, _): return .terminating
        case .none, .unknown: return .none
        }
    }
    
    var isConstantBitRate: Bool {
        return voiceChannel.isConstantBitRateAudioActive
    }
    
    var title: String {
        return voiceChannel.conversation?.displayName ?? ""
    }
    
    var isVideoCall: Bool {
        switch voiceChannel.state {
        case .established, .terminating:
            return voiceChannel.isAnyParticipantSendingVideo
        default:
            return voiceChannel.isVideoCall
        }
    }
    
    var variant: ColorSchemeVariant {
        return ColorScheme.default().variant
    }

    var videoPlaceholderState: CallVideoPlaceholderState {

        guard voiceChannel.isVideoCall else {
            return .hidden
        }

        guard case .incoming = voiceChannel.state else {
            return .hidden
        }

        return preferedVideoPlaceholderState

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
    
    var isAnyParticipantSendingVideo: Bool {
        return videoState.isSending || connectedParticipants.any({ $0.1.isSendingVideo })
    }
    
    var connectedParticipants: [UserWithParticipantState] {
        return participants
            .compactMap { $0 as? ZMUser }
            .map { ($0, state(forParticipant: $0)) }
            .filter { $0.1.isConnected }
    }
    
    var firstDegradedUser: ZMUser? {
        return conversation?.activeParticipants.compactMap({ $0 as? ZMUser }).first(where: { $0.untrusted() })
    }
    
}
