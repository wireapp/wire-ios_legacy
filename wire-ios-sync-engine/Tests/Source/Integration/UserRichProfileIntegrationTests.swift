//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
@testable import WireSyncEngine

class UserRichProfileIntegrationTests: IntegrationTest {

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
        createTeamAndConversations()
    }

    func testThatItDoesNotUpdateRichInfoIfItDoesNotHaveIt() {
        // given
        XCTAssertTrue(login())

        // when
        let user = self.user(for: teamUser1)
        XCTAssertEqual(user?.richProfile.isEmpty, true)
        userSession?.perform {
            user?.needsRichProfileUpdate = true
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(user?.richProfile.isEmpty, true)
    }

    func testThatItHandlesErrorWhenUpdatingRichInfo() {
        // given
        let entry1 = UserRichProfileField(type: "email", value: "some@email.com")
        let entry2 = UserRichProfileField(type: "position", value: "Chief Testing Officer")

        mockTransportSession.performRemoteChanges {
            self.team = $0.insertTeam(withName: "Name", isBound: true)
            self.team.creator = self.selfUser
            $0.insertMember(with: self.selfUser, in: self.team)
            _ = $0.insertTeam(withName: "Other", isBound: false, users: [self.user1])
            self.user1.appendRichInfo(type: entry1.type, value: entry1.value)
            self.user1.appendRichInfo(type: entry2.type, value: entry2.value)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertTrue(login())

        // when
        let user = self.user(for: user1)
        userSession?.perform {
            user?.needsRichProfileUpdate = true
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(user?.richProfile, [])
    }

    func testThatItUpdatesRichInfoWhenItDoesHaveIt() {
        // given
        let entry1 = UserRichProfileField(type: "email", value: "some@email.com")
        let entry2 = UserRichProfileField(type: "position", value: "Chief Testing Officer")
        mockTransportSession.performRemoteChanges { _ in
            self.teamUser1.appendRichInfo(type: entry1.type, value: entry1.value)
            self.teamUser1.appendRichInfo(type: entry2.type, value: entry2.value)
        }
        XCTAssertTrue(login())

        // when
        let user = self.user(for: teamUser1)
        userSession?.perform {
            user?.needsRichProfileUpdate = true
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(user?.richProfile, [entry1, entry2])
    }

}
