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
    let mockState: UIGestureRecognizerState
    var mockLocation: CGPoint?

    init(location: CGPoint?, state: UIGestureRecognizerState) {
        mockLocation = location
        mockState = state

        super.init(target: nil, action: nil)
    }

    override func location(in view: UIView?) -> CGPoint {
        return mockLocation ?? super.location(in: view)
    }

    override var state: UIGestureRecognizerState {
        return mockState
    }
}

final class ConversationInputBarViewControllerTests: CoreDataSnapshotTestCase {
    
    var sut: ConversationInputBarViewController!

    func prepareSut() {
        sut = ConversationInputBarViewController(conversation: nil)

        sut.view.layoutIfNeeded()
        sut.view.layer.speed = 0

        sut.viewDidLoad()
    }

    func testNormalState(){
        prepareSut()
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testAudioRecorderTouchBegan(){
        // GIVEN
        prepareSut()
        sut.createAudioRecord()
        sut.view.layoutIfNeeded()

        // WHEN
        let mockLongPressGestureRecognizer = MockLongPressGestureRecognizer(location: .zero, state: .began)
        sut.audioButtonLongPressed(mockLongPressGestureRecognizer)
        sut.view.layoutIfNeeded()

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testAudioRecorderTouchChanged(){
        // GIVEN
        prepareSut()
        sut.createAudioRecord()
        sut.view.layoutIfNeeded()

        // WHEN
        sut.audioButtonLongPressed(MockLongPressGestureRecognizer(location: .zero, state: .began))
        let mockLongPressGestureRecognizer = MockLongPressGestureRecognizer(location: CGPoint(x: 0, y: 30), state: .changed)
        sut.audioButtonLongPressed(mockLongPressGestureRecognizer)
        sut.view.layoutIfNeeded()

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testAudioRecorderTouchEnded(){
        // GIVEN
        prepareSut()
        sut.createAudioRecord()
        sut.view.layoutIfNeeded()

        // WHEN
        sut.audioButtonLongPressed(MockLongPressGestureRecognizer(location: .zero, state: .began))
        let mockLongPressGestureRecognizer = MockLongPressGestureRecognizer(location: .zero, state: .ended)
        sut.audioButtonLongPressed(mockLongPressGestureRecognizer)
        sut.view.layoutIfNeeded()

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }
}

// Ephemeral indicator button
extension ConversationInputBarViewControllerTests {
    func testEphemeralIndicatorButton(){
        // GIVEN
        prepareSut()

        // WHEN
        sut.mode = .timeoutConfguration

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
