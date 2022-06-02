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

import WireTesting
@testable import WireRequestStrategy

class AssetRequestFactoryTests: ZMTBaseTest {

    var coreDataStack: CoreDataStack!

    override func setUp() {
        super.setUp()
        self.coreDataStack = createCoreDataStack()
    }

    override func tearDown() {
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.coreDataStack = nil
        super.tearDown()
    }

    func testThatItReturnsExpiringForRegularConversation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: coreDataStack.viewContext)

        // when & then
        XCTAssertEqual(AssetRequestFactory.Retention(conversation: conversation), .expiring)
    }

    func testThatItReturnsEternalInfrequentAccessForTeamUserConversation() {
        let moc = coreDataStack.syncContext
        moc.performGroupedBlock {
            // given
            let conversation = ZMConversation.insertNewObject(in: moc)
            let team = Team.insertNewObject(in: moc)
            team.remoteIdentifier = .init()

            // when
            let selfUser = ZMUser.selfUser(in: moc)
            let membership = Member.getOrCreateMember(for: selfUser, in: team, context: moc)
            XCTAssertNotNil(membership.team)
            XCTAssertTrue(selfUser.hasTeam)

            // then
            XCTAssertEqual(AssetRequestFactory.Retention(conversation: conversation), .eternalInfrequentAccess)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testThatItReturnsEternalInfrequentAccessForConversationWithTeam() {
        let moc = coreDataStack.syncContext
        moc.performGroupedBlock {
            // given
            let conversation = ZMConversation.insertNewObject(in: moc)

            // when
            conversation.team = .insertNewObject(in: moc)
            conversation.team?.remoteIdentifier = .init()

            // then
            XCTAssert(conversation.hasTeam)
            XCTAssertEqual(AssetRequestFactory.Retention(conversation: conversation), .eternalInfrequentAccess)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testThatItReturnsEternalInfrequentAccessForAConversationWithAParticipantsWithTeam() {

        // given
        let user = ZMUser.insertNewObject(in: coreDataStack.viewContext)
        user.remoteIdentifier = UUID()
        user.teamIdentifier = .init()

        // when
        guard let conversation = ZMConversation.insertGroupConversation(session: self.coreDataStack, participants: [user]) else { return XCTFail("no conversation") }

        // then
        XCTAssert(conversation.containsTeamUser)
        XCTAssertEqual(AssetRequestFactory.Retention(conversation: conversation), .eternalInfrequentAccess)
    }

}
