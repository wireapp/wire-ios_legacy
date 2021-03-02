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

final class ConversationTitleViewTests: ZMSnapshotTestCase {

    var sut: ConversationTitleView!
    var conversation: MockConversation!

    override func setUp() {
        super.setUp()
        conversation = MockConversation()
        conversation.relatedConnectionState = .accepted
        conversation.displayName = "Alan Turing"
        sut = ConversationTitleView(conversation: conversation as Any as! ZMConversation, interactive: true)
        snapshotBackgroundColor = UIColor.white
    }

    override func tearDown() {
        sut = nil
        conversation = nil

        super.tearDown()
    }

    func testThatItRendersTheConversationDisplayNameCorrectly() {
        verify(view: sut)
    }

    func testThatItUpdatesTheTitleViewAndRendersTheVerifiedShieldCorrectly() {
        // when
        conversation.securityLevel = .secure
        sut = ConversationTitleView(conversation: conversation as Any as! ZMConversation, interactive: true)

        // then
        verify(view: sut)
    }

    func testThatItUpdatesTheTitleViewAndRendersLegalHoldCorrectly_PendingApproval() {
        // when
        conversation.legalHoldStatus = .pendingApproval
        sut = ConversationTitleView(conversation: conversation as Any as! ZMConversation, interactive: true)

        // then
        verify(view: sut)
    }

    func testThatItUpdatesTheTitleViewAndRendersLegalHoldCorrectly_Enabled() {
        // when
        conversation.legalHoldStatus = .enabled
        sut = ConversationTitleView(conversation: conversation as Any as! ZMConversation, interactive: true)

        // then
        verify(view: sut)
    }

    func testThatItUpdatesTheTitleViewAndRendersLegalHoldAndVerifiedShieldCorrectly() {
        // when
        conversation.securityLevel = .secure
        conversation.legalHoldStatus = .enabled
        sut = ConversationTitleView(conversation: conversation as Any as! ZMConversation, interactive: true)

        // then
        verify(view: sut)
    }

    func testThatItDoesNotRenderTheDownArrowForOutgoingConnections() {
        // when
        conversation.relatedConnectionState = .sent
        sut = ConversationTitleView(conversation: conversation as Any as! ZMConversation, interactive: true)

        // then
        verify(view: sut)
    }

    func testThatItExecutesTheTapHandlerOnTitleTap() {
        // given
        var callCount: Int = 0
        sut.tapHandler = { button in
            callCount += 1
        }

        XCTAssertEqual(callCount, 0)

        // when
        sut.titleButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(callCount, 1)
    }
}
