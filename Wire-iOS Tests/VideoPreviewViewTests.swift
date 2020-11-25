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
    
    var sut: VideoPreviewView!
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    private func stream(muted: Bool, videoState: VideoState = .started) -> Wire.Stream {
        let client = AVSClient(userId: UUID(), clientId: UUID().transportString())

        return Wire.Stream(
            streamId: client,
            participantName: "Bob",
            microphoneState: muted ? .muted : .unmuted,
            videoState: videoState
        )
    }
    
    private func createView(from stream: Wire.Stream, isCovered: Bool) -> VideoPreviewView {
        let view = VideoPreviewView(stream: stream, isCovered: isCovered)
        view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: XCTestCase.DeviceSizeIPhone5)
        view.backgroundColor = .graphite
        return view
    }
    
    func testThatItShouldNotFill_WhenMaximized() {
        // GIVEN
        sut = createView(from: stream(muted: false), isCovered: false)
        
        // WHEN
        sut.isMaximized = true
        
        // THEN
        XCTAssertFalse(sut.shouldFill)
    }
    
    func testThatItShouldFill_WhenSharingVideo_AndNotMaximized() {
        // GIVEN / WHEN
        sut = createView(from: stream(muted: false), isCovered: false)
        
        // THEN
        XCTAssertTrue(sut.shouldFill)
    }
    
    func testThatItShouldNotFill_WhenScreenSharing_AndNotMaximized() {
        // GIVEN / WHEN
        sut = createView(from: stream(muted: false, videoState: .screenSharing), isCovered: false)
        
        // THEN
        XCTAssertFalse(sut.shouldFill)
    }
    
    func testDefaultState() {
        // GIVEN / WHEN
        sut = createView(from: stream(muted: false), isCovered: false)
        
        // THEN
        verify(matching: sut)
    }
    
    func testMutedState() {
        // GIVEN / WHEN
        sut = createView(from: stream(muted: true), isCovered: false)
        
        // THEN
        verify(matching: sut)
    }
    
    func testPausedState() {
        // GIVEN
        sut = createView(from: stream(muted: false), isCovered: false)

        // WHEN
        sut.isPaused = true
        
        // THEN
        verify(matching: sut)
    }

    func testCoveredState() {
        // GIVEN / WHEN
        sut = createView(from: stream(muted: false), isCovered: true)
        
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
                         line: UInt = #line)
    {
        // GIVEN
        sut = createView(from: stream(muted: false), isCovered: false)

        let view = UIView(frame: CGRect(origin: .zero, size: XCTestCase.DeviceSizeIPhone5))
        view.addSubview(sut)
        
        // WHEN
        sut.layout(forInterfaceOrientation: .portrait, deviceOrientation: deviceOrientation)
        
        // THEN
        verify(matching: view, file: file, testName: testName, line: line)
    }
    
}
