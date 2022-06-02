////
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

@testable import WireDataModel

class ZMConversationCreationSystemMessageTests: ZMConversationTestsBase {

    override func setUp() {
        super.setUp()
    }

    func testSystemMessageWhenCreatingConversationWithNoName() {
        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let alice = self.createUser(onMoc: self.syncMOC)
            alice.name = "alice"
            let bob = self.createUser(onMoc: self.syncMOC)
            bob.name = "bob"

            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [alice, bob], name: nil, team: nil)
            let systemMessage = conversation?.lastMessage as? ZMSystemMessage

            XCTAssertNotNil(systemMessage)
            XCTAssertEqual(systemMessage?.systemMessageType, .newConversation)
            XCTAssertNil(systemMessage?.text)
            XCTAssertEqual(systemMessage?.users, [selfUser, alice, bob])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testSystemMessageWhenCreatingConversationWithName() {
        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let alice = self.createUser(onMoc: self.syncMOC)
            alice.name = "alice"
            let bob = self.createUser(onMoc: self.syncMOC)
            bob.name = "bob"

            let name = "Crypto"

            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [alice, bob], name: name, team: nil)
            let systemMessage = conversation?.lastMessage as? ZMSystemMessage

            XCTAssertNotNil(systemMessage)
            XCTAssertEqual(systemMessage?.systemMessageType, .newConversation)
            XCTAssertEqual(systemMessage?.text, name)
            XCTAssertEqual(systemMessage?.users, [selfUser, alice, bob])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testSystemMessageWhenCreatingEmptyConversationWithName() {
        syncMOC.performGroupedBlock {
            let name = "Crypto"
            let selfUser = ZMUser.selfUser(in: self.syncMOC)

            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [], name: name, team: nil)
            let nameMessage = conversation?.lastMessage as? ZMSystemMessage

            XCTAssertNotNil(nameMessage)
            XCTAssertEqual(nameMessage?.systemMessageType, .newConversation)
            XCTAssertEqual(nameMessage?.text, name)
            XCTAssertEqual(nameMessage?.users, [selfUser])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testThatItDoesNotSetAllTeamUsersAddedWhenItIsNotTheCaseForTeamUser() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let team = self.createTeam(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            self.createMembership(in: self.syncMOC, user: selfUser, team: team)
            let membership = self.createMembership(in: self.syncMOC, user: selfUser, team: team)
            membership.permissions = .admin

            let user1 = self.createTeamMember(in: self.syncMOC, for: team)
            self.createTeamMember(in: self.syncMOC, for: team)

            // when
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [user1], name: self.name, team: team)
            guard let nameMessage = conversation?.lastMessage as? ZMSystemMessage else { return XCTFail() }

            XCTAssertNotNil(nameMessage)
            XCTAssertEqual(nameMessage.systemMessageType, .newConversation)
            XCTAssertEqual(nameMessage.text, self.name)
            XCTAssertEqual(nameMessage.users, [selfUser, user1])
            XCTAssertFalse(nameMessage.allTeamUsersAdded)
            XCTAssertEqual(nameMessage.numberOfGuestsAdded, 0)
        }
    }

    func testThatItDoesSetAllTeamUsersAddedWhenItIsTheCaseForTeamUser() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let team = self.createTeam(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let membership = self.createMembership(in: self.syncMOC, user: selfUser, team: team)
            membership.permissions = .admin

            let user1 = self.createTeamMember(in: self.syncMOC, for: team)
            let user2 = self.createTeamMember(in: self.syncMOC, for: team)

            // when
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [user1, user2], name: self.name, team: team)
            guard let nameMessage = conversation?.lastMessage as? ZMSystemMessage else { return XCTFail() }

            XCTAssertNotNil(nameMessage)
            XCTAssertEqual(nameMessage.systemMessageType, .newConversation)
            XCTAssertEqual(nameMessage.text, self.name)
            XCTAssertEqual(nameMessage.users, [selfUser, user1, user2])
            XCTAssert(nameMessage.allTeamUsersAdded)
            XCTAssertEqual(nameMessage.numberOfGuestsAdded, 0)
        }
    }

    func testThatItIncludesNumberOfGuestsAddedInNewConversationSystemMessageWithAllTeamUsers() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let team = self.createTeam(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let membership = self.createMembership(in: self.syncMOC, user: selfUser, team: team)
            membership.permissions = .admin

            let user1 = self.createTeamMember(in: self.syncMOC, for: team)
            let user2 = self.createTeamMember(in: self.syncMOC, for: team)
            let guest1 = self.createUser(onMoc: self.syncMOC)
            let guest2 = self.createUser(onMoc: self.syncMOC)

            // when
            let conversation = ZMConversation.insertGroupConversation(
                moc: self.syncMOC,
                participants: [user1, user2, guest1, guest2],
                name: self.name,
                team: team)
            guard let nameMessage = conversation?.lastMessage as? ZMSystemMessage else { return XCTFail() }

            XCTAssertNotNil(nameMessage)
            XCTAssertEqual(nameMessage.systemMessageType, .newConversation)
            XCTAssertEqual(nameMessage.text, self.name)
            XCTAssertEqual(nameMessage.users, [selfUser, user1, user2, guest2, guest1])
            XCTAssert(nameMessage.allTeamUsersAdded)
            XCTAssertEqual(nameMessage.numberOfGuestsAdded, 2)
        }
    }

    func testThatItIncludesNumberOfGuestsAddedInNewConversationSystemMessageWithoutAllTeamUsers() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let team = self.createTeam(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let membership = self.createMembership(in: self.syncMOC, user: selfUser, team: team)
            membership.permissions = .admin

            let user1 = self.createTeamMember(in: self.syncMOC, for: team)
            self.createTeamMember(in: self.syncMOC, for: team)
            let guest1 = self.createUser(onMoc: self.syncMOC)
            let guest2 = self.createUser(onMoc: self.syncMOC)

            // when
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [user1, guest1, guest2], name: self.name, team: team)
            guard let nameMessage = conversation?.lastMessage as? ZMSystemMessage else { return XCTFail() }

            XCTAssertNotNil(nameMessage)
            XCTAssertEqual(nameMessage.systemMessageType, .newConversation)
            XCTAssertEqual(nameMessage.text, self.name)
            XCTAssertEqual(nameMessage.users, [selfUser, user1, guest2, guest1])
            XCTAssertFalse(nameMessage.allTeamUsersAdded)
            XCTAssertEqual(nameMessage.numberOfGuestsAdded, 2)
        }
    }

}
