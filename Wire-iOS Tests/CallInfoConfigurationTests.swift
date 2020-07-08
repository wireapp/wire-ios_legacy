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

import XCTest
@testable import Wire

func ==(lhs: CallInfoViewControllerInput, rhs: CallInfoViewControllerInput) -> Bool {
    return lhs.isEqual(toConfiguration: rhs)
}

class CallInfoConfigurationTests: XCTestCase {
    
    var mockOtherUser: MockUser!
    var mockSelfUser: MockUser!
    
    var selfUser: ZMUser!
    var otherUser: ZMUser!
    
    override func setUp() {
        super.setUp()
        
        mockSelfUser = MockUser.mockSelf()
        mockOtherUser = (MockUser.mockUsers().first! as Any) as? MockUser
        
        selfUser = (mockSelfUser as Any) as? ZMUser
        otherUser = (mockOtherUser as Any) as? ZMUser
    }
    
    override func tearDown() {
        mockSelfUser = nil
        mockOtherUser = nil
        selfUser = nil
        otherUser = nil
        MockUser.setMockSelf(nil)

        super.tearDown()
    }
    
    func assertEquals(_ lhsConfig: CallInfoViewControllerInput, _ rhsConfig: CallInfoViewControllerInput, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(lhsConfig == rhsConfig, "\n\(lhsConfig)\n\nis not equal to\n\n\(rhsConfig)", file: file, line: line)
    }
    
    func mockCallParticipants(count: Int, state: CallParticipantState) -> [CallParticipant] {
        return (MockUser.mockUsers()[0..<count]).map({ CallParticipant(user: $0, clientId: "123", state: state) })
    }
    
    // MARK: - OneToOne Audio
    
