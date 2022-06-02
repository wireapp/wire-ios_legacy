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
@testable import WireSyncEngine

class CallParticipantsSnapshotTests: MessagingTest {

    private typealias Sut = WireSyncEngine.CallParticipantsSnapshot

    var mockWireCallCenterV3: WireCallCenterV3Mock!
    var mockFlowManager: FlowManagerMock!

    private var aliceIphone: AVSClient!
    private var aliceDesktop: AVSClient!
    private var bobIphone: AVSClient!
    private var bobDesktop: AVSClient!
    private var conversationId = AVSIdentifier.stub
    private var selfUser: ZMUser!
    private var user2: ZMUser!
    private var selfClient: UserClient!
    private var client1: UserClient!
    private var client2: UserClient!

    override func setUp() {
        super.setUp()
        mockFlowManager = FlowManagerMock()
        mockWireCallCenterV3 = WireCallCenterV3Mock(userId: AVSIdentifier.stub,
                                                    clientId: UUID().transportString(),
                                                    uiMOC: uiMOC,
                                                    flowManager: mockFlowManager,
                                                    transport: WireCallCenterTransportMock())

        let aliceId = AVSIdentifier.stub
        let bobId = AVSIdentifier.stub

        aliceIphone = AVSClient(userId: aliceId, clientId: "iphone")
        aliceDesktop = AVSClient(userId: aliceId, clientId: "desktop")
        bobIphone = AVSClient(userId: bobId, clientId: "iphone")
        bobDesktop = AVSClient(userId: bobId, clientId: "desktop")
    }

    override func tearDown() {
        mockFlowManager = nil
        mockWireCallCenterV3 = nil
        selfUser = nil
        selfClient = nil
        user2 = nil
        client1 = nil
        client2 = nil
        super.tearDown()
    }

    private func createSut(members: [AVSCallMember]) -> Sut {
        return Sut(conversationId: conversationId, members: members, callCenter: mockWireCallCenterV3)
    }

    // MARK: - Duplicates

    func testThat_ItDoesNotCrash_WhenInitialized_WithDuplicateCallMembers() {
        // Given
        let member1 = AVSCallMember(client: aliceIphone, audioState: .established)
        let member2 = AVSCallMember(client: aliceIphone, audioState: .connecting)

        // When
        let sut = createSut(members: [member1, member2])

        // Then
        XCTAssertEqual(sut.members.array, [member1])
    }

    func testThat_ItDoesNotCrash_WhenUpdated_WithDuplicateCallMembers() {
        // Given
        let member1 = AVSCallMember(client: aliceIphone, audioState: .established)
        let member2 = AVSCallMember(client: aliceIphone, audioState: .connecting)
        let sut = createSut(members: [])

        // when
        sut.callParticipantsChanged(participants: [member1, member2])

        // then
        XCTAssertEqual(sut.members.array, [member1])
    }

    func testThat_ItDoesNotConsider_AUserWithMultipleDevices_AsDuplicated() {
        // Given
        let member1 = AVSCallMember(client: aliceIphone, audioState: .established)
        let member2 = AVSCallMember(client: aliceDesktop, audioState: .connecting)

        // When
        let sut = createSut(members: [member1, member2])

        // Then
        XCTAssertEqual(sut.members.array, [member1, member2])
    }

    // MARK: - Network Quality

    func testThat_ItTakesTheWorstNetworkQuality_FromParticipants() {
        // Given
        let normalQuality = AVSCallMember(client: aliceIphone, networkQuality: .normal)
        let mediumQuality = AVSCallMember(client: aliceDesktop, networkQuality: .medium)
        let poorQuality = AVSCallMember(client: bobIphone, networkQuality: .poor)
        let problemQuality = AVSCallMember(client: bobDesktop, networkQuality: .problem)
        let sut = createSut(members: [])

        XCTAssertEqual(sut.networkQuality, .normal)

        // When, then
        sut.callParticipantsChanged(participants: [normalQuality])
        XCTAssertEqual(sut.networkQuality, .normal)

        // When, then
        sut.callParticipantsChanged(participants: [mediumQuality, normalQuality])
        XCTAssertEqual(sut.networkQuality, .medium)

        // When, then
        sut.callParticipantsChanged(participants: [poorQuality, normalQuality])
        XCTAssertEqual(sut.networkQuality, .poor)

        // When, then
        sut.callParticipantsChanged(participants: [poorQuality, normalQuality, problemQuality])
        XCTAssertEqual(sut.networkQuality, .problem)

        // When, then
        sut.callParticipantsChanged(participants: [mediumQuality, poorQuality])
        XCTAssertEqual(sut.networkQuality, .poor)

        // when
        sut.callParticipantsChanged(participants: [problemQuality, poorQuality])
        // then
        XCTAssertEqual(sut.networkQuality, .problem)
    }

