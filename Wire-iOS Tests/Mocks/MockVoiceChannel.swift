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

class MockVoiceChannel: NSObject, VoiceChannel {

    var conversation: ZMConversation?
    var mockCallState: CallState = .incoming(video: false, shouldRing: true, degraded: false)
    var mockCallDuration: TimeInterval?
    var mockParticipants: NSOrderedSet = NSOrderedSet()
    var mockIsConstantBitRateAudioActive: Bool = false
    var mockInitiator: ZMUser? = nil
    var mockIsVideoCall: Bool = false
    var mockCallParticipantState: CallParticipantState = .unconnected
    var mockVideoState: VideoState = .stopped
    var mockNetworkQuality: NetworkQuality = .normal

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
    
    var participants: NSOrderedSet {
        return mockParticipants
    }
    
    var isConstantBitRateAudioActive: Bool {
        return mockIsConstantBitRateAudioActive
    }
    
    var isVideoCall: Bool {
        return mockIsVideoCall
    }
    
    var initiator: ZMUser? {
        return mockInitiator
    }
    
    func state(forParticipant: ZMUser) -> CallParticipantState {
        return mockCallParticipantState
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
    
    func setVideoCaptureDevice(_ device: CaptureDevice) throws {}
    
    func mute(_ muted: Bool, userSession: ZMUserSession) {}
    
    func join(video: Bool, userSession: ZMUserSession) -> Bool { return true }
    
    func leave(userSession: ZMUserSession) {}
    
    func continueByDecreasingConversationSecurity(userSession: ZMUserSession) {}
    
    func leaveAndKeepDegradedConversationSecurity(userSession: ZMUserSession) {}
    
    func join(video: Bool) -> Bool { return true }
    
    func leave() {}
    
}
