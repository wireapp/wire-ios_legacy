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
import SnapshotTesting

final class ConversationTitleViewTests: XCTestCase {

    var sut: ConversationTitleView!
    var conversation: SwiftMockConversation!

    override func setUp() {
        super.setUp()
        conversation = SwiftMockConversation()
        conversation.relatedConnectionState = .accepted
        conversation.displayName = "Alan Turing"
    }

    override func tearDown() {
        sut = nil
        conversation = nil

        super.tearDown()
    }

    private func createSut(conversation: SwiftMockConversation) -> ConversationTitleView {
        let view = ConversationTitleView(conversation: conversation, interactive: true)
        view.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 44))
        view.backgroundColor = .white
        return view
    }

    func testThatItRendersTheConversationDisplayNameCorrectly() {
        // given
        sut = createSut(conversation: conversation)

        // then
        verify(matching: sut)
    }

    func testThatItRendersTheFederatedConversationDisplayNameCorrectly() {
        // given
        let user = MockUserType.createUser(name: "Alan Turing")
        user.isFederated = true
        user.domain = "wire.com"
        user.handle = "alanturing"
        conversation.connectedUserType = user
        conversation.conversationType = .oneOnOne
        sut = createSut(conversation: conversation)

        // then
        verify(matching: sut)
    }

    func testThatItUpdatesTheTitleViewAndRendersTheVerifiedShieldCorrectly() {
        // when
        conversation.securityLevel = .secure
        sut = createSut(conversation: conversation)

        // then
        verify(matching: sut)
    }

    func testThatItUpdatesTheTitleViewAndRendersLegalHoldCorrectly() {
        // when
        conversation.isUnderLegalHold = true
        sut = createSut(conversation: conversation)

        // then
        verify(matching: sut)
    }

    func testThatItUpdatesTheTitleViewAndRendersLegalHoldAndVerifiedShieldCorrectly() {
        // when
        conversation.securityLevel = .secure
        conversation.isUnderLegalHold = true
        sut = createSut(conversation: conversation)

        // then
        verify(matching: sut)
    }

    func testThatItDoesNotRenderTheDownArrowForOutgoingConnections() {
        // when
        conversation.relatedConnectionState = .sent
        sut = createSut(conversation: conversation)

        // then
        verify(matching: sut)
    }

    func testThatItExecutesTheTapHandlerOnTitleTap() {
        // given
        sut = ConversationTitleView(conversation: conversation, interactive: true)

        var callCount: Int = 0
        sut.tapHandler = { _ in
            callCount += 1
        }

        XCTAssertEqual(callCount, 0)

        // when
        sut.titleButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(callCount, 1)
    }
}
