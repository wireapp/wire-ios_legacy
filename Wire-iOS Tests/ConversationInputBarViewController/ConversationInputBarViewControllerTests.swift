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


final class ConversationInputBarViewControllerTests: CoreDataSnapshotTestCase {

    var sut: ConversationInputBarViewController!

    override func setUp() {
        super.setUp()
        sut = ConversationInputBarViewController(conversation: otherUserConversation)
        sut.loadViewIfNeeded()
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
    func testEphemeralIndicatorButton(){
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTimeNone(){
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(.none)

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTime10Second() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(10)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTime5Minutes() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(300)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTime2Hours() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(7200)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTime3Days() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(259200)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTime4Weeks(){
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(2419200)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
        self.verifyInAllPhoneWidths(view: sut.view)
    }

    func testEphemeralTime1Year() {
        // GIVEN

        // WHEN
        sut.mode = .timeoutConfguration
        otherUserConversation.messageDestructionTimeout = .local(31540000)

        sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

        // THEN
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
        self.verifyInAllPhoneWidths(view: sut.view)
    }
}
