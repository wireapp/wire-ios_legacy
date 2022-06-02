//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

@testable import WireSyncEngine

class ZMConversation_TypingUsersTests: MessagingTest {

    private var token: Any?

    func testThatItCreatesANotificationWhenCallingSetTyping() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // Then
        let expectation = self.expectation(description: "Notification")
        let assertion: (NotificationInContext) -> Void = { notification in
            XCTAssertEqual(notification.object as? ZMConversation, conversation)
            XCTAssertEqual(notification.userInfo["isTyping"] as? Bool, true)
            expectation.fulfill()
        }

        token = NotificationInContext.addObserver(name: ZMConversation.typingChangeNotificationName,
                                                      context: uiMOC.notificationContext,
                                                      object: nil,
                                                      queue: nil,
                                                      using: assertion)
        // When
        conversation.setIsTyping(true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Teardown
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        token = nil
    }
}
