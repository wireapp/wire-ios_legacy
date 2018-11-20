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

class ConversationCellActionControllerTests: CoreDataSnapshotTestCase {
    
    // MARK: - Single Tap Action
    
    func testThatImageIsPresentedOnSingleTapWhenDownloaded() {
        // GIVEN
        let message = MockMessageFactory.imageMessage(with: image(inTestBundleNamed: "unsplash_burger.jpg"))!
        message.sender = otherUser
        message.conversation = otherUserConversation
        
        // WHEN
        let actionController = ConversationCellActionController(responder: nil, message: message)
        let singleTapAction = actionController.singleTapAction
        
        // THEN
        XCTAssertEqual(singleTapAction, .present)
    }
    
    func testThatImageIgnoresSingleTapWhenNotDownloaded() {
        // GIVEN
        let message = MockMessageFactory.imageMessage(with: nil)!
        message.sender = otherUser
        message.conversation = otherUserConversation
        
        // WHEN
        let actionController = ConversationCellActionController(responder: nil, message: message)
        let singleTapAction = actionController.singleTapAction
        
        // THEN
        XCTAssertNil(singleTapAction)
    }

    // MARK: - Reply

    func testThatItDoesNotShowReplyItemForUnsentTextMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Text")!
        message.sender = otherUser
        message.conversation = otherUserConversation
        message.deliveryState = .failedToSend

        // WHEN
        let actionController = ConversationCellActionController(responder: nil, message: message)
        let supportsReply = actionController.canPerformAction(#selector(ConversationCellActionController.quoteMessage))

        // THEN
        XCTAssertFalse(supportsReply)

    }

}
