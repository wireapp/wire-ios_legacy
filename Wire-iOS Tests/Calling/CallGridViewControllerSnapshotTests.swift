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
    var selfAVSClient: AVSClient!
    var stubProvider = StreamStubProvider()
    var conferenceParticipants =  ["Alice", "Bob", "Carol"]
    var mockHintView: MockCallGridHintNotificationLabel!

    override func setUp() {
        super.setUp()
        accentColor = .strongBlue
        mediaManager = ZMMockAVSMediaManager()
        configuration = MockCallGridViewControllerInput()
        mockHintView = MockCallGridHintNotificationLabel()

        let mockSelfClient = MockUserClient()
        mockSelfClient.remoteIdentifier = "selfClient123"
        MockUser.mockSelf().clients = Set([mockSelfClient])

        selfAVSClient = AVSClient(userId: MockUser.mockSelf().remoteIdentifier, clientId: mockSelfClient.remoteIdentifier!)
        selfStream = stubProvider.stream(
            user: MockUserType.createUser(name: "Alice"),
            client: selfAVSClient,
            activeSpeakerState: .active(audioLevelNow: 100)
        )
    }

    override func tearDown() {
        sut = nil
        mediaManager = nil
        mockHintView = nil

        super.tearDown()
    }

    func createSut(hideHintView: Bool = true) {
        sut = CallGridViewController(configuration: configuration,
                                      mediaManager: mediaManager)

        sut.isCovered = false
        sut.view.backgroundColor = .black
        if hideHintView { sut.hideHintView() }
    }

    // MARK: - Snapshots

    func testNoActiveSpeakersSpinner() {
        configuration.streams = []
        configuration.presentationMode = .activeSpeakers

        createSut()

        verify(matching: sut)
    }

    func testActiveSpeakersIndicators_OneToOne() {
        // Given / When
        configuration.streams = [stubProvider.stream(
            user: MockUserType.createUser(name: "Bob"),
            activeSpeakerState: .active(audioLevelNow: 100)
        )]
        configuration.floatingStream = selfStream
        configuration.shouldShowActiveSpeakerFrame = false
        createSut()

        // Then
        verify(matching: sut)
    }

    func testActiveSpeakersIndicators_Conference() {
        // Given / When
        conferenceParticipants.forEach {
            configuration.streams += [stubProvider.stream(
                user: MockUserType.createUser(name: $0),
                activeSpeakerState: .active(audioLevelNow: 100)
            )]
        }

        createSut()

        // Then
        verify(matching: sut)
    }

    func testVideoStoppedBorder_DoesntAppear_OneToOne() {
        // Given / When
        configuration.streams = [stubProvider.stream(videoState: .stopped)]
        configuration.floatingStream = stubProvider.stream(
            user: MockUserType.createUser(name: "Alice"),
            client: selfAVSClient,
            videoState: .stopped
        )
        createSut()

        // Then
        verify(matching: sut)
    }

    func testVideoStoppedBorder_Appears_Conference() {
        // Given / When
        conferenceParticipants.forEach {
            configuration.streams += [stubProvider.stream(
                user: MockUserType.createUser(name: $0),
                videoState: .stopped
            )]
        }

        createSut()

        // Then
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

    func testPagingIndicator() {
        // given
        ["Alice", "Bob", "Carol", "Chuck", "Craig", "Dan", "Erin", "Eve", "Faythe"].forEach {
            configuration.streams += [stubProvider.stream(user: MockUserType.createUser(name: $0))]
        }

        // when
        createSut()

        // then
        verify(matching: sut)
    }

    // MARK: - Hint update

    func testThat_HintIs_Fullscreen_ForViewDidLoad() {
        // given
        createSut()
        sut.hintView = mockHintView

        // when
        sut.updateHint(for: .viewDidLoad)

        // then
        XCTAssertEqual(mockHintView.hint, .fullscreen)
    }

    func testThat_HintIs_Nil_ForConfigurationChanged_MoreThanTwoParticipants() {
        // given
        configuration.callHasTwoParticipants = false
        createSut()
        sut.hintView = mockHintView

        // when
        sut.updateHint(for: .configurationChanged)

        // then
        XCTAssertNil(mockHintView.hint)
    }

    func testThat_HintIs_Nil_ForConfigurationChanged_TwoParticipants_NotSharingVideo() {
        // given
        configuration.callHasTwoParticipants = true
        configuration.streams = [stubProvider.stream(videoState: .stopped)]
        createSut()
        sut.hintView = mockHintView

        // when
        sut.updateHint(for: .configurationChanged)

        // then
        XCTAssertNil(mockHintView.hint)
    }

    func testThat_HintIs_Zoom_ForConfigurationChanged_TwoParticipants_Screensharing() {
        // given
        configuration.callHasTwoParticipants = true
        configuration.streams = [stubProvider.stream(videoState: .screenSharing)]
        createSut()
        sut.hintView = mockHintView

        // when
        sut.updateHint(for: .configurationChanged)

        // then
        XCTAssertEqual(mockHintView.hint, .zoom)
    }

    func testThat_HintIs_GoBackOrZoom_ForConfigurationChanged_TwoParticipants_SharingVideo_Maximized() {
        // given
        let stream = stubProvider.stream(videoState: .started)
        let view = BaseCallParticipantView(stream: stream, isCovered: false, shouldShowActiveSpeakerFrame: true, shouldShowBorderWhenVideoIsStopped: true, pinchToZoomRule: .enableWhenFitted)

        configuration.callHasTwoParticipants = true
        configuration.streams = [stream]
        createSut()
        sut.maximizedView = view
        sut.hintView = mockHintView

        // when
        sut.updateHint(for: .configurationChanged)

        // then
        XCTAssertEqual(mockHintView.hint, .goBackOrZoom)
    }

    func testThat_HintIs_GoBackOrZoom_ForMaximizationChanged_Maximized_SharingVideo() {
        // given
        createSut()
        sut.hintView = mockHintView

        // when
        sut.updateHint(for: .maximizationChanged(stream: stubProvider.stream(videoState: .started), maximized: true))

        // then
        XCTAssertEqual(mockHintView.hint, .goBackOrZoom)
    }

    func testThat_HintIs_GoBack_ForMaximizationChanged_Maximized_NotSharingVideo() {
        // given
        createSut()
        sut.hintView = mockHintView

        // when
        sut.updateHint(for: .maximizationChanged(stream: stubProvider.stream(videoState: .stopped), maximized: true))

        // then
        XCTAssertEqual(mockHintView.hint, .goBack)
    }

    func testThat_ItHidesHintAndStopsTimer_ForMaximizationChanged_NotMaximized() {
        // given
        createSut()
        sut.hintView = mockHintView

        // when
        sut.updateHint(for: .maximizationChanged(stream: stubProvider.stream(videoState: .stopped), maximized: false))

        // then
        XCTAssertTrue(mockHintView.didCallHideAndStopTimer)
    }
}
