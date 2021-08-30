//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

class VoiceChannelStreamArrangementTests: XCTestCase {
    private var sut: MockVoiceChannel!
    var mockUser1: ZMUser!
    var mockUser2: ZMUser!
    var mockUser3: ZMUser!
    var remoteId1 = UUID()
    var remoteId2 = UUID()
    var remoteId3 = UUID()

    var mockSelfUser: ZMUser!
    var selfUserId = UUID()
    var selfClientId = UUID().transportString()

    var stubProvider = StreamStubProvider()

    override func setUp() {
        super.setUp()
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        sut = MockVoiceChannel(conversation: mockConversation)
        mockUser1 = MockUser.mockUsers()[0]
        mockUser1.remoteIdentifier = remoteId1
        mockUser1.name = "bob"
        mockUser2 = MockUser.mockUsers()[1]
        mockUser2.remoteIdentifier = remoteId2
        mockUser2.name = "Alice"
        mockUser3 = MockUser.mockUsers()[2]
        mockUser3.remoteIdentifier = remoteId3
        mockUser3.name = "Cate"

        let userClient = MockUserClient()
        userClient.remoteIdentifier = selfClientId

        // Workaround to have the self user mock be of ZMUser type.
        mockSelfUser = MockUser.mockUsers()[3]
        MockUser.setMockSelf(mockSelfUser)
        MockUser.mockSelf()?.remoteIdentifier = selfUserId
        MockUser.mockSelf()?.clients = [userClient]
        MockUser.mockSelf()?.isSelfUser = true

        CallingConfiguration.config = .largeConferenceCalls
    }

    override func tearDown() {
        sut = nil
        mockUser1 = nil
        mockUser2 = nil
        mockUser3 = nil
        CallingConfiguration.resetDefaultConfig()
        super.tearDown()
    }

    private func participantStub(for user: ZMUser, videoEnabled: Bool) -> CallParticipant {
        let state: VideoState = videoEnabled ? .started : .stopped
        return CallParticipant(user: user, clientId: UUID().transportString(), state: .connected(videoState: state, microphoneState: .unmuted), activeSpeakerState: .inactive)
    }

    // MARK: - activeVideoStreams(from participants:)

    func testThatActiveStreams_ReturnsSteams_ForParticipantsWithVideo(enabled: Bool) {
        // GIVEN
        let participants = [
            participantStub(for: mockUser1, videoEnabled: enabled),
            participantStub(for: mockUser2, videoEnabled: enabled)
        ]

        // WHEN
        let streams = sut.activeStreams(from: participants)

        // THEN
        XCTAssertEqual(streams.count, 2)
        XCTAssertTrue(streams.contains(where: {$0.streamId.userId == remoteId1}))
        XCTAssertTrue(streams.contains(where: {$0.streamId.userId == remoteId2}))
    }

    func testThatActiveStreams_ReturnsVideoStreams_ForParticipantsWithVideo() {
       testThatActiveStreams_ReturnsSteams_ForParticipantsWithVideo(enabled: true)
    }

    func testThatActiveStreams_ReturnsVideoStreams_ForParticipantsWithoutVideo() {
        testThatActiveStreams_ReturnsSteams_ForParticipantsWithVideo(enabled: false)
    }

    // MARK: - participants(for presentationMode:)

    func testThatParticipants_ForMode_AllVideoStreams_SortsPartipantsByNameAlphabetically() {
        // GIVEN
        let participant1 = participantStub(for: mockUser1, videoEnabled: true)
        let participant2 = participantStub(for: mockUser2, videoEnabled: true)
        let participant3 = participantStub(for: mockUser3, videoEnabled: true)
        sut.mockParticipants = [participant1, participant2, participant3]

        // WHEN
        let participants = sut.participants(forPresentationMode: .allVideoStreams)

        // THEN
        let userIds = participants.map(\.userId)
        XCTAssertEqual(userIds.count, 3)
        XCTAssertEqual(userIds[0], remoteId2)
        XCTAssertEqual(userIds[1], remoteId1)
        XCTAssertEqual(userIds[2], remoteId3)
    }

    func testThatParticipants_ForMode_AllVideoStreams_GetsParticipantsList_OfKind_All() {
        // GIVEN
        sut.requestedCallParticipantsListKind = nil

        // WHEN
        _ = sut.participants(forPresentationMode: .allVideoStreams)

        // THEN
        XCTAssertEqual(sut.requestedCallParticipantsListKind, CallParticipantsListKind.all)
    }

    func testThatParticipants_ForMode_ActiveSpeakers_GetsParticipantsList_OfKind_SmoothedActiveSpeakers() {
        // GIVEN
        sut.requestedCallParticipantsListKind = nil

        // WHEN
        _ = sut.participants(forPresentationMode: .activeSpeakers)

        // THEN
        XCTAssertEqual(sut.requestedCallParticipantsListKind, CallParticipantsListKind.smoothedActiveSpeakers)
    }

    // MARK: - arrangeVideoStreams(for selfStream:participantsStreams:)

    func setMockParticipants(with users: [ZMUser]) {
        sut.mockParticipants = []
        for user in users {
            sut.mockParticipants.append(participantStub(for: user, videoEnabled: false))
        }
    }

    func testThatItReturnsSelfPreviewAndParticipantInGrid_WhenOnlyTwoParticipants() {
        // GIVEN
        setMockParticipants(with: [mockUser1, mockSelfUser])

        let participantStreams = [stubProvider.stream()]
        let selfStream = stubProvider.stream(client: AVSClient(userId: selfUserId, clientId: selfClientId))

        // WHEN
        let streamArrangement = sut.arrangeStreams(for: selfStream, participantsStreams: participantStreams)

        // THEN
        XCTAssert(streamArrangement.grid.elementsEqual(participantStreams))
        XCTAssert(streamArrangement.preview == selfStream)
    }

    func testThatItReturnsNilPreviewAndParticipantInGrid_WhenOnlyTwoParticipants_WithoutSelfStream() {
        // GIVEN
        setMockParticipants(with: [mockUser1, mockSelfUser])

        let participantStreams = [stubProvider.stream()]

        // WHEN
        let streamArrangement = sut.arrangeStreams(for: nil, participantsStreams: participantStreams)

        // THEN
        XCTAssert(streamArrangement.grid.elementsEqual(participantStreams))
        XCTAssert(streamArrangement.preview == nil)
    }

    func testThatItReturnsNilPreviewAndAllParticipantsInGrid_WhenOverTwoParticipants() {
        // GIVEN
        setMockParticipants(with: [mockUser1, mockUser2, mockSelfUser])

        let participantStreams = [stubProvider.stream()]
        let selfStream = stubProvider.stream()

        // WHEN
        let streamArrangement = sut.arrangeStreams(for: selfStream, participantsStreams: participantStreams)

        // THEN
        XCTAssert(streamArrangement.grid.elementsEqual([selfStream] + participantStreams))
        XCTAssert(streamArrangement.preview == nil)
    }
}
