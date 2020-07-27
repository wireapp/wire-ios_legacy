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
        return CallParticipant(user: user, clientId: UUID().transportString(), state: .connected(videoState: state, microphoneState: .unmuted))
    }
    
    // MARK - sortedActiveVideoStates
    
    func testThatWithOneParticipantWithoutVideoItReturnsEmpty() {
        // GIVEN
        let participant = participantStub(for: mockUser1, videoEnabled: false)
        sut.mockParticipants = [participant]
        
        // THEN
        XCTAssert(sut.sortedActiveVideoStreams.isEmpty)
    }
    
    func testThatWithOneParticipantWithVideoItReturnsOneParticipantVideoState() {
        // GIVEN
        let participant = participantStub(for: mockUser1, videoEnabled: true)
        sut.mockParticipants = [participant]
        
        // WHEN
        let videoStreams = sut.sortedActiveVideoStreams
        
        // THEN
        XCTAssert(videoStreams.count == 1)
        XCTAssert(videoStreams.first?.stream.streamId.userId == remoteId1)
    }
    
    func testThatWithTwoParticipantsWithoutVideoItReturnsEmpty() {
        // GIVEN
        let participant1 = participantStub(for: mockUser1, videoEnabled: false)
        let participant2 = participantStub(for: mockUser2, videoEnabled: false)
        sut.mockParticipants = [participant1, participant2]
        
        // THEN
        XCTAssert(sut.sortedActiveVideoStreams.isEmpty)
    }
    
    func testThatWithTwoParticipantsWithOneStartedAndOneStoppedVideoItReturnsOnlyOneVideoState() {
        // GIVEN
        let participant1 = participantStub(for: mockUser1, videoEnabled: false)
        let participant2 = participantStub(for: mockUser2, videoEnabled: true)
        sut.mockParticipants = [participant1, participant2]
        
        // WHEN
        let videoStreams = sut.sortedActiveVideoStreams
        
        // THEN
        XCTAssert(videoStreams.count == 1)
        XCTAssert(videoStreams.first?.stream.streamId.userId == remoteId2)
    }
    
    func testThatWithTwoParticipantsWithTwoStartedVideosItReturnsTwoVideoStates() {
        // GIVEN
        let participant1 = participantStub(for: mockUser1, videoEnabled: true)
        let participant2 = participantStub(for: mockUser2, videoEnabled: true)
        sut.mockParticipants = [participant1, participant2]
        
        // WHEN
        let videoStreams = sut.sortedActiveVideoStreams
        
        // THEN
        XCTAssert(videoStreams.count == 2)
        XCTAssert(videoStreams.contains(where: {$0.stream.streamId.userId == remoteId1}))
        XCTAssert(videoStreams.contains(where: {$0.stream.streamId.userId == remoteId2}))
    }

    func testThatItSortsPartipantsByNameAlphabetically() {
        // GIVEN
        let participant1 = participantStub(for: mockUser1, videoEnabled: true)
        let participant2 = participantStub(for: mockUser2, videoEnabled: true)
        let participant3 = participantStub(for: mockUser3, videoEnabled: true)
        sut.mockParticipants = [participant1, participant2, participant3]

        // WHEN
        let videoStreams = sut.sortedActiveVideoStreams

        // THEN
        let streamUserIds = videoStreams.map(\.stream.streamId.userId)
        XCTAssertEqual(streamUserIds.count, 3)
        XCTAssertEqual(streamUserIds[0], remoteId2)
        XCTAssertEqual(streamUserIds[1], remoteId1)
        XCTAssertEqual(streamUserIds[2], remoteId3)
    }
    
    // MARK - arrangeVideoStreams
    
    func videoStreamStub() -> VideoStream {
        let stream = Stream(streamId: AVSClient(userId: UUID(), clientId: UUID().transportString()),
                            participantName: nil,
                            microphoneState: .none)
        return VideoStream(stream: stream,
                           isPaused: false)
    }
    
    func testThatItReturnsSelfPreviewAndParticipantInGrid_OneOnOneConversation() {
        // GIVEN
        let participantVideoStreams = [videoStreamStub()]
        let selfStream = videoStreamStub()
        sut.conversation?.conversationType = .oneOnOne
        
        // WHEN
        let videoStreamArrangement = sut.arrangeVideoStreams(for: selfStream, participantsStreams: participantVideoStreams)
        
        // THEN
        XCTAssert(videoStreamArrangement.grid.elementsEqual(participantVideoStreams))
        XCTAssert(videoStreamArrangement.preview == selfStream)
    }
    
    func testThatItReturnsNilPreviewAndAllParticipantsInGrid_GroupConversation() {
        // GIVEN
        let participantVideoStreams = [videoStreamStub()]
        let selfStream = videoStreamStub()
        sut.conversation?.conversationType = .group
        
        // WHEN
        let videoStreamArrangement = sut.arrangeVideoStreams(for: selfStream, participantsStreams: participantVideoStreams)
        
        // THEN
        XCTAssert(videoStreamArrangement.grid.elementsEqual([selfStream] + participantVideoStreams))
        XCTAssert(videoStreamArrangement.preview == nil)
    }
    
    func testThatItReturnsNilPreviewAndParticipantInGrid_WithoutSelfStream() {
        // GIVEN
        let participantVideoStreams = [videoStreamStub()]
        sut.conversation?.conversationType = .oneOnOne
        
        // WHEN
        let videoStreamArrangement = sut.arrangeVideoStreams(for: nil, participantsStreams: participantVideoStreams)
        
        // THEN
        XCTAssert(videoStreamArrangement.grid.elementsEqual(participantVideoStreams))
        XCTAssert(videoStreamArrangement.preview == nil)
    }
}


