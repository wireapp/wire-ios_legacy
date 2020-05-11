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
    var remoteId1 = UUID()
    var remoteId2 = UUID()
    
    override func setUp() {
        super.setUp()
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        sut = MockVoiceChannel(conversation: mockConversation)
        mockUser1 = MockUser.mockUsers()[0]
        mockUser1.remoteIdentifier = remoteId1
        mockUser2 = MockUser.mockUsers()[1]
        mockUser2.remoteIdentifier = remoteId2
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    private func participantStub(for user: ZMUser, videoEnabled: Bool) -> CallParticipant {
        let state: VideoState = videoEnabled ? .started : .stopped
        return CallParticipant(user: user, clientId: UUID().transportString(), state: .connected(videoState: state))
    }
    
    // MARK - participantsActiveVideoStates
    
    func testThatWithOneParticipantWithoutVideoItReturnsEmpty() {
        // GIVEN
        let participant = participantStub(for: mockUser1, videoEnabled: false)
        sut.mockParticipants = [participant]
        
        // THEN
        XCTAssert(sut.participantsActiveVideoStreams.isEmpty)
    }
    
    func testThatWithOneParticipantWithVideoItReturnsOneParticipantVideoState() {
        // GIVEN
        let participant = participantStub(for: mockUser1, videoEnabled: true)
        sut.mockParticipants = [participant]
        
        // WHEN
        let videoStreams = sut.participantsActiveVideoStreams
        
        // THEN
        XCTAssert(videoStreams.count == 1)
        XCTAssert(videoStreams.first?.stream.userId == remoteId1)
    }
    
    func testThatWithTwoParticipantsWithoutVideoItReturnsEmpty() {
        // GIVEN
        let participant1 = participantStub(for: mockUser1, videoEnabled: false)
        let participant2 = participantStub(for: mockUser2, videoEnabled: false)
        sut.mockParticipants = [participant1, participant2]
        
        // THEN
        XCTAssert(sut.participantsActiveVideoStreams.isEmpty)
    }
    
    func testThatWithTwoParticipantsWithOneStartedAndOneStoppedVideoItReturnsOnlyOneVideoState() {
        // GIVEN
        let participant1 = participantStub(for: mockUser1, videoEnabled: false)
        let participant2 = participantStub(for: mockUser2, videoEnabled: true)
        sut.mockParticipants = [participant1, participant2]
        
        // WHEN
        let videoStreams = sut.participantsActiveVideoStreams
        
        // THEN
        XCTAssert(videoStreams.count == 1)
        XCTAssert(videoStreams.first?.stream.userId == remoteId2)
    }
    
    func testThatWithTwoParticipantsWithTwoStartedVideosItReturnsTwoVideoStates() {
        // GIVEN
        let participant1 = participantStub(for: mockUser1, videoEnabled: true)
        let participant2 = participantStub(for: mockUser2, videoEnabled: true)
        sut.mockParticipants = [participant1, participant2]
        
        // WHEN
        let videoStreams = sut.participantsActiveVideoStreams
        
        // THEN
        XCTAssert(videoStreams.count == 2)
        XCTAssert(videoStreams.contains(where: {$0.stream.userId == remoteId1}))
        XCTAssert(videoStreams.contains(where: {$0.stream.userId == remoteId2}))
    }
    
    // MARK - arrangeVideoStreams
    
    func videoStreamStub() -> VideoStream {
        return VideoStream(stream: Stream(userId: UUID(), clientId: UUID().transportString()), isPaused: false)
    }
    
    func testThatWithoutSelfStreamItReturnsNilPreviewAndParticipantsVideoStateGrid() {
        // GIVEN
        let participantVideoStreams = [videoStreamStub(), videoStreamStub()]
        
        // WHEN
        let videoStreamArrangement = sut.arrangeVideoStreams(for: nil, participantsStreams: participantVideoStreams)

        // THEN
        XCTAssert(videoStreamArrangement.grid.elementsEqual(participantVideoStreams))
        XCTAssert(videoStreamArrangement.preview == nil)
    }
    
    func testThatWithSelfStreamAndOneParticipantItReturnsSelfStreamAsPreviewAndOtherParticipantsVideoStatesAsGrid() {
        // GIVEN
        let participantVideoStreams = [videoStreamStub()]
        let selfStream = videoStreamStub()
        
        // WHEN
        let videoStreamArrangement = sut.arrangeVideoStreams(for: selfStream, participantsStreams: participantVideoStreams)

        // THEN
        XCTAssert(videoStreamArrangement.grid.elementsEqual(participantVideoStreams))
        XCTAssert(videoStreamArrangement.preview == selfStream)
    }
    
    func testThatWithSelfStreamAndMultipleParticipantsItReturnsNilAsPreviewAndSelfStreamPlusOtherParticipantsVideoStatesAsGrid()  {
        // GIVEN
        let participantVideoStreams = [videoStreamStub(), videoStreamStub()]
        let selfStream = videoStreamStub()
        let expectedStreams = [selfStream] + participantVideoStreams

        // WHEN
        let videoStreamArrangement = sut.arrangeVideoStreams(for: selfStream, participantsStreams: participantVideoStreams)

        // THEN
        XCTAssert(videoStreamArrangement.grid.elementsEqual(expectedStreams))
        XCTAssert(videoStreamArrangement.preview == nil)
    }
}


