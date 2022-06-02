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

import Foundation
import XCTest
@testable import WireDataModel

class ConversationCreationOptionsTests: ZMConversationTestsBase {

    func testThatItCreatesTheConversationWithOptions() {
        // given
        let user = self.createUser()
        let name = "Test Conversation In Swift"
        let team = Team.insertNewObject(in: self.uiMOC)
        let options = ConversationCreationOptions(participants: [user], name: name, team: team, allowGuests: true)
        // when
        let conversation = self.coreDataStack.insertGroup(with: options)
        // then
        XCTAssertEqual(conversation.displayName, name)
        XCTAssertEqual(conversation.localParticipants, Set([user, .selfUser(in: uiMOC)]))
        XCTAssertEqual(conversation.team, team)
        XCTAssertEqual(conversation.allowGuests, true)
    }
}
