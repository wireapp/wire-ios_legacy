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
        sut.viewDidLoad()

        sut.createAudioRecord()
        sut.view.layoutIfNeeded()
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
        sut.view.layoutIfNeeded()

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
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

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testNormalState(){
        // GIVEN
        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        sut.viewDidLoad()
        
        // THEN
        verifyInAllPhoneWidths(view: sut.view)
        verifyInAllTabletWidths(view: sut.view)
    }

}

// MARK: - Ephemeral indicator button
extension ConversationInputBarViewControllerTests {
    func testEphemeralIndicatorButton(){
        // GIVEN
        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        sut.viewDidLoad()

        // WHEN
        sut.mode = .timeoutConfguration

        // THEN
        sut.view.prepareForSnapshot()
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTimeNone(){
        // GIVEN
        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        sut.viewDidLoad()
        
        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(.none)

        // THEN
        sut.view.prepareForSnapshot()
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTime10Second() {
        // GIVEN
        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        
        sut.viewDidLoad()
        
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
        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        
        sut.viewDidLoad()
        
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
        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        
        sut.viewDidLoad()
        
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
        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        
        sut.viewDidLoad()
        
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
        sut = ConversationInputBarViewController(conversation: otherUserConversation)

        sut.viewDidLoad()

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
        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        
        sut.viewDidLoad()
        
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
        sut = ConversationInputBarViewController(conversation: otherUserConversation)

        sut.viewDidLoad()

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
