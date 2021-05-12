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

final class ConversationMessageActionControllerTests: XCTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
    }

    override func tearDown() {
        coreDataFixture = nil
        super.tearDown()
    }

    // MARK: - Single Tap Action

    func testThatImageIsPresentedOnSingleTapWhenDownloaded() {
        // GIVEN
        let message = MockMessageFactory.imageMessage(with: image(inTestBundleNamed: "unsplash_burger.jpg"))
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let singleTapAction = actionController.singleTapAction

        // THEN
        XCTAssertEqual(singleTapAction, .present)
    }

    func testThatImageIgnoresSingleTapWhenNotDownloaded() {
        // GIVEN
        let message = MockMessageFactory.imageMessage(with: nil)
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let singleTapAction = actionController.singleTapAction

        // THEN
        XCTAssertNil(singleTapAction)
    }

    // MARK: - Double Tap Action

    func testThatItAllowsToLikeMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Super likeable")
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let doubleTapAction = actionController.doubleTapAction

        // THEN
        XCTAssertEqual(doubleTapAction, .like)
    }

    func testThatItDoesNotAllowToLikeEphemeralMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Super likeable")
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation
        message.isEphemeral = true

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let doubleTapAction = actionController.doubleTapAction

        // THEN
        XCTAssertNil(doubleTapAction)
    }

    // MARK: - Reply

    func testThatItDoesNotShowReplyItemForUnsentTextMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Text")
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation
        message.deliveryState = .failedToSend

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let supportsReply = actionController.canPerformAction(#selector(ConversationMessageActionController.quoteMessage))

        // THEN
        XCTAssertFalse(supportsReply)

    }

    // MARK: - Copy

    func testThatItShowsCopyItemForTextMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Text")
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let supportsCopy = actionController.canPerformAction(#selector(ConversationMessageActionController.copyMessage))

        // THEN
        XCTAssertTrue(supportsCopy)
    }

}
