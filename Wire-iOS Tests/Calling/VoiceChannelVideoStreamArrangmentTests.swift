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

class VoiceChannelVideoStreamArrangementTests: XCTestCase {
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
    }
    
    override func tearDown() {
        sut = nil
        mockUser1 = nil
        mockUser2 = nil
        mockUser3 = nil
        super.tearDown()
    }
    
    private func participantStub(for user: ZMUser, videoEnabled: Bool) -> CallParticipant {
        let state: VideoState = videoEnabled ? .started : .stopped
        return CallParticipant(user: user, clientId: UUID().transportString(), state: .connected(videoState: state, microphoneState: .unmuted), isActiveSpeaker: false)
    }
    
    // MARK: - activeVideoStreams(from participants:)
    
    func testThatActiveVideoStreams_ReturnsEmpty_ForOneParticipantWithoutVideo() {
        // GIVEN
        let participant = participantStub(for: mockUser1, videoEnabled: false)
        
        // THEN
        XCTAssert(sut.activeVideoStreams(from: [participant]).isEmpty)
    }
    
    func testThatActiveVideoStreams_ReturnsOneParticipantVideoState_ForOneParticipantWithVideo() {
        // GIVEN
        let participant = participantStub(for: mockUser1, videoEnabled: true)
        
        // WHEN
        let videoStreams = sut.activeVideoStreams(from: [participant])
        
        // THEN
        XCTAssert(videoStreams.count == 1)
        XCTAssert(videoStreams.first?.stream.streamId.userId == remoteId1)
    }
    
    func testThatActiveVideoStreams_ReturnsEmpty_ForTwoParticipantsWithoutVideo() {
        // GIVEN
        let participants = [
            participantStub(for: mockUser1, videoEnabled: false),
            participantStub(for: mockUser2, videoEnabled: false)
        ]
        
        // THEN
        XCTAssert(sut.activeVideoStreams(from: participants).isEmpty)
    }
    
    func testThatActiveVideoStreams_ReturnsOneVideoStream_ForTwoParticipantsWithOneStartedAndOneStoppedVideo() {
        // GIVEN
        let participants = [
            participantStub(for: mockUser1, videoEnabled: false),
            participantStub(for: mockUser2, videoEnabled: true)
        ]

        // WHEN
        let videoStreams = sut.activeVideoStreams(from: participants)
        
        // THEN
        XCTAssert(videoStreams.count == 1)
        XCTAssert(videoStreams.first?.stream.streamId.userId == remoteId2)
    }
    
    func testThatActiveVideoStreams_ReturnsTwoVideoStreams_ForTwoParticipantsWithTwoStartedVideos() {
        // GIVEN
        let participants = [
            participantStub(for: mockUser1, videoEnabled: true),
            participantStub(for: mockUser2, videoEnabled: true)
        ]
        
        // WHEN
        let videoStreams = sut.activeVideoStreams(from: participants)
        
        // THEN
        XCTAssert(videoStreams.count == 2)
        XCTAssert(videoStreams.contains(where: {$0.stream.streamId.userId == remoteId1}))
        XCTAssert(videoStreams.contains(where: {$0.stream.streamId.userId == remoteId2}))
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
    
    func videoStreamStub(userId: UUID = UUID(), clientId: String = UUID().transportString()) -> VideoStream {
        let stream = Stream(streamId: AVSClient(userId: userId, clientId: clientId),
                            participantName: nil,
                            microphoneState: .none,
                            videoState: .none,
                            isParticipantActiveSpeaker: false)
        return VideoStream(stream: stream,
                           isPaused: false)
    }
    
    func setMockParticipants(with users: [ZMUser]) {
        sut.mockParticipants = []
        for user in users {
            sut.mockParticipants.append(participantStub(for: user, videoEnabled: false))
        }
    }
    
    func testThatItReturnsSelfPreviewAndParticipantInGrid_WhenOnlyTwoParticipants() {
        // GIVEN
        setMockParticipants(with: [mockUser1, mockSelfUser])
        
        let participantVideoStreams = [videoStreamStub()]
        let selfStream = videoStreamStub(userId: selfUserId, clientId: selfClientId)

        // WHEN
        let videoStreamArrangement = sut.arrangeVideoStreams(for: selfStream, participantsStreams: participantVideoStreams)
        
        // THEN
        XCTAssert(videoStreamArrangement.grid.elementsEqual(participantVideoStreams))
        XCTAssert(videoStreamArrangement.preview == selfStream)
    }

    func testThatItReturnsNilPreviewAndParticipantInGrid_WhenOnlyTwoParticipants_WithoutSelfStream() {
        // GIVEN
        setMockParticipants(with: [mockUser1, mockSelfUser])

        let participantVideoStreams = [videoStreamStub()]
        
        // WHEN
        let videoStreamArrangement = sut.arrangeVideoStreams(for: nil, participantsStreams: participantVideoStreams)
        
        // THEN
        XCTAssert(videoStreamArrangement.grid.elementsEqual(participantVideoStreams))
        XCTAssert(videoStreamArrangement.preview == nil)
    }
    
    func testThatItReturnsNilPreviewAndAllParticipantsInGrid_WhenOverTwoParticipants() {
        // GIVEN
        setMockParticipants(with: [mockUser1, mockUser2, mockSelfUser])
        
        let participantVideoStreams = [videoStreamStub()]
        let selfStream = videoStreamStub()
        
        // WHEN
        let videoStreamArrangement = sut.arrangeVideoStreams(for: selfStream, participantsStreams: participantVideoStreams)
        
        // THEN
        XCTAssert(videoStreamArrangement.grid.elementsEqual([selfStream] + participantVideoStreams))
        XCTAssert(videoStreamArrangement.preview == nil)
    }
}


