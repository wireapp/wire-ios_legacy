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

func ==(lhs: CallActionAppearance, rhs: CallActionAppearance) -> Bool {
    switch (lhs, rhs) {
    case (.light, .light): return true
    case let (.dark(blurred: lhsBlurred), .dark(blurred: rhsBlurred)): return lhsBlurred == rhsBlurred
    default: return false
    }
}

func ==(lhs: CallInfoViewControllerInput, rhs: CallInfoViewControllerInput) -> Bool {
    return lhs.degradationState == rhs.degradationState &&
        lhs.accessoryType == rhs.accessoryType &&
        lhs.appearance == rhs.appearance &&
        lhs.canAccept == rhs.canAccept &&
        lhs.canToggleMediaType == rhs.canToggleMediaType &&
        lhs.displayString == rhs.displayString &&
        lhs.isConstantBitRate == rhs.isConstantBitRate &&
        lhs.state == rhs.state &&
        lhs.mediaState == rhs.mediaState &&
        lhs.disableIdleTimer == rhs.disableIdleTimer
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
        selfUser = nil
        otherUser = nil
        
        super.tearDown()
    }
    
    func assertEquals(_ lhsConfig: CallInfoViewControllerInput, _ rhsConfig: CallInfoViewControllerInput, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(lhsConfig == rhsConfig, "\n\(lhsConfig)\n\nis not equal to\n\n\(rhsConfig)", file: file, line: line)
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
        // then
        assertEquals(fixture.oneToOneOutgoingAudioRinging, configuration)
    }
    
    func testOneToOneIncomingAudioDegraded() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        (mockConversation.activeParticipants.lastObject as? MockUser)?.untrusted = true
        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: true)
        mockVoiceChannel.mockInitiator = otherUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
        // then
        assertEquals(fixture.oneToOneIncomingAudioDegraded, configuration)
    }
    
    func testOneToOneOutgoingAudioDegraded() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        (mockConversation.activeParticipants.lastObject as? MockUser)?.untrusted = true
        mockVoiceChannel.mockCallState = .outgoing(degraded: true)
        mockVoiceChannel.mockInitiator = selfUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())

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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())

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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
        // then
        assertEquals(fixture.groupOutgoingAudioRinging, configuration)
    }
    
    func testGroupAudioConnecting() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
        // then
        assertEquals(fixture.groupAudioConnecting, configuration)
    }
    
    func testGroupAudioEstablished() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let mockUsers: [ZMUser] = MockUser.mockUsers()!
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockParticipants = NSOrderedSet(array: Array(mockUsers[0..<fixture.groupSize.rawValue]))
        mockVoiceChannel.mockCallParticipantState = .connected(videoState: .stopped)
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
        // then
        assertEquals(fixture.groupAudioEstablished, configuration)
    }
    
    func testGroupAudioEstablishedLargeGroup() {
        // given
        let mockGroupConversation = MockConversation.groupConversation()
        mockGroupConversation.canStartVideoCall = false
        
        let mockConversation = ((mockGroupConversation as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let mockUsers: [ZMUser] = MockUser.mockUsers()!
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockParticipants = NSOrderedSet(array: Array(mockUsers[0..<fixture.groupSize.rawValue]))
        mockVoiceChannel.mockCallParticipantState = .connected(videoState: .stopped)
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
        // then
        assertEquals(fixture.groupAudioEstablishedLargeGroup, configuration)
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
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
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
        // then
        assertEquals(fixture.groupVideoConnecting, configuration)
    }
    
    func testGroupVideoEstablished() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let mockUsers: [ZMUser] = MockUser.mockUsers()!
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started
        mockVoiceChannel.mockParticipants = NSOrderedSet(array: Array(mockUsers[0..<fixture.groupSize.rawValue]))
        mockVoiceChannel.mockCallParticipantState = .connected(videoState: .started)
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        
        // then
        assertEquals(fixture.groupVideoEstablished, configuration)
    }

    // MARK: - Video Placeholder

    func testVideoPermissionsPlaceholderRespectsPreferenceInIncomingVideoCall() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let mockUsers: [ZMUser] = MockUser.mockUsers()!
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockParticipants = NSOrderedSet(array: Array(mockUsers[0..<fixture.groupSize.rawValue]))
        mockVoiceChannel.mockCallParticipantState = .connected(videoState: .started)

        // when
        var configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        configuration.preferedVideoPlaceholderState = .statusTextHidden

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .statusTextHidden)
    }

    func testVideoPermissionsPlaceholderHiddenInIncomingAudioCall() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let mockUsers: [ZMUser] = MockUser.mockUsers()!
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = false
        mockVoiceChannel.mockParticipants = NSOrderedSet(array: Array(mockUsers[0..<fixture.groupSize.rawValue]))
        mockVoiceChannel.mockCallParticipantState = .connected(videoState: .started)

        // when
        var configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        configuration.preferedVideoPlaceholderState = .statusTextHidden

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .hidden)
    }

    func testVideoPermissionsPlaceholderHiddenInEstablishedVideoCall() {
        // given
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let mockUsers: [ZMUser] = MockUser.mockUsers()!
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockParticipants = NSOrderedSet(array: Array(mockUsers[0..<fixture.groupSize.rawValue]))
        mockVoiceChannel.mockCallParticipantState = .connected(videoState: .started)

        // when
        var configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions())
        configuration.preferedVideoPlaceholderState = .statusTextHidden

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .hidden)
    }

}

