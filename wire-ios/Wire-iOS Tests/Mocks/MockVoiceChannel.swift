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

final class MockVoiceChannel: NSObject, VoiceChannel {
    var conversation: ZMConversation?
    var mockCallState: CallState = .incoming(video: false, shouldRing: true, degraded: false)
    var mockCallDuration: TimeInterval?
    var mockParticipants: [CallParticipant] = []
    var mockIsConstantBitRateAudioActive: Bool = false
    var mockInitiator: UserType?
    var mockIsVideoCall: Bool = false
    var mockVideoState: VideoState = .stopped
    var mockNetworkQuality: NetworkQuality = .normal
    var mockIsConferenceCall: Bool = false
    var mockFirstDegradedUser: UserType?

    required init(conversation: ZMConversation) {
        self.conversation = conversation
    }

    func addCallStateObserver(_ observer: WireCallCenterCallStateObserver) -> Any {
        return "token"
    }

    func addParticipantObserver(_ observer: WireCallCenterCallParticipantObserver) -> Any {
        return "token"
    }

    func addVoiceGainObserver(_ observer: VoiceGainObserver) -> Any {
        return "token"
    }

    func addConstantBitRateObserver(_ observer: ConstantBitRateAudioObserver) -> Any {
        return "token"
    }

    static func addCallStateObserver(_ observer: WireCallCenterCallStateObserver, userSession: ZMUserSession) -> Any {
        return "token"
    }

    func addNetworkQualityObserver(_ observer: NetworkQualityObserver) -> Any {
        return "token"
    }

    func addMuteStateObserver(_ observer: MuteStateObserver) -> Any {
        return "token"
    }

    func addActiveSpeakersObserver(_ observer: ActiveSpeakersObserver) -> Any {
        return "token"
    }

    var state: CallState {
        return mockCallState
    }

    var callStartDate: Date? {
        if let mockCallDuration = mockCallDuration {
            return Date(timeIntervalSinceNow: -mockCallDuration)
        } else {
            return nil
        }
    }

    var participants: [CallParticipant] {
        return mockParticipants
    }

    var requestedCallParticipantsListKind: CallParticipantsListKind?
    func participants(ofKind kind: CallParticipantsListKind, activeSpeakersLimit limit: Int?) -> [CallParticipant] {
        requestedCallParticipantsListKind = kind
        return mockParticipants
    }

    var isConstantBitRateAudioActive: Bool {
        return mockIsConstantBitRateAudioActive
    }

    var isVideoCall: Bool {
        return mockIsVideoCall
    }

    var initiator: UserType? {
        return mockInitiator
    }

    var videoState: VideoState {
        get {
            return mockVideoState
        }
        set {
            mockVideoState = newValue
        }

    }

    var networkQuality: NetworkQuality {
        return mockNetworkQuality
    }

    var isConferenceCall: Bool {
        return mockIsConferenceCall
    }

    var firstDegradedUser: UserType? {
        return mockFirstDegradedUser
    }

    var mockMuted = false
    var muted: Bool {
        get {
            return mockMuted
        }
        set {
            mockMuted = newValue
        }
    }

    var mockVideoGridPresentationMode: VideoGridPresentationMode = .allVideoStreams
    var videoGridPresentationMode: VideoGridPresentationMode {
        get {
            return mockVideoGridPresentationMode
        }
        set {
            mockVideoGridPresentationMode = newValue
        }
    }

    func setVideoCaptureDevice(_ device: CaptureDevice) throws {}

    func mute(_ muted: Bool, userSession: ZMUserSession) {}

    func join(video: Bool, userSession: ZMUserSession) -> Bool { return true }

    func leave(userSession: ZMUserSession, completion: (() -> Void)?) {}

    func continueByDecreasingConversationSecurity(userSession: ZMUserSession) {}

    func leaveAndDecreaseConversationSecurity(userSession: ZMUserSession) {}

    func join(video: Bool) -> Bool { return true }

    func leave() {}

    var requestedVideoStreams: [AVSClient]?
    func request(videoStreams: [AVSClient]) {
        requestedVideoStreams = videoStreams
    }
}
