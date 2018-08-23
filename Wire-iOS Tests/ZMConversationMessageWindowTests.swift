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

final class ZMConversationMessageWindowTests: XCTestCase {
    
    var sut: ZMConversationMessageWindow!

    var message: ZMConversationMessage {
        let message = MockMessageFactory.textMessage(withText: "Hello")
        message?.deliveryState = .sent

        let users = MockUser.mockUsers().compactMap { $0 }
        message?.backingUsersReaction = [
            MessageReaction.like.unicodeValue: users
        ]

        return message!
    }

    override func setUp() {
        super.setUp()
        let mockConversation = MockConversationFactory.mockConversation() as Any
        sut = ZMConversationMessageWindow.init(conversation: mockConversation as! ZMConversation, size: 50)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatIsPreviousSenderSameReturnFalseIfPreviousMessageIsNil(){
        // GIVEN

        // WHEN
        let isPreviousSenderSame = sut.isPreviousSenderSame(forMessage: message)

        // THEN
        XCTAssertFalse(isPreviousSenderSame)
    }

    func testThatIsPreviousSenderSameReturnFalseIfMessageIsNil(){
        // GIVEN

        // WHEN
        let isPreviousSenderSame = sut.isPreviousSenderSame(forMessage: nil)

        // THEN
        XCTAssertFalse(isPreviousSenderSame)
    }
}
