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
    
    override func setUp() {
        super.setUp()
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        sut = MockVoiceChannel(conversation: mockConversation)
        mockUser1 = MockUser.mockUsers()[0]
        mockUser1.remoteIdentifier = UUID()
        mockUser2 = MockUser.mockUsers()[1]
        mockUser2.remoteIdentifier = UUID()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    private func participantStub(for user: ZMUser, videoEnabled: Bool) -> CallParticipant {
        let state: VideoState = videoEnabled ? .started : .stopped
        return CallParticipant(user: user, state: .connected(videoState: state, clientId: UUID().transportString()))
    }
    
    // MARK - participantsActiveVideoStates
    
    func testThatWithOneParticipantWithoutVideoItReturnsEmpty() {
        let participant = participantStub(for: mockUser1, videoEnabled: false)
        sut.mockParticipants = [participant]
        
        XCTAssert(sut.participantsActiveVideoStreams.isEmpty)
    }
    
    func testThatWithOneParticipantWithVideoItReturnsOneParticipantVideoState() {
        let participant = participantStub(for: mockUser1, videoEnabled: true)
        sut.mockParticipants = [participant]
        
        XCTAssert(sut.participantsActiveVideoStreams.count == 1)
    }
    
    func testThatWithTwoParticipantsWithoutVideoItReturnsEmpty() {
        let participant1 = participantStub(for: mockUser1, videoEnabled: false)
        let participant2 = participantStub(for: mockUser2, videoEnabled: false)
        
        sut.mockParticipants = [participant1, participant2]
        
        XCTAssert(sut.participantsActiveVideoStreams.isEmpty)
    }
    
    func testThatWithTwoParticipantsWithOneStartedAndOneStoppedVideoItReturnsOnlyOneVideoState() {
        let participant1 = participantStub(for: mockUser1, videoEnabled: false)
        let participant2 = participantStub(for: mockUser2, videoEnabled: true)
        
        sut.mockParticipants = [participant1, participant2]
        
        XCTAssert(sut.participantsActiveVideoStreams.count == 1)
    }
    
    func testThatWithTwoParticipantsWithTwoStartedVideosItReturnsTwoVideoStates() {
        let participant1 = participantStub(for: mockUser1, videoEnabled: true)
        let participant2 = participantStub(for: mockUser2, videoEnabled: true)
        
        sut.mockParticipants = [participant1, participant2]
        
        XCTAssert(sut.participantsActiveVideoStreams.count == 2)
    }
    
    // MARK - arrangeVideoStreams
    
    func videoStreamStub() -> VideoStream {
        return VideoStream(stream: Stream(userId: UUID(), clientId: UUID().transportString()), isPaused: false)
    }
    
    func testThatWithoutSelfStreamItReturnsNilPreviewAndParticipantsVideoStateGrid() {
        let participantVideoStreams = [videoStreamStub(), videoStreamStub()]
        
        let videoStreamArrangement = sut.arrangeVideoStreams(for: nil, participantsStreams: participantVideoStreams)
        XCTAssert(videoStreamArrangement.grid.elementsEqual(participantVideoStreams))
        XCTAssert(videoStreamArrangement.preview == nil)
    }
    
    func testThatWithSelfStreamAndOneParticipantItReturnsSelfStreamAsPreviewAndOtherParticipantsVideoStatesAsGrid() {
        let participantVideoStreams = [videoStreamStub()]
        let selfStream = videoStreamStub()
        
        let videoStreamArrangement = sut.arrangeVideoStreams(for: selfStream, participantsStreams: participantVideoStreams)
        XCTAssert(videoStreamArrangement.grid.elementsEqual(participantVideoStreams))
        XCTAssert(videoStreamArrangement.preview == selfStream)
    }
    
    func testThatWithSelfStreamAndMultipleParticipantsItReturnsNilAsPreviewAndSelfStreamPlusOtherParticipantsVideoStatesAsGrid()  {
        let participantVideoStreams = [videoStreamStub(), videoStreamStub()]
        let selfStream = videoStreamStub()
        
        let videoStreamArrangement = sut.arrangeVideoStreams(for: selfStream, participantsStreams: participantVideoStreams)
        let expectedStreams = [selfStream] + participantVideoStreams
        XCTAssert(videoStreamArrangement.grid.elementsEqual(expectedStreams))
        XCTAssert(videoStreamArrangement.preview == nil)
    }
}


