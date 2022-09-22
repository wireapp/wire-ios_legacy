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

final class ConversationInputBarViewControllerTests: ZMSnapshotTestCase {

    private var mockConversation: MockInputBarConversationType!
    private var mockClassificationProvider: MockClassificationProvider!

    override func setUp() {
        super.setUp()

        UIColor.setAccentOverride(.vividRed)
        mockConversation = MockInputBarConversationType()
        mockClassificationProvider = MockClassificationProvider()
    }

    override func tearDown() {
        mockConversation = nil
        mockClassificationProvider = nil

        super.tearDown()
    }

    func testNormalState() {
        verifyInAllPhoneWidths(createSut: {
            return ConversationInputBarViewController(conversation: mockConversation)
        }, hasMaskedCorners: false)
        verifyInWidths(createSut: {
                return ConversationInputBarViewController(conversation: mockConversation)
            },
            widths: tabletWidths(),
                       snapshotBackgroundColor: .white, hasMaskedCorners: false)

    }

    // MARK: - Typing indication

    func testTypingIndicationIsShown() {
        // THEN
        let createSut: () -> UIViewController = {
            // GIVEN & WHEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // Directly working with sut.typingIndicatorView to prevent triggering aniamtion
            sut.typingIndicatorView.typingUsers = [MockUserType.createUser(name: "Bruno")]
            sut.typingIndicatorView.setHidden(false, animated: false)

            return sut
        }

        verifyInAllPhoneWidths(createSut: createSut, hasMaskedCorners: false)
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

        verifyInAllPhoneWidths(createSut: createSut, hasMaskedCorners: false)
    }

    func testEphemeralTimeNone() {
        // THEN
        let createSut: () -> UIViewController = {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // WHEN
            sut.mode = .timeoutConfguration
            self.mockConversation.activeMessageDestructionTimeoutValue = nil
            return sut
        }

        verifyInAllPhoneWidths(createSut: createSut, hasMaskedCorners: false)
    }

    private func setMessageDestructionTimeout(timeInterval: TimeInterval) {
        mockConversation.activeMessageDestructionTimeoutValue = .init(rawValue: timeInterval)
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
        } as () -> UIViewController, hasMaskedCorners: false)
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
        } as () -> UIViewController, hasMaskedCorners: false)
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
        } as () -> UIViewController, hasMaskedCorners: false)
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
        } as () -> UIViewController, hasMaskedCorners: false)
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
        } as () -> UIViewController, hasMaskedCorners: false)
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
        } as () -> UIViewController, hasMaskedCorners: false)
    }

    func testEphemeralDisabled() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            self.mockConversation.isSelfDeletingMessageSendingDisabled = true
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // WHEN
            sut.mode = .timeoutConfguration

            return sut
        } as () -> UIViewController, hasMaskedCorners: false)
    }

    func testEphemeralWithForcedTimeout() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            self.mockConversation.isSelfDeletingMessageTimeoutForced = true
            let sut = ConversationInputBarViewController(conversation: self.mockConversation)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 300)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

            return sut
        } as () -> UIViewController, hasMaskedCorners: false)
    }

    // MARK: - file action sheet

    func testUploadFileActionSheet() {
        let sut = ConversationInputBarViewController(conversation: mockConversation)

        let alert: UIAlertController = sut.createDocUploadActionSheet()

        verify(matching: alert)
    }

    // MARK: - Classification

    func testClassifiedNormalState() {
        verifyInAllPhoneWidths(createSut: {
            self.mockClassificationProvider.returnClassification = .classified

            return ConversationInputBarViewController(conversation: self.mockConversation, classificationProvider: self.mockClassificationProvider)
        } as () -> UIViewController, hasMaskedCorners: false)
    }

    func testNotClassifiedNormalState() {
        verifyInAllPhoneWidths(createSut: {
            self.mockClassificationProvider.returnClassification = .notClassified

            return ConversationInputBarViewController(conversation: self.mockConversation, classificationProvider: self.mockClassificationProvider)
        } as () -> UIViewController, hasMaskedCorners: false)
    }

    func testNoClassificationNormalState() {
        verifyInAllPhoneWidths(createSut: {
            self.mockClassificationProvider.returnClassification = .none

            return ConversationInputBarViewController(conversation: self.mockConversation, classificationProvider: self.mockClassificationProvider)
        } as () -> UIViewController, hasMaskedCorners: false)
    }

}
