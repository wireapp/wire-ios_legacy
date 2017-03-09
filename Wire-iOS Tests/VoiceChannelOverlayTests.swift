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

import UIKit
import XCTest
import Classy
@testable import Wire

class VoiceChannelOverlayTests: ZMSnapshotTestCase {
    var conversation: MockConversation!
    
    func configure(view: UIView, isIpad: Bool) {
        let overlay = view as! VoiceChannelOverlay
        overlay.hidesSpeakerButton = isIpad
    }
    
    override func setUp() {
        super.setUp()
        conversation = MockConversation()
        conversation.conversationType = .oneOnOne
        conversation.displayName = "John Doe"
        conversation.connectedUser = MockUser.mockUsers().last!
    }
    
    private func voiceChannelOverlay(state: VoiceChannelOverlayState, videoCall: Bool = false, conversation: MockConversation, selfUntrusted: Bool = false) -> VoiceChannelOverlay {
        let overlay = VoiceChannelOverlay(frame: UIScreen.main.bounds)
        let mockUser = MockUser.mockSelf()
        mockUser?.untrusted = selfUntrusted
        if videoCall {
            conversation.voiceChannel = MockVoiceChannel(videoCall: true)
        }
        overlay.selfUser = (mockUser as Any) as! ZMUser
        overlay.callingConversation = (conversation as Any) as! ZMConversation
        overlay.transition(to: state)
        CASStyler.default().styleItem(overlay)
        overlay.backgroundColor = .darkGray
        return overlay
    }

    func testIncomingAudioCall() {
        let overlay = voiceChannelOverlay(state: .incomingCall, conversation: conversation)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testIncomingVideoCall() {
        let overlay = voiceChannelOverlay(state: .incomingCall, videoCall: true, conversation: conversation)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testOutgoingAudioCall() {
        let overlay = voiceChannelOverlay(state: .outgoingCall, conversation: conversation)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testOutgoingVideoCall() {
        let overlay = voiceChannelOverlay(state: .outgoingCall, videoCall: true, conversation: conversation)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testOutgoingAudioCallDegraded() {
        let overlay = voiceChannelOverlay(state: .outgoingCallDegraded, conversation: conversation)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testOutgoingVideoCallDegraded() {
        let overlay = voiceChannelOverlay(state: .outgoingCallDegraded, videoCall: true, conversation: conversation)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testOutgoingAudioCallDegradedSelfUntrustedDevices() {
        let overlay = voiceChannelOverlay(state: .outgoingCallDegraded, conversation: conversation, selfUntrusted: true)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testIncomingAudioCallDegraded() {
        let overlay = voiceChannelOverlay(state: .incomingCallDegraded, conversation: conversation)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testIncomingVideoCallDegraded() {
        let overlay = voiceChannelOverlay(state: .incomingCallDegraded, videoCall: true, conversation: conversation)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }

    func testIncomingAudioCallDegradedSelfUntrustedDevices() {
        let overlay = voiceChannelOverlay(state: .incomingCallDegraded, conversation: conversation, selfUntrusted: true)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testConnectingAudioCall() {
        let overlay = voiceChannelOverlay(state: .joiningCall, conversation: conversation)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testConnectingVideoCall() {
        let overlay = voiceChannelOverlay(state: .joiningCall, videoCall: true, conversation: conversation)
        overlay.incomingVideoActive = true
        overlay.outgoingVideoActive = true
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testConnectingVideoCallConnected() {
        let overlay = voiceChannelOverlay(state: .joiningCall, videoCall: true, conversation: conversation)
        overlay.incomingVideoActive = true
        overlay.outgoingVideoActive = true
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }

    func testOngoingAudioCall() {
        let overlay = voiceChannelOverlay(state: .connected, conversation: conversation)
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testOngoingVideoCall() {
        let overlay = voiceChannelOverlay(state: .connected, videoCall: true, conversation: conversation)
        overlay.remoteIsSendingVideo = true
        overlay.incomingVideoActive = true
        overlay.outgoingVideoActive = true
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testOngoingVideoCallWithoutIncomingVideo() {
        let overlay = voiceChannelOverlay(state: .connected, videoCall: true, conversation: conversation)
        overlay.remoteIsSendingVideo = false
        overlay.incomingVideoActive = false
        overlay.outgoingVideoActive = true
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
    
    func testOngoingVideoCallWithoutOutgoingVideo() {
        let overlay = voiceChannelOverlay(state: .connected, videoCall: true, conversation: conversation)
        overlay.remoteIsSendingVideo = true
        overlay.incomingVideoActive = true
        overlay.outgoingVideoActive = false
        verifyInAllDeviceSizes(view: overlay, configuration: configure)
    }
}
