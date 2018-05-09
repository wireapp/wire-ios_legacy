//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

@objc
class MockVoiceChannel : NSObject, CallProperties, VoiceChannel {

    var isConstantBitRateAudioActive: Bool = false
    var initiator: ZMUser?

    public func continueByDecreasingConversationSecurity(userSession: ZMUserSession) {}
    func leaveAndKeepDegradedConversationSecurity(userSession: ZMUserSession) {}


    required init(conversation: ZMConversation) {
        self.conversation = conversation
    }
    
    // MARK - Call Properties
    
    var mockIsVideoCall: Bool = false
    
    var isVideoCall: Bool {
        return mockIsVideoCall
    }
    
    var videoState: VideoState {
        return .stopped
    }
    
    var state: CallState {
        return .incoming(video: false, shouldRing: true, degraded: false)
    }
    
    var conversation: ZMConversation?
    
    var callStartDate: Date? = nil
    
    var participants: NSOrderedSet = NSOrderedSet()
    
    func state(forParticipant: ZMUser) -> CallParticipantState {
        return .connected(videoState: .stopped)
    }
    
    var selfUserConnectionState: CallParticipantState = CallParticipantState.connected(videoState: .stopped)
    
    func setVideoState(_ videoState: VideoState) {
        
    }
    
    func setVideoCaptureDevice(_ device: CaptureDevice) throws {
        
    }
    
    // MARK - Call Actions
    
    func mute(_ muted: Bool, userSession: ZMUserSession) {
        
    }
    
    func join(video: Bool, userSession: ZMUserSession) -> Bool {
        return true
    }
    
    func leave(userSession: ZMUserSession) {
        
    }
    
    func ignore(userSession: ZMUserSession) {
        
    }
    
    // MARK - Call Actions Internal
    
    func join(video: Bool) -> Bool {
        return true
    }
    
    func leave() {
        
    }
    
    func ignore() {
        
    }
    
    // MARK - Observers
    
    func addVoiceGainObserver(_ observer: VoiceGainObserver) -> Any {
        return NSObject()
    }
    
    func addCallStateObserver(_ observer: WireCallCenterCallStateObserver) -> Any {
        return NSObject()
    }
    
    func addReceivedVideoObserver(_ observer: ReceivedVideoObserver) -> Any {
        return NSObject()
    }
    
    func addParticipantObserver(_ observer: WireCallCenterCallParticipantObserver) -> Any {
        return NSObject()
    }
    
    func addConstantBitRateObserver(_ observer: ConstantBitRateAudioObserver) -> Any {
        return NSObject()
    }
    
    static func addCallStateObserver(_ observer: WireCallCenterCallStateObserver, userSession: ZMUserSession) -> Any {
        return NSObject()
    }
    
}
