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

class VideoPreviewViewTests: XCTestCase {
    var size = XCTestCase.DeviceSizeIPhone5
    var sut: VideoPreviewView!
    var stubProvider = VideoStreamStubProvider()
    var unmutedStream = VideoStreamStubProvider().videoStream(muted: false).stream

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private func createView(from stream: Wire.Stream, isCovered: Bool, pinchToZoomRule: PinchToZoomRule = .enableWhenMaximized) -> VideoPreviewView {
        let view = VideoPreviewView(
            stream: stream,
            isCovered: isCovered,
            shouldShowActiveSpeakerFrame: true,
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
        let stream = stubProvider.videoStream(muted: false, videoState: .screenSharing).stream
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
        let stream = stubProvider.videoStream(muted: true).stream
        sut = createView(from: stream, isCovered: false)

        // THEN
        verify(matching: sut)
    }

    func testActiveState() {
        // GIVEN / WHEN
        let stream = stubProvider.videoStream(muted: false, activeSpeakerState: .active(audioLevelNow: 100)).stream
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

    func testThatPinchGestureScalesViewUp() {
        // given
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.width))
        let scale: CGFloat = 2

        let gestureRecognizer = MockPinchGestureRecognizer(
            location: .zero,
            view: view,
            state: .changed,
            scale: scale
        )

        let location = CGPoint(x: -view.bounds.midX, y: -view.bounds.midY)
        let expectedTransform = view.transform
            .translatedBy(x: location.x, y: location.y)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -location.x, y: -location.y)

        sut = createView(from: unmutedStream, isCovered: false)

        // when
        sut.handlePinchGesture(gestureRecognizer)

        // then
        XCTAssert(view.transform == expectedTransform)
    }

    func testThatPinchGestureDoesntScaleViewDown() {
        // given
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.width))
        let scale: CGFloat = 0.5

        let gestureRecognizer = MockPinchGestureRecognizer(
            location: .zero,
            view: view,
            state: .changed,
            scale: scale
        )

        sut = createView(from: unmutedStream, isCovered: false)

        // when
        sut.handlePinchGesture(gestureRecognizer)

        // then
        XCTAssert(view.transform == .identity)
    }

    func testThatPanGestureTranslatesView_WhenViewIsScaled() {
        // given
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.width))
        view.transform = view.transform.scaledBy(x: 1.1, y: 1.1)

        let translation = CGPoint(x: 10, y: 10)
        let gestureRecongnizer = MockPanGestureRecognizer(
            location: view.center,
            translation: translation,
            view: view,
            state: .changed
        )

        let expectedTransform = view.transform.translatedBy(x: translation.x, y: translation.y)

        sut = createView(from: unmutedStream, isCovered: false)

        // when
        sut.handlePanGesture(gestureRecongnizer)

        // then
        XCTAssert(view.transform == expectedTransform)
    }

    func testThatPanGestureDoesntTranslateView_WhenViewIsNotScaled() {
        // given
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.width))

        let gestureRecongnizer = MockPanGestureRecognizer(
            location: view.center,
            translation: CGPoint(x: 10, y: 10),
            view: view,
            state: .changed
        )

        sut = createView(from: unmutedStream, isCovered: false)

        // when
        sut.handlePanGesture(gestureRecongnizer)

        // then
        XCTAssert(view.transform == .identity)
    }

    func testThat_GestureRecognizersAreDisabled_WhenRuleIs_EnableWhenFitted_And_ShouldFill_IsTrue() {
        // given - view is not maximized and videoState is .started, shouldFill will compute to true
        let stream = stubProvider.videoStream(videoState: .started).stream
        sut = createView(from: stream, isCovered: false, pinchToZoomRule: .enableWhenFitted)
        sut.isMaximized = false

        // then
        XCTAssertFalse(sut.panGesture.isEnabled)
        XCTAssertFalse(sut.pinchGesture.isEnabled)
    }

    func testThat_GestureRecognizersAreEnabled_WhenRuleIs_EnableWhenFitted_And_ShouldFill_IsFalse() {
        // given - view is maximized, shouldFill will compute to true
        sut = createView(from: unmutedStream, isCovered: false, pinchToZoomRule: .enableWhenFitted)
        sut.isMaximized = true

        // then
        XCTAssertTrue(sut.panGesture.isEnabled)
        XCTAssertTrue(sut.pinchGesture.isEnabled)
    }

    func testThat_GestureRecognizersAreDisabled_WhenRuleIs_EnableWhenMaximized_And_ViewIsNotMaximized() {
        // given
        sut = createView(from: unmutedStream, isCovered: false, pinchToZoomRule: .enableWhenMaximized)
        sut.isMaximized = false

        // then
        XCTAssertFalse(sut.panGesture.isEnabled)
        XCTAssertFalse(sut.pinchGesture.isEnabled)
    }

    func testThat_GestureRecognizersAreEnabled_WhenRuleIs_EnableWhenMaximized_And_ViewIsMaximized() {
        // given
        sut = createView(from: unmutedStream, isCovered: false, pinchToZoomRule: .enableWhenMaximized)
        sut.isMaximized = true

        // then
        XCTAssertTrue(sut.panGesture.isEnabled)
        XCTAssertTrue(sut.pinchGesture.isEnabled)
    }
}
