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

final class MockAudioTrack: NSObject, AudioTrack {
    var title: String!

    var author: String!

    var artwork: UIImage!

    var duration: TimeInterval = 0.0

    var artworkURL: URL!

    var streamURL: URL!

    var previewStreamURL: URL!

    var externalURL: URL!

    var failedToLoad: Bool

    func fetchArtwork() {
        // no-op
    }

    override init() {
        failedToLoad = false
        super.init()
    }
}

final class AudioMessageViewTests: XCTestCase {
    
    var sut: AudioMessageView!
    
    override func setUp() {
        super.setUp()
        sut = AudioMessageView()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }



    /// Example checker method which can be reused in different tests
    fileprivate func checkerExample(file: StaticString = #file, line: UInt = #line) {
        XCTAssert(true, file: file, line: line)
    }

    func testExample(){
        // GIVEN
        let url = Bundle(for: type(of: self)).url(forResource: "audio_sample", withExtension: "m4a")!

        let audioMessage = MockMessageFactory.audioMessage(config: {
            $0.fileMessageData?.transferState = .downloaded
            $0.backingFileMessageData.fileURL = url
        })

        let mediaPlayBackManager = MediaPlaybackManager(name: "conversationMedia")
        sut.audioTrackPlayer = mediaPlayBackManager?.audioTrackPlayer
        let audioTrack = MockAudioTrack()
        sut.audioTrackPlayer?.load(audioTrack, sourceMessage: audioMessage, completionHandler: nil)
        sut.configure(for: audioMessage, isInitial: true)

        // WHEN

//        AudioTrack

//        mediaPlayBackManager.con

        sut.playButton.sendActions(for: .touchUpInside)
        XCTAssert((sut.audioTrackPlayer?.isPlaying)!)

        // THEN
        checkerExample()
    }
}
