// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@testable import Wire

class AudioButtonOverlayTests: ZMSnapshotTestCase {

    var sut: AudioButtonOverlay!
    var buttonTapHistory: [AudioButtonOverlay.AudioButtonOverlayButtonType]!

    override func setUp() {
        super.setUp()
        buttonTapHistory = []
        sut = AudioButtonOverlay()
        sut.buttonHandler = { self.buttonTapHistory.append($0) }
    }

    override func tearDown() {
        buttonTapHistory = []
        sut = nil
        super.tearDown()
    }

    func testThatItRendersTheButtonOverlayCorrectInitially_Recording() {
        sut.setOverlayState(.default)
        verify(view: sut)
    }

    func testThatItRendersTheButtonOverlayCorrectInitially_FinishedRecording() {
        sut.recordingState = .finishedRecording
        sut.setOverlayState(.default)
        verify(view: sut)
    }

    func testThatItRendersTheButtonOverlayCorrectInitially_FinishedRecording_PlayingAudio() {
        sut.recordingState = .finishedRecording
        sut.playingState = .playing
        sut.setOverlayState(.default)
        verify(view: sut)
    }

    func testThatItChangesItsSize_Expanded() {
        sut.setOverlayState(.expanded(0))
        verify(view: sut)
    }

    func testThatItChangesItsSize_Expanded_Half() {
        sut.setOverlayState(.expanded(0.5))
        verify(view: sut)
    }

    func testThatItChangesItsSize_Expanded_Full() {
        sut.setOverlayState(.expanded(1))
        verify(view: sut)
    }

    func testThatItCallsTheButtonHandlerWithTheCorrectButtonType() {
        sut.playButton.sendActions(for: .touchUpInside)
        XCTAssertArrayEqual(buttonTapHistory, [AudioButtonOverlay.AudioButtonOverlayButtonType.play])

        sut.sendButton.sendActions(for: .touchUpInside)
        XCTAssertArrayEqual(buttonTapHistory, [AudioButtonOverlay.AudioButtonOverlayButtonType.play, AudioButtonOverlay.AudioButtonOverlayButtonType.send])
    }

}
