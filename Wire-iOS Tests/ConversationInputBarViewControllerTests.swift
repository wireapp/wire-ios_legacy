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

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    override func setUp() {
        super.setUp()

        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        sut.audioSession = MockAudioSession()
//        sut.loadViewIfNeeded()

        //HACK: prevent a crash from pureLayout when creating constraint in a zero size frame
        // A multiplier of 0 or a nil second item together with a location for the first attribute creates an illegal constraint of a location equal to a constant. Location attributes must be specified in pairs."
        sut.view.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 320))

        sut.createAudioRecord()
    }

    func longPressChanged() {
        let changedGestureRecognizer = MockLongPressGestureRecognizer(location: CGPoint(x: 0, y: 30), state: .changed)
        sut.audioButtonLongPressed(changedGestureRecognizer)
    }

    func longPressEnded() {
        let endedGestureRecognizer = MockLongPressGestureRecognizer(location: .zero, state: .ended)
        sut.audioButtonLongPressed(endedGestureRecognizer)
    }

    func testAudioRecorderTouchBegan() {
        // GIVEN

        // WHEN
        let mockLongPressGestureRecognizer = MockLongPressGestureRecognizer(location: .zero, state: .began)
        sut.audioButtonLongPressed(mockLongPressGestureRecognizer)
//        sut.view.layoutIfNeeded()

        // THEN
        verifyInAllPhoneWidths(view: sut.view)
    }

    func testAudioRecorderTouchChanged() {
        // GIVEN

        // WHEN
        sut.audioButtonLongPressed(MockLongPressGestureRecognizer(location: .zero, state: .began))
        longPressChanged()
        sut.view.layoutIfNeeded()

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testAudioRecorderTouchEnded() {
        // GIVEN

        // WHEN
        sut.audioButtonLongPressed(MockLongPressGestureRecognizer(location: .zero, state: .began))
        longPressEnded()
        sut.view.layoutIfNeeded()

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }
}

final class ConversationInputBarViewControllerTests: CoreDataSnapshotTestCase {
    
    var sut: ConversationInputBarViewController!

    override func setUp() {
        super.setUp()
        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        sut.loadViewIfNeeded()

        //        recordMode = true
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testNormalState(){
        verifyInAllPhoneWidths(view: sut.view)
        verifyInAllTabletWidths(view: sut.view)
    }

}

// MARK: - Ephemeral indicator button
extension ConversationInputBarViewControllerTests {
    func testEphemeralIndicatorButton(){ ///TODO: broken constraint? the placeholder label's position.y is not always the same
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration

        // THEN
        sut.view.prepareForSnapshot()
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTimeNone(){
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(.none)

        // THEN
        sut.view.prepareForSnapshot()
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTime10Second() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(10)
        
        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)
        
        // THEN
        sut.view.prepareForSnapshot()
        self.verifyInAllPhoneWidths(view: sut.view)
    }
    
    func testEphemeralTime5Minutes() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(300)
        
        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)
        
        // THEN
        sut.view.prepareForSnapshot()
        self.verifyInAllPhoneWidths(view: sut.view)
    }
    
    func testEphemeralTime2Hours() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(7200)
        
        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)
        
        // THEN
        sut.view.prepareForSnapshot()
        self.verifyInAllPhoneWidths(view: sut.view)
    }
    
    func testEphemeralTime3Days() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(259200)
        
        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)
        
        // THEN
        sut.view.prepareForSnapshot()
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTime4Weeks(){
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(2419200)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
        sut.view.prepareForSnapshot()
        self.verifyInAllPhoneWidths(view: sut.view)
    }
    
    func testEphemeralTime1Year() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(31540000)
        
        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)
        
        // THEN
        sut.view.prepareForSnapshot()
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralModeWhenTyping() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(2419200)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)
        let shortText = "Lorem ipsum dolor"
        sut.inputBar.textView.text = shortText

        // THEN
        sut.view.prepareForSnapshot()
        self.verifyInAllPhoneWidths(view: sut.view)
    }
}
