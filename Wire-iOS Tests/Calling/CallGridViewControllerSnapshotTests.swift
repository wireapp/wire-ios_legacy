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

final class MockCallGridViewControllerInput: CallGridViewControllerInput {
    var shouldShowActiveSpeakerFrame: Bool = true

    var floatingStream: Wire.Stream?

    var streams: [Wire.Stream] = []

    var videoState: VideoState = .stopped

    var networkQuality: NetworkQuality = .normal

    var presentationMode: VideoGridPresentationMode = .allVideoStreams

    var callHasTwoParticipants: Bool = false
}

final class CallGridViewControllerSnapshotTests: XCTestCase {

    var sut: CallGridViewController!
    var mediaManager: ZMMockAVSMediaManager!
    var configuration: MockCallGridViewControllerInput!
    var selfStream: Wire.Stream!
    var stubProvider = StreamStubProvider()

    override func setUp() {
        super.setUp()
        accentColor = .strongBlue
        mediaManager = ZMMockAVSMediaManager()
        configuration = MockCallGridViewControllerInput()

        let mockSelfClient = MockUserClient()
        mockSelfClient.remoteIdentifier = "selfClient123"
        MockUser.mockSelf().clients = Set([mockSelfClient])

        let client = AVSClient(userId: MockUser.mockSelf().remoteIdentifier, clientId: mockSelfClient.remoteIdentifier!)
        selfStream = stubProvider.stream(
            user: MockUserType.createUser(name: "Alice"),
            client: client,
            activeSpeakerState: .active(audioLevelNow: 100)
        )
    }

    override func tearDown() {
        sut = nil
        mediaManager = nil

        super.tearDown()
    }

    func createSut(hideHintView: Bool = true) {
        sut = CallGridViewController(configuration: configuration,
                                      mediaManager: mediaManager)

        sut.isCovered = false
        sut.view.backgroundColor = .black
        if hideHintView { sut.hideHintView() }
    }

    func testNoActiveSpeakersSpinner() {
        configuration.streams = []
        configuration.presentationMode = .activeSpeakers

        createSut()

        verify(matching: sut)
    }

    func testActiveSpeakersIndicators_OneToOne() {
        configuration.streams = [stubProvider.stream(
            user: MockUserType.createUser(name: "Bob"),
            activeSpeakerState: .active(audioLevelNow: 100)
        )]
        configuration.floatingStream = selfStream
        configuration.shouldShowActiveSpeakerFrame = false
        createSut()

        verify(matching: sut)
    }

    func testActiveSpeakersIndicators_Conference() {
        configuration.streams = [
            stubProvider.stream(user: MockUserType.createUser(name: "Alice"),
                                activeSpeakerState: .active(audioLevelNow: 100)),
            stubProvider.stream(user: MockUserType.createUser(name: "Bob"),
                                activeSpeakerState: .active(audioLevelNow: 100)),
            stubProvider.stream(user: MockUserType.createUser(name: "Carol"),
                                activeSpeakerState: .active(audioLevelNow: 100))
        ]
        createSut()

        verify(matching: sut)
    }

    func testForBadNetwork() {
        // given / when
        configuration.networkQuality = .poor
        createSut()

        // then
        verify(matching: sut)
    }

    func testHintView() {
        // given / when
        createSut(hideHintView: false)

        // then
        verify(matching: sut)
    }

    func testHintViewWithNetworkQualityView() {
        // given / when
        configuration.networkQuality = .poor
        createSut(hideHintView: false)

        // then
        verify(matching: sut)
    }

    func disable_testPagingIndicator() {
        configuration.streams = [
            stubProvider.stream(user: MockUserType.createUser(name: "Alice")),
            stubProvider.stream(user: MockUserType.createUser(name: "Bob")),
            stubProvider.stream(user: MockUserType.createUser(name: "Carol")),
            stubProvider.stream(user: MockUserType.createUser(name: "Chuck")),
            stubProvider.stream(user: MockUserType.createUser(name: "Craig")),
            stubProvider.stream(user: MockUserType.createUser(name: "Dan")),
            stubProvider.stream(user: MockUserType.createUser(name: "Erin")),
            stubProvider.stream(user: MockUserType.createUser(name: "Eve")),
            stubProvider.stream(user: MockUserType.createUser(name: "Faythe"))
        ]
        createSut()

        verify(matching: sut)
    }
}
