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

final class MockVideoGridConfiguration: VideoGridConfiguration {
    var isCallOneToOne: Bool = false
    
    var floatingVideoStream: VideoStream?

    var videoStreams: [VideoStream] = []

    var networkQuality: NetworkQuality = .normal
}

final class VideoGridViewControllerSnapshotTests: ZMSnapshotTestCase {
    
    var sut: VideoGridViewController!
    var mediaManager: ZMMockAVSMediaManager!
    var configuration: MockVideoGridConfiguration!
    var selfVideoStream: VideoStream!

    override func setUp() {
        super.setUp()
        recordMode = true
        mediaManager = ZMMockAVSMediaManager()
        configuration = MockVideoGridConfiguration()
        
        let mockSelfClient = MockUserClient()
        mockSelfClient.remoteIdentifier = "selfClient123"
        MockUser.mockSelf().clients = Set([mockSelfClient])
        
        let selfStream = Wire.Stream(
            streamId: AVSClient(userId: MockUser.mockSelf().remoteIdentifier, clientId: mockSelfClient.remoteIdentifier!),
            participantName: "Alice",
            microphoneState: .unmuted,
            videoState: .started,
            isParticipantActiveSpeaker: true
        )
        selfVideoStream = VideoStream(stream: selfStream, isPaused: false)
    }
    
    override func tearDown() {
        sut = nil
        mediaManager = nil

        super.tearDown()
    }

    func createSut() {
        sut = VideoGridViewController(configuration: configuration,
                                      mediaManager: mediaManager)
        sut.isCovered = false
        sut.view.backgroundColor = .black
    }
    
    func videoStream(participantName: String) -> VideoStream {
        let stream = Wire.Stream(
            streamId: AVSClient(userId: UUID(), clientId: UUID().uuidString),
            participantName: participantName,
            microphoneState: .unmuted,
            videoState: .started,
            isParticipantActiveSpeaker: true
        )
        return VideoStream(stream: stream, isPaused: false)
    }
    
    func testForActiveSpeakers_OneToOne() {

        let stream = Wire.Stream(
            streamId: AVSClient(userId: UUID(), clientId: UUID().uuidString),
            participantName: "Alice",
            microphoneState: .unmuted,
            videoState: .started,
            isParticipantActiveSpeaker: true
        )
        let videoStream = VideoStream(stream: stream, isPaused: false)
        
        configuration.videoStreams = [videoStream]
        configuration.floatingVideoStream = selfVideoStream
        configuration.isCallOneToOne = true
        createSut()

        verify(view: sut.view)
    }
    
    func testForActiveSpeakers_Conference() {
        
    }

    func testForBadNetwork(){
        configuration.networkQuality = .poor
        createSut()
        verify(view: sut.view)
    }
}
