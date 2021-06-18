//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import avs

@testable import Wire

class MockAVSVideoPreview: AVSVideoPreview {
    var isCapturing: Bool = false

    override func startVideoCapture() {
        isCapturing = true
    }

    override func stopVideoCapture() {
        isCapturing = false
    }
}

class SelfCallParticipantViewTests: XCTestCase {
    var sut: SelfCallParticipantView!
    var stubProvider = StreamStubProvider()
    var previewViewMock = MockAVSVideoPreview()

    override func setUp() {
        super.setUp()

        let stream = stubProvider.stream()
        sut = SelfCallParticipantView(
            stream: stream,
            isCovered: false,
            shouldShowActiveSpeakerFrame: false,
            shouldShowBorderWhenVideoIsStopped: false,
            pinchToZoomRule: .enableWhenFitted
        )
        sut.previewView = previewViewMock
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testCapturerState_ForVideoState_Started() {
        // Given
        previewViewMock.isCapturing = false

        // When
        sut.updateCaptureState(with: .started)

        // Then
        XCTAssertTrue(previewViewMock.isCapturing)
    }

    func testCapturerState_ForVideoState_Stopped() {
        // Given
        previewViewMock.isCapturing = false

        // When
        sut.updateCaptureState(with: .stopped)

        // Then
        XCTAssertFalse(previewViewMock.isCapturing)
    }

    func testCapturerState_ForVideoState_Paused() {
        // Given
        previewViewMock.isCapturing = false

        // When
        sut.updateCaptureState(with: .paused)

        // Then
        XCTAssertFalse(previewViewMock.isCapturing)
    }

    func testCapturerState_ForVideoState_BadConnection() {
        // Given
        previewViewMock.isCapturing = false

        // When
        sut.updateCaptureState(with: .badConnection)

        // Then
        XCTAssertFalse(previewViewMock.isCapturing)
    }

    func testCapturerState_ForVideoState_ScreenSharing() {
        // Given
        previewViewMock.isCapturing = false

        // When
        sut.updateCaptureState(with: .screenSharing)

        // Then
        XCTAssertFalse(previewViewMock.isCapturing)
    }

    func testThatSettingStream_UpdatesCaptureState() {
        // Given
        previewViewMock.isCapturing = false

        // When
        sut.stream = stubProvider.stream(videoState: .started)

        // Then
        XCTAssertTrue(previewViewMock.isCapturing)
    }
}
