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
import WireSyncEngine

func ==(lhs: CallInfoViewControllerInput, rhs: CallInfoViewControllerInput) -> Bool {
    return lhs.isEqual(toConfiguration: rhs)
}

final class CallInfoConfigurationTests: XCTestCase {

    var mockOtherUser: MockUserType!
    var mockSelfUser: MockUserType!
    var mockUsers: [MockUserType]!

    override func setUp() {
        super.setUp()

        mockSelfUser = MockUserType.createSelfUser(name: "Bob")
        mockUsers = SwiftMockLoader.mockUsers()
        mockOtherUser = mockUsers.first!
    }

    override func tearDown() {
        mockSelfUser = nil
        mockOtherUser = nil
        mockUsers = nil

        super.tearDown()
    }

    func assertEquals(_ lhsConfig: CallInfoViewControllerInput, _ rhsConfig: CallInfoViewControllerInput, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(lhsConfig == rhsConfig,
                      "\n\(lhsConfig)\n\nis not equal to\n\n\(rhsConfig)",
                      file: file,
                      line: line)
    }

    private func mockCallParticipants(mockUsers: [MockUserType], count: Int, state: CallParticipantState) -> [CallParticipant] {
        return (mockUsers[0..<count]).map({ CallParticipant(user: $0,
                                                                       userId: UUID(),
                                                                       clientId: "123",
                                                                       state: state,
                                                                       activeSpeakerState: .inactive) })
    }

    // MARK: - OneToOne Audio

