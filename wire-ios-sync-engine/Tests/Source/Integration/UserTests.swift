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

import Foundation

final class UserTests_swift: IntegrationTest {

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    func testThatDisplayNameDoesNotChangesIfAUserWithADifferentNameIsAdded() {
        XCTAssertTrue(login())

        // Create a conversation and change SelfUser name

        let conversation = self.conversation(for: groupConversation)
        _ = conversation?.lastModifiedDate

        weak var selfUser = ZMUser.selfUser(inUserSession: userSession!)
        userSession!.perform({
            selfUser?.name = "Super Name"
        })
        if !waitForAllGroupsToBeEmpty(withTimeout: 0.2) {
            XCTFail("Timed out waiting for groups to empty.")
        }

        XCTAssertEqual(selfUser?.name, "Super Name")

        // initialize observers

        let userObserver = UserChangeObserver(user: selfUser)

        // when
        // add new user to groupConversation remotely

        var extraUser: MockUser?
        mockTransportSession.performRemoteChanges({ [self] session in
            extraUser = session.insertUser(withName: "Max Tester")
            self.groupConversation.addUsers(by: self.selfUser, addedUsers: [extraUser!])
            XCTAssertNotNil(extraUser?.name)
        })

        if !waitForAllGroupsToBeEmpty(withTimeout: 0.5) {
            XCTFail("Timed out waiting for groups to empty.")
        }

        // then

        let realUser = user(for: extraUser!)
        XCTAssertEqual(realUser?.name, "Max Tester")
        if let realUser = realUser {
            XCTAssert(((conversation?.localParticipants.contains(realUser)) != nil))
        }

        let userNotes = userObserver?.notifications
        XCTAssertEqual(userNotes!.count, 0)

        XCTAssertEqual(realUser?.name, "Max Tester")
        XCTAssertEqual(selfUser?.name, "Super Name")
    }

}
