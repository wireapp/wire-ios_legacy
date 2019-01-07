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


final class MockLongPressGestureRecognizer: UILongPressGestureRecognizer {
    let mockState: UIGestureRecognizer.State
    var mockLocation: CGPoint?

    init(location: CGPoint?, state: UIGestureRecognizer.State) {
        mockLocation = location
        mockState = state

        super.init(target: nil, action: nil)
    }

    override func location(in view: UIView?) -> CGPoint {
        return mockLocation ?? super.location(in: view)
    }

    override var state: UIGestureRecognizer.State {
        get {
            return mockState
        }
        set {}
    }
}

final class MockAudioSession: NSObject, AVAudioSessionType {
    var recordPermission: AVAudioSession.RecordPermission = .granted
}

final class ConversationInputBarViewControllerAudioRecorderSnapshotTests: CoreDataSnapshotTestCase {
    var sut: ConversationInputBarViewController!
    var mockLongPressGestureRecognizer: MockLongPressGestureRecognizer!

    override func setUp() {
        super.setUp()

        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        sut.audioSession = MockAudioSession()
        sut.loadViewIfNeeded()

        sut.createAudioRecord()

        mockLongPressGestureRecognizer = MockLongPressGestureRecognizer(location: .zero, state: .began)
    }

    override func tearDown() {
        sut = nil
        mockLongPressGestureRecognizer = nil

        super.tearDown()
    }

    func longPressChanged() {
        let changedGestureRecognizer = MockLongPressGestureRecognizer(location: CGPoint(x: 0, y: -30), state: .changed)
        sut.audioButtonLongPressed(changedGestureRecognizer)
    }

    func longPressEnded() {
        let endedGestureRecognizer = MockLongPressGestureRecognizer(location: .zero, state: .ended)
        sut.audioButtonLongPressed(endedGestureRecognizer)
    }

    func testAudioRecorderTouchBegan() {
        // GIVEN


        // THEN
        verifyInAllPhoneWidths(view: sut.view,
                               configuration: { _ in
                                // WHEN
                                self.sut.audioButtonLongPressed(self.mockLongPressGestureRecognizer)
        })
    }

    func testAudioRecorderTouchChanged() {
        // GIVEN

        // THEN
        verifyInAllPhoneWidths(view: sut.view,
                               configuration: { _ in
                                // WHEN
                                self.sut.audioButtonLongPressed(self.mockLongPressGestureRecognizer)
                                self.longPressChanged()
        })
    }

    func testAudioRecorderTouchEnded() {
        // GIVEN

        // THEN
        verifyInAllPhoneWidths(view: sut.view,
                               configuration: { _ in
                                // WHEN
                                self.sut.audioButtonLongPressed(self.mockLongPressGestureRecognizer)
                                self.longPressEnded()
        })
    }
}

