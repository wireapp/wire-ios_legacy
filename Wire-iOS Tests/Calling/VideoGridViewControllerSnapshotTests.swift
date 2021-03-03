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
import SnapshotTesting

final class MockVideoGridConfiguration: VideoGridConfiguration {
    var shouldShowActiveSpeakerFrame: Bool = true

    var floatingVideoStream: VideoStream?

    var videoStreams: [VideoStream] = []

    var videoState: VideoState = .stopped

    var networkQuality: NetworkQuality = .normal

    var presentationMode: VideoGridPresentationMode = .allVideoStreams
}

final class VideoGridViewControllerSnapshotTests: XCTestCase {

    var sut: VideoGridViewController!
    var mediaManager: ZMMockAVSMediaManager!
    var configuration: MockVideoGridConfiguration!
    var selfVideoStream: VideoStream!
    var stubProvider = VideoStreamStubProvider()

    override func setUp() {
        super.setUp()
        mediaManager = ZMMockAVSMediaManager()
        configuration = MockVideoGridConfiguration()

        let mockSelfClient = MockUserClient()
        mockSelfClient.remoteIdentifier = "selfClient123"
        MockUser.mockSelf().clients = Set([mockSelfClient])

        let client = AVSClient(userId: MockUser.mockSelf().remoteIdentifier, clientId: mockSelfClient.remoteIdentifier!)
        selfVideoStream = stubProvider.videoStream(
            participantName: "Alice",
            client: client,
            activeSpeakerState: .active(audioLevelNow: 100)
        )
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

    func testNoActiveSpeakersSpinner() {
        configuration.videoStreams = []
        configuration.presentationMode = .activeSpeakers

        createSut()

        verify(matching: sut)
    }

    func testActiveSpeakersIndicators_OneToOne() {
        configuration.videoStreams = [stubProvider.videoStream(participantName: "Bob", activeSpeakerState: .active(audioLevelNow: 100))]
        configuration.floatingVideoStream = selfVideoStream
        configuration.shouldShowActiveSpeakerFrame = false
        createSut()

        verify(matching: sut)
    }

    func testActiveSpeakersIndicators_Conference() {
        configuration.videoStreams = [
            stubProvider.videoStream(participantName: "Alice", activeSpeakerState: .active(audioLevelNow: 100)),
            stubProvider.videoStream(participantName: "Bob", activeSpeakerState: .active(audioLevelNow: 100)),
            stubProvider.videoStream(participantName: "Carol", activeSpeakerState: .active(audioLevelNow: 100))
        ]
        createSut()

        verify(matching: sut)
    }

    func testForBadNetwork() {
        configuration.networkQuality = .poor
        createSut()
        verify(matching: sut)
    }
}
