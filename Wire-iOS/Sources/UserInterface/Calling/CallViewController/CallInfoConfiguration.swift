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
}

extension CallInfoConfiguration: CallInfoViewControllerInput {
    
    var accessoryType: CallInfoViewControllerAccessoryType {
        guard !voiceChannel.isVideoCall else { return .none }
        let conversation = voiceChannel.conversation
        
        switch voiceChannel.state {
        case .incoming(_, shouldRing: true, _):
            return voiceChannel.initiator.map { .avatar($0) } ?? .none
        case .answered, .establishedDataChannel, .outgoing:
            if conversation?.conversationType == .oneOnOne, let remoteParticipant = conversation?.firstActiveParticipantOtherThanSelf() {
                return .avatar(remoteParticipant)
            } else {
                return .none
            }
        case .unknown, .none, .terminating, .established, .incoming(_, shouldRing: false, _):
            if conversation?.conversationType == .group {
                return .participantsList(voiceChannel.connectedParticipants.map {
                    .callParticipant(user: $0.0, sendsVideo: $0.1.isSendingVideo)
                })
            } else if let remoteParticipant = conversation?.firstActiveParticipantOtherThanSelf() {
                return .avatar(remoteParticipant)
            } else {
                return .none
            }
        }
    }
    
    var canToggleMediaType: Bool {
        return voiceChannel.state == .established
    }
    
    var isMuted: Bool {
        return AVSMediaManager.sharedInstance().isMicrophoneMuted
    }
    
    var isTerminating: Bool {
        guard case .terminating = voiceChannel.state else { return false }
        return true
    }
    
    var canAccept: Bool {
        switch voiceChannel.state {
        case .incoming(video: _, shouldRing: true, degraded: false): return true
        default: return false
        }
    }
    
    var mediaState: MediaState {
        return .notSendingVideo(speakerEnabled: AVSMediaManager.sharedInstance().isSpeakerEnabled)
    }
    
    var state: CallStatusViewState {
        switch voiceChannel.state {
        case .incoming(_ , shouldRing: true, _): return .ringingIncoming(name: voiceChannel.initiator?.displayName ?? "")
        case .outgoing: return .ringingOutgoing
        case .answered, .establishedDataChannel: return .connecting
        case .established: return .established(duration: -(voiceChannel.callStartDate?.timeIntervalSinceNow ?? 0))
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
        return voiceChannel.isVideoCall
    }
    
    var variant: ColorSchemeVariant {
        return ColorScheme.default().variant
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
        case .connected(videoState: .started), .connected(videoState: .badConnection): return true
        default: return false
        }
    }
}

fileprivate typealias UserWithParticipantState = (ZMUser, CallParticipantState)

fileprivate extension VoiceChannel {
    
    var connectedParticipants: [UserWithParticipantState] {
        return participants
            .compactMap { $0 as? ZMUser }
            .map { ($0, state(forParticipant: $0)) }
            .filter { $0.1.isConnected }
    }
    
}
