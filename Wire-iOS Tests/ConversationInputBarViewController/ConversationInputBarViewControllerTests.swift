//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

final class ConversationInputBarViewControllerTests: XCTestCase {

    var mockConversation: MockInputBarConversationType!

    override func setUp() {
        super.setUp()

        UIColor.setAccentOverride(.vividRed)
        mockConversation = MockInputBarConversationType()
    }

    override func tearDown() {
        mockConversation = nil

        super.tearDown()
    }

    func testNormalState() {
        verifyInAllPhoneWidths(createSut: {
            return ConversationInputBarViewController(conversation: mockConversation)
        })
        verifyInWidths(createSut: {
                return ConversationInputBarViewController(conversation: mockConversation)
            },
            widths: tabletWidths(),
            snapshotBackgroundColor: .white)

    }

    // MARK: - Typing indication

    func testTypingIndicationIsShown() {
        // THEN
        let createSut: () -> UIViewController = {
            // GIVEN & WHEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            /// directly working with sut.typingIndicatorView to prevent triggering aniamtion
            sut.typingIndicatorView.typingUsers = [MockUserType.createUser(name: "Bruno")]
            sut.typingIndicatorView.setHidden(false, animated: false)

            return sut
        }

        verifyInAllPhoneWidths(createSut: createSut)
    }

    // MARK: - Ephemeral indicator button

    func testEphemeralIndicatorButton() {
        // THEN
        let createSut: () -> UIViewController = {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // WHEN
            sut.mode = .timeoutConfguration
            return sut
        }

        verifyInAllPhoneWidths(createSut: createSut)
    }

    func testEphemeralTimeNone() {
        // THEN
        let createSut: () -> UIViewController = {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // WHEN
            sut.mode = .timeoutConfguration
            self.mockConversation.messageDestructionTimeout = .local(.none)
            return sut
        }

        verifyInAllPhoneWidths(createSut: createSut)
    }

    private func setMessageDestructionTimeout(timeInterval: TimeInterval) {
        mockConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: timeInterval))
        mockConversation.messageDestructionTimeoutValue = timeInterval
    }

    func testEphemeralTime10Second() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 10)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)
            return sut
        } as () -> UIViewController)
    }

    func testEphemeralTime5Minutes() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 300)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

            return sut
        } as () -> UIViewController)
    }

    func testEphemeralTime2Hours() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 7200)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

            return sut
        } as () -> UIViewController)
    }

    func testEphemeralTime3Days() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 259200)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

            return sut
        } as () -> UIViewController)
    }

    func testEphemeralTime4Weeks() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 2419200)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

            return sut
        } as () -> UIViewController)
    }

    func testEphemeralModeWhenTyping() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 2419200)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)
            let shortText = "Lorem ipsum dolor"
            sut.inputBar.textView.text = shortText

            return sut
        } as () -> UIViewController)
    }

// MARK: - file action sheet

    func testUploadFileActionSheet() {
        let sut = ConversationInputBarViewController(conversation: mockConversation)

        let alert: UIAlertController = sut.createDocUploadActionSheet()

        verify(matching: alert)
    }
}
