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

final class VideoGridViewControllerSnapshotTests: ZMSnapshotTestCase {
    
    var sut: VideoGridViewController!
    var mediaManager: ZMMockAVSMediaManager!

    override func setUp() {
        super.setUp()
        mediaManager = ZMMockAVSMediaManager()
    }
    
    override func tearDown() {
        sut = nil
        mediaManager = nil
        super.tearDown()
    }

    func createSut(muted: Bool) {
        ZMUser.selfUser().remoteIdentifier = UUID()

        let conversation = (MockConversation.oneOnOneConversation() as Any) as! ZMConversation
        let voiceChannel = MockVoiceChannel(conversation: conversation)
        voiceChannel.mockVideoState = VideoState.started
        voiceChannel.mockIsVideoCall = true
        voiceChannel.mockCallState = CallState.established

        mediaManager.isMicrophoneMuted = muted

        let videoConfiguration = VideoConfiguration(voiceChannel: voiceChannel, mediaManager: mediaManager,  isOverlayVisible: false)
        sut = VideoGridViewController(configuration: videoConfiguration)

        sut.view.backgroundColor = .black
    }

    func testForMuted(){
        createSut(muted: true)

        sut.isCovered = false
        verify(view: sut.view)
    }
}