    // MARK: - Updates

    func testThat_ItUpdatesNetworkQuality_WhenItChangesForParticipant() {
        // Given
        let member1 = AVSCallMember(client: aliceIphone, audioState: .established, networkQuality: .normal)
        let member2 = AVSCallMember(client: bobIphone, audioState: .established, networkQuality: .normal)
        let sut = createSut(members: [member1, member2])

        XCTAssertEqual(sut.networkQuality, .normal)

        // When, then
        sut.callParticipantNetworkQualityChanged(client: member1.client, networkQuality: .medium)
        XCTAssertEqual(sut.networkQuality, .medium)

        // When, then
        sut.callParticipantNetworkQualityChanged(client: member2.client, networkQuality: .poor)
        XCTAssertEqual(sut.networkQuality, .poor)

        // When, then
        sut.callParticipantNetworkQualityChanged(client: member1.client, networkQuality: .normal)
        sut.callParticipantNetworkQualityChanged(client: member2.client, networkQuality: .normal)
        XCTAssertEqual(sut.networkQuality, .normal)
    }

    func testThat_ItDoesNotUpdateNetworkQuality_WhenNoMatchFound() {
        // Given
        let member1 = AVSCallMember(client: aliceIphone, videoState: .stopped)
        let member2 = AVSCallMember(client: bobIphone, videoState: .stopped)
        let sut = createSut(members: [member1, member2])

        // When
        let unknownMember = AVSCallMember(client: aliceDesktop, videoState: .stopped)
        sut.callParticipantNetworkQualityChanged(client: unknownMember.client, networkQuality: .problem)

        // Then
        XCTAssertEqual(sut.members.array, [member1, member2])
    }

    func testThat_ItUpdatesAudioState_WhenItChangesForParticipant() {
        // Given
        let member1 = AVSCallMember(client: aliceIphone, audioState: .connecting)
        let member2 = AVSCallMember(client: bobIphone, audioState: .connecting)
        let sut = createSut(members: [member1, member2])

        // When
        let updatedMember1 = member1.with(audioState: .established)
        sut.callParticipantsChanged(participants: [updatedMember1, member2])

        // Then
        XCTAssertEqual(sut.members.array, [updatedMember1, member2])
    }

    func testThat_ItUpdatesVideoState_WhenItChangesForParticipant() {
        // Given
        let member1 = AVSCallMember(client: aliceIphone, videoState: .stopped)
        let member2 = AVSCallMember(client: bobIphone, videoState: .stopped)
        let sut = createSut(members: [member1, member2])

        // When
        let updatedMember1 = member1.with(videoState: .screenSharing)
        sut.callParticipantsChanged(participants: [updatedMember1, member2])

        // Then
        XCTAssertEqual(sut.members.array, [updatedMember1, member2])
    }

    func testThat_ItUpdateMicrophoneState_WhenItChangesForParticipant() {
        // Given
        let member1 = AVSCallMember(client: aliceIphone, microphoneState: .unmuted)
        let member2 = AVSCallMember(client: bobIphone, microphoneState: .unmuted)
        let sut = createSut(members: [member1, member2])

        // When
        let updatedMember1 = member1.with(microphoneState: .muted)
        sut.callParticipantsChanged(participants: [updatedMember1, member2])

        // Then
        XCTAssertEqual(sut.members.array, [updatedMember1, member2])
    }

    // MARK: - Call Degradation

