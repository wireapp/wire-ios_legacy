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

extension MockMessage: AudioTrack {

    public var title: String? {
        get {
            return .none
        }
    }
    public var author: String? {
        get {
            return .none
        }
    }

    public var duration: TimeInterval {
        get {
            return 9999
        }
    }

    public var streamURL: URL? {
        get {
            return .none
        }
    }

    public var previewStreamURL: URL? {
        get {
            return .none
        }
    }

    public var failedToLoad: Bool {
        get {
            return false
        }
        set {
            // no-op
        }
    }
}

final class AudioMessageViewTests: XCTestCase {

    var sut: AudioMessageView!
    var mediaPlaybackManager: MediaPlaybackManager!

    override func setUp() {
        super.setUp()

        let url = Bundle(for: type(of: self)).url(forResource: "audio_sample", withExtension: "m4a")!

        let audioMessage = MockMessageFactory.audioMessage(config: {
            $0.backingFileMessageData?.transferState = .uploaded
            $0.backingFileMessageData?.downloadState = .downloaded
            $0.backingFileMessageData.fileURL = url
        })

        mediaPlaybackManager = MediaPlaybackManager(name: "conversationMedia")
        sut = AudioMessageView(mediaPlaybackManager: mediaPlaybackManager)

        sut.audioTrackPlayer?.load(audioMessage, sourceMessage: audioMessage)
        sut.configure(for: audioMessage, isInitial: true)
    }

    override func tearDown() {
        sut = nil
        mediaPlaybackManager = nil

        super.tearDown()
    }

    func testThatAudioMessageIsResumedAfterIncomingCallIsTerminated() {
        // GIVEN & WHEN

        // play
        sut.playButton.sendActions(for: .touchUpInside)
        XCTAssert((sut.audioTrackPlayer?.isPlaying)!)

        // THEN
        let incomingState = CallState.incoming(video: false, shouldRing: true, degraded: false)
        sut.callCenterDidChange(callState: incomingState, conversation: ZMConversation(), caller: ZMUser(), timestamp: nil, previousCallState: nil)

        XCTAssertFalse((sut.audioTrackPlayer?.isPlaying)!)

        sut.callCenterDidChange(callState: .terminating(reason: WireSyncEngine.CallClosedReason.normal), conversation: ZMConversation(), caller: ZMUser(), timestamp: nil, previousCallState: incomingState)

        XCTAssert((sut.audioTrackPlayer?.isPlaying)!)
    }

    func testThatAudioMessageIsNotResumedIfItIsPausedAfterIncomingCallIsTerminated() {
        // GIVEN & WHEN

        // play
        sut.playButton.sendActions(for: .touchUpInside)
        XCTAssert((sut.audioTrackPlayer?.isPlaying)!)

        // pause
        sut.playButton.sendActions(for: .touchUpInside)
        XCTAssertFalse((sut.audioTrackPlayer?.isPlaying)!)

        // THEN
        let incomingState = CallState.incoming(video: false, shouldRing: true, degraded: false)
        sut.callCenterDidChange(callState: incomingState, conversation: ZMConversation(), caller: ZMUser(), timestamp: nil, previousCallState: nil)

        XCTAssertFalse((sut.audioTrackPlayer?.isPlaying)!)

        sut.callCenterDidChange(callState: .terminating(reason: WireSyncEngine.CallClosedReason.normal), conversation: ZMConversation(), caller: ZMUser(), timestamp: nil, previousCallState: incomingState)

        XCTAssertFalse((sut.audioTrackPlayer?.isPlaying)!)
    }
}