    func testOneToOneIncomingAudioRinging() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.oneToOneIncomingAudioRinging, configuration)
    }
    
    func testOneToOneOutgoingAudioRinging() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = selfUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.oneToOneOutgoingAudioRinging, configuration)
    }
    
    func testOneToOneIncomingAudioDegraded() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        ((mockConversation.sortedActiveParticipants.first as Any) as? MockUser)?.isTrusted = true
        ((mockConversation.sortedActiveParticipants.last as Any) as? MockUser)?.isTrusted = false
        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: true)
        mockVoiceChannel.mockInitiator = otherUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.oneToOneIncomingAudioDegraded, configuration)
    }
    
    func testOneToOneOutgoingAudioDegraded() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        ((mockConversation.sortedActiveParticipants.first as Any) as? MockUser)?.isTrusted = true
        ((mockConversation.sortedActiveParticipants.last as Any) as? MockUser)?.isTrusted = false
        mockVoiceChannel.mockCallState = .outgoing(degraded: true)
        mockVoiceChannel.mockInitiator = selfUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.oneToOneOutgoingAudioDegraded, configuration)
    }
    

    func testOneToOneAudioConnecting() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.oneToOneAudioConnecting, configuration)
    }
    
    func testOneToOneAudioEstablishedUpgradedToVideo() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.videoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front)

        // then
        assertEquals(fixture.oneToOneVideoEstablished, configuration)
    }
    
    func testOneToOneAudioEstablished() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockCallDuration = 10
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)

        // then
        assertEquals(fixture.oneToOneAudioEstablished, configuration)
    }
    
    func testOneToOneAudioEstablishedCBR() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockIsConstantBitRateAudioActive = true
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.oneToOneAudioEstablishedCBR, configuration)
    }
    
    // MARK: - OneToOne Video
    
    func testOneToOneIncomingVideoRinging() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front)
        
        // then
        assertEquals(fixture.oneToOneIncomingVideoRinging, configuration)
    }

    func testOneToOneIncomingVideoRingingVideoTurnedOff() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .stopped
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .statusTextHidden, permissions: CallPermissions(), cameraType: .front)

        // then
        assertEquals(fixture.oneToOneIncomingVideoRingingVideoTurnedOff, configuration)
    }
    
    func testOneToOneOutgoingVideoRinging() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front)
        
        // then
        assertEquals(fixture.oneToOneOutgoingVideoRinging, configuration)
    }
    
    func testOneToOneVideoConnecting() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front)
        
        // then
        assertEquals(fixture.oneToOneVideoConnecting, configuration)
    }
    
    func testOneToOneVideoEstablished() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started
        mockVoiceChannel.mockCallDuration = 10

        let permissions = MockCallPermissions()
        permissions.canAcceptVideoCalls = true
        permissions.isPendingVideoPermissionRequest = false
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front)

        // then
        assertEquals(fixture.oneToOneVideoEstablished, configuration)
    }
    
    func testOneToOneVideoEstablishedWithScreenSharing() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .screenSharing
        mockVoiceChannel.mockCallDuration = 10
        
        let permissions = MockCallPermissions()
        permissions.canAcceptVideoCalls = true
        permissions.isPendingVideoPermissionRequest = false
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front)
        
        // then
        assertEquals(fixture.oneToOneVideoEstablished, configuration)
    }
    
    func testOneToOneVideoEstablishedDowngradedToAudio() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .stopped
        mockVoiceChannel.mockCallDuration = 10
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.oneToOneAudioEstablished, configuration)
    }
    
    // MARK: - Group Audio
    
    func testGroupIncomingAudioRinging() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.groupIncomingAudioRinging, configuration)
    }
    
    func testGroupOutgoingAudioRinging() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = selfUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.groupOutgoingAudioRinging, configuration)
    }
    
    func testGroupAudioConnecting() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        mockSelfUser.isTeamMember = true
        
        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.groupAudioConnecting, configuration)
    }
    
    func testGroupAudioEstablished() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        mockSelfUser.isTeamMember = true
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(count: fixture.groupSize.rawValue, state: .connected(videoState: .stopped, microphoneState: .unmuted))
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.groupAudioEstablished, configuration)
    }
    
    func testGroupAudioEstablishedNonTeamUser() {
        // given
        ZMConversation.callCenterConfiguration = .init()

        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let mockUsers: [ZMUser] = MockUser.mockUsers()!
        mockUsers.forEach {
            ($0 as Any as! MockUser).isTeamMember = false
        }

        (otherUser as Any as! MockUser).isTeamMember = false
        (selfUser as Any as! MockUser).isTeamMember = false

        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(count: fixture.groupSize.rawValue, state: .connected(videoState: .stopped, microphoneState: .unmuted))
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.groupAudioEstablishedVideoUnavailable, configuration)
    }
    
    func testGroupAudioEstablishedNonTeamUserRemoteTurnedVideoOn() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(count: fixture.groupSize.rawValue, state: .connected(videoState: .started, microphoneState: .unmuted))
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.groupAudioEstablishedRemoteTurnedVideoOn, configuration)
    }
    
    func testGroupAudioEstablishedLargeGroup() {
        // given
        ZMConversation.callCenterConfiguration = .init()
        
        let mockUsers: [ZMUser] = MockUser.mockUsers()!
        let fixture = CallInfoTestFixture(otherUser: otherUser, groupSize: .large)
        
        let mockGroupConversation = MockConversation.groupConversation()
        mockGroupConversation.sortedActiveParticipants = Array(mockUsers[0..<fixture.groupSize.rawValue])
        
        let mockConversation = ((mockGroupConversation as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)

        mockSelfUser.isTeamMember = true
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(count: fixture.groupSize.rawValue, state: .connected(videoState: .stopped, microphoneState: .unmuted))
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front)
        
        // then
        assertEquals(fixture.groupAudioEstablishedVideoUnavailable, configuration)
    }

    func testOneToOneIncomingVideoRingingWithVideoPermissionsDeniedForever() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoDeniedForever, cameraType: .front)

        // then
        assertEquals(fixture.oneToOneIncomingVideoRingingWithPermissionsDeniedForever, configuration)
    }


    func testOneToOneIncomingVideoRingingWithUndeterminedVideoPermissions() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoPendingApproval, cameraType: .front)

        // then
        assertEquals(fixture.oneToOneIncomingVideoRingingWithUndeterminedVideoPermissions, configuration)
    }

    // MARK: - Group Video
    
    func testGroupIncomingVideoRinging() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front)
        
        // then
        assertEquals(fixture.groupIncomingVideoRinging, configuration)
    }
    
    func testGroupOutgoingVideoRinging() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front)
        
        // then
        assertEquals(fixture.groupOutgoingVideoRinging, configuration)
    }
    
    func testGroupVideoConnecting() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front)
        
        // then
        assertEquals(fixture.groupVideoConnecting, configuration)
    }
    
    func testGroupVideoEstablished() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started
        mockVoiceChannel.mockParticipants = mockCallParticipants(count: fixture.groupSize.rawValue, state: .connected(videoState: .started, microphoneState: .unmuted))
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front)
        
        // then
        assertEquals(fixture.groupVideoEstablished, configuration)
    }

    // MARK: - Video Placeholder

    func testVideoPermissionsPlaceholderRespectsPreferenceInIncomingVideoCall() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockParticipants = mockCallParticipants(count: fixture.groupSize.rawValue, state: .connected(videoState: .started, microphoneState: .unmuted))

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .statusTextHidden, permissions: CallPermissions(), cameraType: .front)

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .statusTextHidden)
    }

    func testVideoPermissionsPlaceholderHiddenInIncomingAudioCall() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = false
        mockVoiceChannel.mockParticipants = mockCallParticipants(count: fixture.groupSize.rawValue, state: .connected(videoState: .started, microphoneState: .unmuted))

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .statusTextHidden, permissions: CallPermissions(), cameraType: .front)

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .hidden)
    }

    func testVideoPermissionsPlaceholderHiddenInEstablishedVideoCall() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockParticipants = mockCallParticipants(count: fixture.groupSize.rawValue, state: .connected(videoState: .started, microphoneState: .unmuted))

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .statusTextHidden, permissions: CallPermissions(), cameraType: .front)

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .hidden)
    }

}