    func testThat_ItDegradesCallSecurity_WithCorrectUser_WhenUserBecomesUnverified() {
        // Given / When
        setupCallSnapshot()
        setupUsersAndClients()
        setupDegradationTest(degradedClient: client2)

        // Then
        XCTAssertTrue(mockWireCallCenterV3.mockAVSWrapper.didCallEndCall)
        XCTAssertEqual(mockWireCallCenterV3.callSnapshots[conversationId]!.degradedUser, user2)
    }

    func testThat_ItDegradesCallSecurity_WithSelfUser_WhenSelfUserBecomesUnverified() {
        // Given
        setupCallSnapshot()
        setupUsersAndClients()
        setupDegradationTest(degradedClient: client1)

        // Then
        XCTAssertTrue(mockWireCallCenterV3.mockAVSWrapper.didCallEndCall)
        XCTAssertEqual(mockWireCallCenterV3.callSnapshots[conversationId]!.degradedUser, selfUser)
    }

    func setupCallSnapshot() {
        mockWireCallCenterV3.callSnapshots[conversationId] = CallSnapshot(
            callParticipants: CallParticipantsSnapshot(conversationId: conversationId, members: [], callCenter: mockWireCallCenterV3),
            callState: .established,
            callStarter: aliceIphone.avsIdentifier,
            isVideo: false,
            isGroup: true,
            isConstantBitRate: false,
            videoState: .stopped,
            networkQuality: .normal,
            isConferenceCall: true,
            degradedUser: nil,
            activeSpeakers: [],
            videoGridPresentationMode: .allVideoStreams,
            conversationObserverToken: nil
        )
    }

    private func setupUsersAndClients() {
        performPretendingUiMocIsSyncMoc {
            self.selfUser = ZMUser.selfUser(in: self.uiMOC)
            self.selfUser.remoteIdentifier = self.aliceIphone.avsIdentifier.identifier

            self.selfClient = UserClient.insertNewObject(in: self.uiMOC)
            self.selfClient.user = self.selfUser
            self.selfClient.remoteIdentifier = self.aliceIphone.clientId
            self.uiMOC.setPersistentStoreMetadata(self.selfClient.remoteIdentifier, key: "PersistedClientId")

            self.client1 = UserClient.insertNewObject(in: self.uiMOC)
            self.client1.user = self.selfUser
            self.client1.remoteIdentifier = self.aliceDesktop.clientId

            self.user2 = ZMUser.fetchOrCreate(with: self.bobIphone.avsIdentifier.identifier, domain: nil, in: self.uiMOC)

            self.client2 = UserClient.insertNewObject(in: self.uiMOC)
            self.client2.user = self.user2
            self.client2.remoteIdentifier = self.bobIphone.clientId

            self.uiMOC.saveOrRollback()
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    private func setupDegradationTest(degradedClient: UserClient) {
        // Given
        let sut = createSut(members: [])

        // trust clients
        client2.trustClient(selfClient)
        selfClient.trustClients([client1, client2])

        // Create call members
        let member1 = AVSCallMember(client: aliceIphone, microphoneState: .unmuted)
        let member2 = AVSCallMember(client: bobIphone, microphoneState: .unmuted)

        // setup participants list
        sut.callParticipantsChanged(participants: [member1, member2])

        // When
        selfClient.ignoreClient(degradedClient)
        sut.callParticipantsChanged(participants: [member1, member2])
    }
}

private extension AVSCallMember {

    func with(audioState: AudioState) -> AVSCallMember {
        return AVSCallMember(client: client,
                             audioState: audioState,
                             videoState: videoState,
                             microphoneState: microphoneState,
                             networkQuality: networkQuality)
    }

    func with(videoState: VideoState) -> AVSCallMember {
        return AVSCallMember(client: client,
                             audioState: audioState,
                             videoState: videoState,
                             microphoneState: microphoneState,
                             networkQuality: networkQuality)
    }

    func with(microphoneState: MicrophoneState) -> AVSCallMember {
        return AVSCallMember(client: client,
                             audioState: audioState,
                             videoState: videoState,
                             microphoneState: microphoneState,
                             networkQuality: networkQuality)
    }

}
