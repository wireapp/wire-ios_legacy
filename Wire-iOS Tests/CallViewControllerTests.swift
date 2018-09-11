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

extension XCTestCase {
    public func verifyDeallocation<T: AnyObject>(of instanceGenerator: () -> (T)) {
        weak var weakInstance: T? = nil
        var instance: T? = nil

        autoreleasepool {
            instance = instanceGenerator()
            // then
            weakInstance = instance
            XCTAssertNotNil(weakInstance)
            // when
            instance = nil
        }

        XCTAssertNil(instance)
        XCTAssertNil(weakInstance)
    }
}

extension XCTestCase {
    static func CreateCallViewController(mediaManager: ZMMockAVSMediaManager) -> CallViewController {
        ZMUser.selfUser().remoteIdentifier = UUID()

        let conversation = (MockConversation.oneOnOneConversation() as Any) as! ZMConversation
        let voiceChannel = MockVoiceChannel(conversation: conversation)
        voiceChannel.mockVideoState = VideoState.started
        voiceChannel.mockIsVideoCall = true
        voiceChannel.mockCallState = CallState.established
        let proximityManager = ProximityMonitorManager()
        let callController = CallViewController(voiceChannel: voiceChannel, proximityMonitorManager: proximityManager, mediaManager:mediaManager)

        return callController
    }
}

final class CallViewControllerTests: XCTestCase {

    func testThatItDeallocates() {
        // when & then
        verifyDeallocation { () -> CallViewController in
            // given
            let callController = XCTestCase.CreateCallViewController(mediaManager: ZMMockAVSMediaManager())
            // Simulate user click
            callController.startOverlayTimer()
            return callController
        }
    }
}

final class CallViewControllerGestureTests: XCTestCase {
    var sut: CallViewController!
    var mediaManager: ZMMockAVSMediaManager!

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)

        mediaManager = ZMMockAVSMediaManager()
        sut = XCTestCase.CreateCallViewController(mediaManager: mediaManager)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()

        UIView.setAnimationsEnabled(true)
    }

    func tapOnSut() {
        sut.handleSingleTap(UITapGestureRecognizer(target: nil, action: nil))
    }

    func testThatOverlayDismissesAfterTapped() {
        // GIVEN
        mediaManager.isMicrophoneMuted = true

        // WHEN
        // call overlay is visible at the beginning
        XCTAssert(sut.isOverlayVisible)

        tapOnSut()

        // call overlay is invisible after tapped
        XCTAssertFalse(sut.isOverlayVisible)
    }
}
