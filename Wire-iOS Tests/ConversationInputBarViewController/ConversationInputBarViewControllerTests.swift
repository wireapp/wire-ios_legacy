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
import WireCommonComponents

final class MockInputBarConversationType: InputBarConversationType {
    var typingUsers: [UserType] = []

    var hasDraftMessage: Bool = false

    var connectedUserType: UserType?

    var draftMessage: DraftMessage?

    var messageDestructionTimeoutValue: TimeInterval = 0
    var messageDestructionTimeout: MessageDestructionTimeout?

    var conversationType: ZMConversationType = .group

    func setIsTyping(_ isTyping: Bool) {
        //no-op
    }

    var isReadOnly: Bool = false

    var displayName: String = ""
}

final class ConversationInputBarViewControllerTests: XCTestCase {

    var sut: ConversationInputBarViewController!
    var mockConversation: MockInputBarConversationType!

    override func setUp() {
        super.setUp()

        UIColor.setAccentOverride(.vividRed)

        mockConversation = MockInputBarConversationType()
        sut = ConversationInputBarViewController(conversation: mockConversation)
    }

    override func tearDown() {
        sut = nil
        mockConversation = nil

        super.tearDown()
    }

    func testNormalState() {
        verifyInAllPhoneWidths(matching: sut.view)
        verifyInWidths(matching: sut.view,
                       widths: tabletWidths(), snapshotBackgroundColor: .white)

    }

    // MARK: - Typing indication

    func testTypingIndicationIsShown() {
        // GIVEN & WHEN
        /// directly working with sut.typingIndicatorView to prevent triggering aniamtion
        sut.typingIndicatorView.typingUsers = [MockUserType.createUser(name: "Bruno")]
        sut.typingIndicatorView.setHidden(false, animated: false)

        // THEN
        verifyInAllPhoneWidths(matching: sut.view)
    }

    // MARK: - Ephemeral indicator button

    func testEphemeralIndicatorButton() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration

        // THEN
        verifyInAllPhoneWidths(matching: sut.view)
    }

    func testEphemeralTimeNone() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        mockConversation.messageDestructionTimeout = .local(.none)

        // THEN
        verifyInAllPhoneWidths(matching: sut.view)
    }

    private func setMessageDestructionTimeout(timeInterval: TimeInterval) {
        mockConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: timeInterval))
        mockConversation.messageDestructionTimeoutValue = timeInterval
    }

    func testEphemeralTime10Second() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        setMessageDestructionTimeout(timeInterval: 10)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
        verifyInAllPhoneWidths(matching: sut.view)
    }

    func testEphemeralTime5Minutes() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        setMessageDestructionTimeout(timeInterval: 300)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
        verifyInAllPhoneWidths(matching: sut.view)
    }

    func testEphemeralTime2Hours() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        setMessageDestructionTimeout(timeInterval: 7200)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
        verifyInAllPhoneWidths(matching: sut.view)
    }

    func testEphemeralTime3Days() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        setMessageDestructionTimeout(timeInterval: 259200)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
        self.verifyInAllPhoneWidths(matching: sut.view)
    }

    func testEphemeralTime4Weeks() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        setMessageDestructionTimeout(timeInterval: 2419200)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
        verifyInAllPhoneWidths(matching: sut.view)
    }

    func testEphemeralModeWhenTyping() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        setMessageDestructionTimeout(timeInterval: 2419200)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)
        let shortText = "Lorem ipsum dolor"
        sut.inputBar.textView.text = shortText

        // THEN
        verifyInAllPhoneWidths(matching: sut.view)
    }

// MARK: - file action sheet

    func testUploadFileActionSheet() {
        let alert: UIAlertController = sut.createDocUploadActionSheet()

        verify(matching: alert)
    }
}
