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

struct MockCallGridViewControllerInput: CallGridViewControllerInput, Equatable {

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
    var mockHintView: MockCallGridHintNotificationLabel!
    var allParticipantsNames = ["Alice", "Bob", "Carol", "Chuck", "Craig", "Dan", "Erin", "Eve", "Faythe"]

    override func setUp() {
        super.setUp()
        accentColor = .strongBlue
        mediaManager = ZMMockAVSMediaManager()
        configuration = MockCallGridViewControllerInput()
        mockHintView = MockCallGridHintNotificationLabel()

        let mockSelfClient = MockUserClient()
        mockSelfClient.remoteIdentifier = "selfClient123"
        MockUser.mockSelf().clients = Set([mockSelfClient])

        let identifier = AVSIdentifier(identifier: MockUser.mockSelf().remoteIdentifier,
                                       domain: nil)

        selfAVSClient = AVSClient(userId: identifier,
                                  clientId: mockSelfClient.remoteIdentifier!)

        selfStream = stubProvider.stream(
            user: MockUserType.createUser(name: "Alice"),
            client: selfAVSClient,
            activeSpeakerState: .active(audioLevelNow: 100)
        )

        CallingConfiguration.config = .largeConferenceCalls
    }

    override func tearDown() {
        sut = nil
        mediaManager = nil
        mockHintView = nil
        CallingConfiguration.resetDefaultConfig()

        super.tearDown()
    }

