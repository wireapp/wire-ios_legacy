//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import Foundation
import XCTest
import SnapshotTesting

@testable import Wire

class CallParticipantViewTests: XCTestCase {
    var size = XCTestCase.DeviceSizeIPhone5
    var sut: CallParticipantView!
    var stubProvider = StreamStubProvider()
    var unmutedStream = StreamStubProvider().stream(muted: false)

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private func createView(from stream: Wire.Stream, isCovered: Bool, pinchToZoomRule: PinchToZoomRule = .enableWhenMaximized) -> CallParticipantView {
        let view = CallParticipantView(
            stream: stream,
            isCovered: isCovered,
            shouldShowActiveSpeakerFrame: true,
            shouldShowBorderWhenVideoIsStopped: true,
            pinchToZoomRule: pinchToZoomRule
        )
        view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        view.backgroundColor = .graphite
        return view
    }

    func testThatItShouldNotFill_WhenMaximized() {
        // GIVEN
        sut = createView(from: unmutedStream, isCovered: false)

        // WHEN
        sut.isMaximized = true

        // THEN
        XCTAssertFalse(sut.shouldFill)
    }

    func testThatItShouldFill_WhenSharingVideo_AndNotMaximized() {
        // GIVEN / WHEN
        sut = createView(from: unmutedStream, isCovered: false)

        // THEN
        XCTAssertTrue(sut.shouldFill)
    }

    func testThatItShouldNotFill_WhenScreenSharing_AndNotMaximized() {
        // GIVEN / WHEN
        let stream = stubProvider.stream(muted: false, videoState: .screenSharing)
        sut = createView(from: stream, isCovered: false)

        // THEN
        XCTAssertFalse(sut.shouldFill)
    }

    func testDefaultState() {
        // GIVEN / WHEN
        sut = createView(from: unmutedStream, isCovered: false)

        // THEN
        verify(matching: sut)
    }

    func testMutedState() {
        // GIVEN / WHEN
        let stream = stubProvider.stream(muted: true)
        sut = createView(from: stream, isCovered: false)

        // THEN
        verify(matching: sut)
    }

    func testActiveState() {
        // GIVEN / WHEN
        let stream = stubProvider.stream(muted: false, activeSpeakerState: .active(audioLevelNow: 100))
        sut = createView(from: stream, isCovered: false)

        // THEN
        verify(matching: sut)
    }

    func testPausedState() {
        // GIVEN
        sut = createView(from: unmutedStream, isCovered: false)

        // WHEN
        sut.isPaused = true

        // THEN
        verify(matching: sut)
    }

    func testVideoStoppedState() {
        // GIVEN
        let stream = stubProvider.stream(videoState: .stopped)
        sut = createView(from: stream, isCovered: false)

        // THEN
        verify(matching: sut)
    }

    func testVideoStoppedBorder_IsZero_WhenMaximized() {
        // GIVEN
        let stream = stubProvider.stream(videoState: .stopped)
        sut = createView(from: stream, isCovered: false)
        sut.layer.borderWidth = 1

        // WHEN
        sut.isMaximized = true

        // THEN
        XCTAssertEqual(sut.layer.borderWidth, 0)
    }

    func testCoveredState() {
        // GIVEN / WHEN
        sut = createView(from: unmutedStream, isCovered: true)

        // THEN
        verify(matching: sut)
    }

    func testOrientationUpsideDown() {
        testOrientation(.portraitUpsideDown)
    }

    func testOrientationLandscapeLeft() {
        testOrientation(.landscapeLeft)
    }

    func testOrientationLandscapeRight() {
        testOrientation(.landscapeRight)
    }

    func testOrientation(_ deviceOrientation: UIDeviceOrientation,
                         file: StaticString = #file,
                         testName: String = #function,
                         line: UInt = #line) {
        // GIVEN
        sut = createView(from: unmutedStream, isCovered: false)

        let view = UIView(frame: CGRect(origin: .zero, size: XCTestCase.DeviceSizeIPhone5))
        view.addSubview(sut)

        // WHEN
        sut.layout(forInterfaceOrientation: .portrait, deviceOrientation: deviceOrientation)

        // THEN
        verify(matching: view, file: file, testName: testName, line: line)
    }

    func testThat_ScalingIsDisabled_WhenRuleIs_EnableWhenFitted_And_ShouldFill_IsTrue() {
        // given - view is not maximized and videoState is .started, shouldFill will compute to true
        let stream = stubProvider.stream(videoState: .started)
        sut = createView(from: stream, isCovered: false, pinchToZoomRule: .enableWhenFitted)
        sut.isMaximized = false

        // then
        XCTAssertFalse(sut.scalableView!.isScalingEnabled)
    }

    func testThat_ScalingIsEnabled_WhenRuleIs_EnableWhenFitted_And_ShouldFill_IsFalse() {
        // given - view is maximized, shouldFill will compute to true
        sut = createView(from: unmutedStream, isCovered: false, pinchToZoomRule: .enableWhenFitted)
        sut.isMaximized = true

        // then
        XCTAssertTrue(sut.scalableView!.isScalingEnabled)
    }

    func testThat_ScalingIsDisabled_WhenRuleIs_EnableWhenMaximized_And_ViewIsNotMaximized() {
        // given
        sut = createView(from: unmutedStream, isCovered: false, pinchToZoomRule: .enableWhenMaximized)
        sut.isMaximized = false

        // then
        XCTAssertFalse(sut.scalableView!.isScalingEnabled)
    }

    func testThat_ScalingIsEnabled_WhenRuleIs_EnableWhenMaximized_And_ViewIsMaximized() {
        // given
        sut = createView(from: unmutedStream, isCovered: false, pinchToZoomRule: .enableWhenMaximized)
        sut.isMaximized = true

        // then
        XCTAssertTrue(sut.scalableView!.isScalingEnabled)
    }

}
