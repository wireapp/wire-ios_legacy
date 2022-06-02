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

import XCTest
@testable import WireRequestStrategy

class ZMLocalNotificationLocalizationTests: ZMLocalNotificationTests {

    func testThatItLocalizesCallkitCallerName() {
        syncMOC.performGroupedBlockAndWait {
            let result: (ZMUser, ZMConversation) -> String = {
                $1.localizedCallerName(with: $0)
            }

            // then
            XCTAssertEqual(result(self.sender, self.groupConversation), "Super User in Super Conversation")
            XCTAssertEqual(result(self.userWithNoName, self.groupConversationWithoutName), "Someone calling in a conversation")
            XCTAssertEqual(result(self.userWithNoName, self.groupConversation), "Someone calling in Super Conversation")
            XCTAssertEqual(result(self.sender, self.groupConversationWithoutName), "Super User calling in a conversation")
        }
    }
}