    func createSut(hideHintView: Bool = true, delegate: MockCallGridViewControllerDelegate? = nil) {
        sut = CallGridViewController(configuration: configuration,
                                      mediaManager: mediaManager)

        sut.isCovered = false
        sut.view.backgroundColor = .black
        sut.delegate = delegate
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
        allParticipantsNames.prefixed(by: 3).forEach {
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
        allParticipantsNames.prefixed(by: 3).forEach {
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
        allParticipantsNames.forEach {
            configuration.streams += [stubProvider.stream(user: MockUserType.createUser(name: $0))]
        }

        // when
        createSut()

        // then
        verify(matching: sut)
    }

    // MARK: - Hint update

    func testThat_ItUpdatesHint() {

        // Maximization

        assertHint(
            input: .maximizationChanged(state: .maximized(isSharingVideo: true)),
            output: .show(hint: .goBackOrZoom)
        )

        assertHint(
            input: .maximizationChanged(state: .maximized(isSharingVideo: false)),
            output: .show(hint: .goBack)
        )

        assertHint(
            input: .maximizationChanged(state: .notMaximized),
            output: .hideHintAndStopTimer
        )

        // Configuration Changed

        assertHint(
            input: .configurationChanged(participants: .moreThanTwo),
            output: .showNothing
        )

        assertHint(
            input: .configurationChanged(participants: .two(videoState: .notSharing)),
            output: .showNothing
        )

        assertHint(
            input: .configurationChanged(participants: .two(videoState: .screenSharing)),
            output: .show(hint: .zoom)
        )

        assertHint(
            input: .configurationChanged(participants: .two(videoState: .sharing(isMaximized: true))),
            output: .show(hint: .goBackOrZoom)
        )

        assertHint(
            input: .configurationChanged(participants: .two(videoState: .sharing(isMaximized: false))),
            output: .showNothing
        )

        // View Did Load

        assertHint(
            input: .viewDidLoad,
            output: .show(hint: .fullscreen)
        )
    }

    // MARK: - Selective video

    func testThatItRequestsVideoStreams_ForParticipantsOnGivenPageWithVideoEnabled() {
        // given
        let mockDelegate = MockCallGridViewControllerDelegate()
        createSut(delegate: mockDelegate)

        var configuration = MockCallGridViewControllerInput()

        // Page 1 - video enabled
        for _ in 0..<CallGridViewController.maxItemsPerPage {
            configuration.streams += [stubProvider.stream(videoState: .started)]
        }

        // Page 2 - First half with video disabled
        let half = CallGridViewController.maxItemsPerPage / 2
        for _ in 0..<half {
            configuration.streams += [stubProvider.stream(videoState: .stopped)]
        }

        // Page 2 - Second half with video enabled
        var expectedClients = [AVSClient]()
        for _ in half..<CallGridViewController.maxItemsPerPage {
            let client = AVSClient(userId: AVSIdentifier.stub, clientId: UUID().transportString())
            configuration.streams += [stubProvider.stream(client: client, videoState: .started)]
            expectedClients += [client]
        }

        sut.configuration = configuration

        // when
        sut.requestVideoStreamsIfNeeded(forPage: 1)

        // then
        XCTAssertEqual(mockDelegate.requestedClients, expectedClients)
    }

    func testThatItDoesntRequestVideoStreams_IfPageIsInvalid() {
        // given
        let mockDelegate = MockCallGridViewControllerDelegate()
        var configuration = MockCallGridViewControllerInput()

        createSut(delegate: mockDelegate)

        // this will be one page's worth of streams
        for _ in 0..<CallGridViewController.maxItemsPerPage {
            configuration.streams += [stubProvider.stream(videoState: .started)]
        }

        sut.configuration = configuration
        mockDelegate.requestedClients = nil

        // when - we request video streams for a second page that doesn't exist
        sut.requestVideoStreamsIfNeeded(forPage: 1) // pages start from 0

        // then
        XCTAssertNil(mockDelegate.requestedClients)
    }

}

extension CallGridViewControllerSnapshotTests {

    private func assertHint(input: HintTestCase.Input, output: HintTestCase.Output, file: StaticString = #file, line: UInt = #line) {
        mockHintView.didCallHideAndStopTimer = false
        mockHintView.hint = nil

        var maximizedView: BaseCallParticipantView?
        if case let .configurationChanged(participants) = input {
            configuration.callHasTwoParticipants = participants.isTwo

            if let stream = participants.stream {
                configuration.streams = [stream]

                if case let .two(videoState) = participants, videoState.isMaximized {
                    maximizedView = BaseCallParticipantView(
                        stream: stream,
                        isCovered: false,
                        shouldShowActiveSpeakerFrame: true,
                        shouldShowBorderWhenVideoIsStopped: true,
                        pinchToZoomRule: .enableWhenFitted
                    )
                }
            }
        }

        createSut()
        sut.maximizedView = maximizedView
        sut.hintView = mockHintView

        sut.updateHint(for: input.event)

        output.assert(mockHintView: mockHintView)
    }

    private struct HintTestCase {
        enum Input {
            case configurationChanged(participants: Participants)
            case maximizationChanged(state: MaximizationState)
            case viewDidLoad

            var event: Wire.CallGridEvent {
                switch self {
                case .maximizationChanged(state: let state):
                    return .maximizationChanged(stream: state.stream, maximized: state.isMaximized)
                case .configurationChanged:
                    return .configurationChanged
                default:
                    return .viewDidLoad
                }
            }

            enum Participants: Equatable {
                case two(videoState: VideoState)
                case moreThanTwo

                var isTwo: Bool { self != .moreThanTwo }

                var stream: Wire.Stream? {
                    switch self {
                    case .two(videoState: let videoState):
                        return videoState.stream
                    case .moreThanTwo:
                        return nil
                    }
                }

                enum VideoState: Equatable {
                    case screenSharing
                    case sharing(isMaximized: Bool)
                    case notSharing

                    var isMaximized: Bool {
                        switch self {
                        case .sharing(isMaximized: let isMaximized):
                            return isMaximized
                        default:
                            return false
                        }
                    }

                    var stream: Wire.Stream {
                        StreamStubProvider().stream(videoState: videoState)
                    }

                    private var videoState: WireSyncEngine.VideoState {
                        switch self {
                        case .notSharing:
                            return .stopped
                        case .sharing:
                            return .started
                        case .screenSharing:
                            return .screenSharing
                        }
                    }
                }
            }

            enum MaximizationState: Equatable {
                case notMaximized
                case maximized(isSharingVideo: Bool)

                var stream: Wire.Stream {
                    let stubProvider = StreamStubProvider()

                    switch self {
                    case .maximized(isSharingVideo: let isSharingVideo):
                        return stubProvider.stream(videoState: isSharingVideo ? .started : .stopped)
                    case .notMaximized:
                        return stubProvider.stream()
                    }
                }

                var isMaximized: Bool { self != .notMaximized }
            }

        }

        enum Output {
            case show(hint: CallGridHintKind)
            case showNothing
            case hideHintAndStopTimer

            func assert(mockHintView: MockCallGridHintNotificationLabel, file: StaticString = #file, line: UInt = #line) {
                switch self {
                case .show(hint: let hint):
                    XCTAssertEqual(mockHintView.hint, hint, file: file, line: line)
                case .showNothing:
                    XCTAssertNil(mockHintView.hint, file: file, line: line)
                case .hideHintAndStopTimer:
                    XCTAssertTrue(mockHintView.didCallHideAndStopTimer, file: file, line: line)
                }
            }
        }
    }
}
