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
class MockVoiceChannel : NSObject, VoiceChannel {
    var initiator: ZMUser?

    public func continueByDecreasingConversationSecurity(userSession: ZMUserSession) {}
    func leaveAndKeepDegradedConversationSecurity(userSession: ZMUserSession) {}

    
    @objc
    public init(videoCall: Bool) {
        self.isVideoCall = videoCall
        
        super.init()
    }
    
    // MARK - Call Properties
    
    var isVideoCall: Bool = false
    
    var state: CallState {
        return .incoming(video: false, shouldRing: true, degraded: false)
    }
    
    var conversation: ZMConversation?
    
    var callStartDate: Date? = nil
    
    var participants: NSOrderedSet = NSOrderedSet()
    
    func state(forParticipant: ZMUser) -> CallParticipantState {
        return .connected(muted: false, sendingVideo: false)
    }
    
    var selfUserConnectionState: CallParticipantState = CallParticipantState.connected(muted: false, sendingVideo: false)
    
    func setVideoCaptureDevice(device: CaptureDevice) throws {
        
    }
    
    func toggleVideo(active: Bool) throws {
        
    }
    
    // MARK - Call Actions
    
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
    
    func addVoiceGainObserver(_ observer: VoiceGainObserver) -> WireCallCenterObserverToken {
        return NSObject()
    }
    
    func addCallStateObserver(_ observer: WireCallCenterCallStateObserver) -> WireCallCenterObserverToken {
        return NSObject()
    }
    
    func addReceivedVideoObserver(_ observer: ReceivedVideoObserver) -> WireCallCenterObserverToken {
        return NSObject()
    }
    
    func addParticipantObserver(_ observer: VoiceChannelParticipantObserver) -> WireCallCenterObserverToken {
        return NSObject()
    }
    
    static func addCallStateObserver(_ observer: WireCallCenterCallStateObserver, userSession: ZMUserSession) -> WireCallCenterObserverToken {
        return NSObject()
    }
    
}