    func testOneToOneIncomingAudioRinging() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneIncomingAudioRinging, configuration)
    }

    func testOneToOneOutgoingAudioRinging() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = mockSelfUser

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneOutgoingAudioRinging, configuration)
    }

    func testOneToOneIncomingAudioDegraded() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        ((mockConversation.sortedActiveParticipants.first as Any) as? MockUser)?.isTrusted = true
        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: true)
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockFirstDegradedUser = mockOtherUser

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneIncomingAudioDegraded, configuration)
    }

    func testOneToOneOutgoingAudioDegraded() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        ((mockConversation.sortedActiveParticipants.first as Any) as? MockUser)?.isTrusted = true
        mockVoiceChannel.mockCallState = .outgoing(degraded: true)
        mockVoiceChannel.mockInitiator = mockSelfUser
        mockVoiceChannel.mockFirstDegradedUser = mockOtherUser

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneOutgoingAudioDegraded, configuration)
    }

    func testOneToOneAudioConnecting() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneAudioConnecting, configuration)
    }

    func testOneToOneAudioEstablishedUpgradedToVideo() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.videoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneVideoEstablished, configuration)
    }

    func testOneToOneAudioEstablished() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockCallDuration = 10

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneAudioEstablished, configuration)
    }

    func testOneToOneAudioEstablishedCBR() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockIsConstantBitRateAudioActive = true

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: true, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneAudioEstablishedCBR, configuration)
    }

    func testOneToOneAudioEstablishedVBR() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockIsConstantBitRateAudioActive = false

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: true, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneAudioEstablishedVBR, configuration)
    }

    // MARK: - OneToOne Video

    func testOneToOneIncomingVideoRinging() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneIncomingVideoRinging, configuration)
    }

    func testOneToOneIncomingVideoRingingVideoTurnedOff() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .stopped

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .statusTextHidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneIncomingVideoRingingVideoTurnedOff, configuration)
    }

    func testOneToOneOutgoingVideoRinging() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = mockSelfUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneOutgoingVideoRinging, configuration)
    }

    func testOneToOneVideoConnecting() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneVideoConnecting, configuration)
    }

    func testOneToOneVideoEstablished() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started
        mockVoiceChannel.mockCallDuration = 10

        let permissions = MockCallPermissions()
        permissions.canAcceptVideoCalls = true
        permissions.isPendingVideoPermissionRequest = false

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneVideoEstablished, configuration)
    }

    func testOneToOneVideoEstablishedWithScreenSharing() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .screenSharing
        mockVoiceChannel.mockCallDuration = 10

        let permissions = MockCallPermissions()
        permissions.canAcceptVideoCalls = true
        permissions.isPendingVideoPermissionRequest = false

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneVideoEstablished, configuration)
    }

    func testOneToOneVideoEstablishedDowngradedToAudio() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .stopped
        mockVoiceChannel.mockCallDuration = 10

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneAudioEstablished, configuration)
    }

    // MARK: - Group Audio
    
    private func createMockGroupConversation() -> ZMConversation {
        return ((MockConversation.groupConversation(selfUser: mockSelfUser,
                                                    otherUser: mockOtherUser) as Any) as! ZMConversation)
    }

    func testGroupIncomingAudioRinging() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.groupIncomingAudioRinging, configuration)
    }

    func testGroupOutgoingAudioRinging() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = mockSelfUser

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.groupOutgoingAudioRinging, configuration)
    }

    func testGroupAudioConnecting() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)
        mockSelfUser.teamIdentifier = UUID()

        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.groupAudioConnecting, configuration)
    }

    func testGroupAudioEstablished() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)
        mockSelfUser.teamIdentifier = UUID()

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = mockSelfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(mockUsers: mockUsers, count: fixture.groupSize.rawValue, state: .connected(videoState: .stopped, microphoneState: .unmuted))

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false,
                                                  selfUser: mockSelfUser)

        // then
        assertEquals(fixture.groupAudioEstablished(mockUsers: mockUsers), configuration)
    }

    func testGroupAudioEstablishedNonTeamUser() {
        // given
        let mockConversation = (MockConversation.groupConversation(selfUser: mockSelfUser,
                                                                    otherUser: mockOtherUser) as Any) as! ZMConversation

        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)

        mockOtherUser.teamIdentifier = nil
        mockSelfUser.teamIdentifier = nil

        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = mockSelfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(mockUsers: mockUsers, count: fixture.groupSize.rawValue, state: .connected(videoState: .stopped, microphoneState: .unmuted))

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.groupAudioEstablishedVideoUnavailable(mockUsers: mockUsers), configuration)//canToggleMediaType
    }

    func testGroupAudioEstablishedNonTeamUserRemoteTurnedVideoOn() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = mockSelfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(mockUsers: mockUsers, count: fixture.groupSize.rawValue, state: .connected(videoState: .started, microphoneState: .unmuted))

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.groupAudioEstablishedRemoteTurnedVideoOn(mockUsers: mockUsers), configuration)
    }

    func testGroupAudioEstablishedLargeGroup() {
        // given        
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, groupSize: .large, mockUsers: mockUsers)

        let mockGroupConversation = MockConversation.groupConversation(otherUser: mockOtherUser)
        mockGroupConversation.sortedActiveParticipants = Array(mockUsers[0..<fixture.groupSize.rawValue])

        let mockConversation = ((mockGroupConversation as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)

        mockSelfUser.teamIdentifier = UUID()

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = mockSelfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(mockUsers: mockUsers, count: fixture.groupSize.rawValue, state: .connected(videoState: .stopped, microphoneState: .unmuted))

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.groupAudioEstablishedVideoUnavailable(mockUsers: mockUsers), configuration)
    }

    func testOneToOneIncomingVideoRingingWithVideoPermissionsDeniedForever() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoDeniedForever, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneIncomingVideoRingingWithPermissionsDeniedForever, configuration)
    }

    func testOneToOneIncomingVideoRingingWithUndeterminedVideoPermissions() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation(otherUser: mockOtherUser) as Any) as! ZMConversation)
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoPendingApproval, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.oneToOneIncomingVideoRingingWithUndeterminedVideoPermissions, configuration)
    }

    // MARK: - Group Video

    func testGroupIncomingVideoRinging() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.groupIncomingVideoRinging, configuration)
    }

    func testGroupOutgoingVideoRinging() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = mockSelfUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.groupOutgoingVideoRinging, configuration)
    }

    func testGroupVideoConnecting() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.groupVideoConnecting, configuration)
    }

    func testGroupVideoEstablished() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = mockSelfUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started
        mockVoiceChannel.mockParticipants = mockCallParticipants(mockUsers: mockUsers, count: fixture.groupSize.rawValue, state: .connected(videoState: .started, microphoneState: .unmuted))

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .hidden, permissions: MockCallPermissions.videoAllowedForever, cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        assertEquals(fixture.groupVideoEstablished(mockUsers: mockUsers), configuration)
    }

    // MARK: - Video Placeholder

    func testVideoPermissionsPlaceholderRespectsPreferenceInIncomingVideoCall() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockParticipants = mockCallParticipants(mockUsers: mockUsers, count: fixture.groupSize.rawValue, state: .connected(videoState: .started, microphoneState: .unmuted))

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .statusTextHidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .statusTextHidden)
    }

    func testVideoPermissionsPlaceholderHiddenInIncomingAudioCall() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = false
        mockVoiceChannel.mockParticipants = mockCallParticipants(mockUsers: mockUsers, count: fixture.groupSize.rawValue, state: .connected(videoState: .started, microphoneState: .unmuted))

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .statusTextHidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .hidden)
    }

    func testVideoPermissionsPlaceholderHiddenInEstablishedVideoCall() {
        // given
        let mockConversation = createMockGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = mockOtherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockParticipants = mockCallParticipants(mockUsers: mockUsers, count: fixture.groupSize.rawValue, state: .connected(videoState: .started, microphoneState: .unmuted))

        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel, preferedVideoPlaceholderState: .statusTextHidden, permissions: CallPermissions(), cameraType: .front, userEnabledCBR: false, selfUser: mockSelfUser)

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .hidden)
    }

}
