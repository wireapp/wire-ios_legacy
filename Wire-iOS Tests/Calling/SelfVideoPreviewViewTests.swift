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

class SelfVideoPreviewViewTests: XCTestCase {
    var sut: SelfVideoPreviewView!
    var stubProvider = VideoStreamStubProvider()
    var previewViewMock = MockAVSVideoPreview()
    
    override func setUp() {
        super.setUp()
        
        let stream = stubProvider.videoStream().stream
        sut = SelfVideoPreviewView(stream: stream, isCovered: false, shouldShowActiveSpeakerFrame: false)
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
        sut.stream = stubProvider.videoStream(videoState: .started).stream

        // Then
        XCTAssertTrue(previewViewMock.isCapturing)
    }
    
    func testCapturerState_ForVideoState_Stopped() {
        // Given
        previewViewMock.isCapturing = false
        
        // When
        sut.stream = stubProvider.videoStream(videoState: .stopped).stream
        
        // Then
        XCTAssertFalse(previewViewMock.isCapturing)
    }
    
    func testCapturerState_ForVideoState_Paused() {
        // Given
        previewViewMock.isCapturing = false
        
        // When
        sut.stream = stubProvider.videoStream(videoState: .paused).stream
        
        // Then
        XCTAssertFalse(previewViewMock.isCapturing)
    }
    
    func testCapturerState_ForVideoState_BadConnection() {
        // Given
        previewViewMock.isCapturing = false
        
        // When
        sut.stream = stubProvider.videoStream(videoState: .badConnection).stream
        
        // Then
        XCTAssertFalse(previewViewMock.isCapturing)
    }
    
    func testCapturerState_ForVideoState_ScreenSharing() {
        // Given
        previewViewMock.isCapturing = false
        
        // When
        sut.stream = stubProvider.videoStream(videoState: .screenSharing).stream
        
        // Then
        XCTAssertFalse(previewViewMock.isCapturing)
    }
}
