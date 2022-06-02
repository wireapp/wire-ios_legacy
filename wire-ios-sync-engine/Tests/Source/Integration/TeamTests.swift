//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireDataModel
@testable import WireSyncEngine

class TestTeamObserver: NSObject, TeamObserver {

    var token: NSObjectProtocol!
    var observedTeam: Team?
    var notifications: [TeamChangeInfo] = []

    init(team: Team? = nil, userSession: ZMUserSession) {
        super.init()
        token = TeamChangeInfo.add(observer: self, for: team, managedObjectContext: userSession.managedObjectContext)
    }

    func teamDidChange(_ changeInfo: TeamChangeInfo) {
        if let observedTeam = observedTeam, (changeInfo.team as? Team) != observedTeam {
            return
        }
        notifications.append(changeInfo)
    }
}

class TeamTests: IntegrationTest {

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    func remotelyInsertTeam(members: [MockUser], isBound: Bool = true) -> MockTeam {
        var mockTeam: MockTeam!
        mockTransportSession.performRemoteChanges { (session) in
            mockTeam = session.insertTeam(withName: "Super-Team", isBound: isBound, users: Set(members))
            mockTeam.creator = members.first
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        return mockTeam
    }
}

// MARK: Notifications

extension TeamTests {

    func testThatItNotifiesAboutChangedTeamName() {
        // given
        let mockTeam = remotelyInsertTeam(members: [self.selfUser, self.user1])

        XCTAssert(login())
        guard let localSelfUser = user(for: selfUser) else { return XCTFail() }
        XCTAssertTrue(localSelfUser.hasTeam)

        let teamObserver = TestTeamObserver(team: nil, userSession: userSession!)

        // when
        mockTransportSession.performRemoteChanges { (_) in
            mockTeam.name = "Super-Duper-Team"
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(teamObserver.notifications.count, 1)
        guard let note = teamObserver.notifications.last else {
            return XCTFail("no notification received")
        }
        XCTAssertTrue(note.nameChanged)
    }
}

// MARK: Member removal
extension TeamTests {

    func testThatOtherUserCanBeRemovedRemotely() {
        // given
        let mockTeam = remotelyInsertTeam(members: [self.selfUser, self.user1])

        XCTAssert(login())

        let user = self.user(for: user1)!
        let localSelfUser = self.user(for: selfUser)!
        XCTAssert(user.hasTeam)
        XCTAssert(localSelfUser.hasTeam)

        // when
        mockTransportSession.performRemoteChanges { (session) in
            session.removeMember(with: self.user1, from: mockTeam)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(user.membership)
        XCTAssertTrue(user.isAccountDeleted)
    }

    func testThatAccountIsDeletedWhenSelfUserIsRemovedFromTeam() {
        // given
        let mockTeam = remotelyInsertTeam(members: [self.selfUser, self.user1])

        XCTAssert(login())

        XCTAssert(ZMUser.selfUser(in: userSession!.managedObjectContext).hasTeam)

        // when
        mockTransportSession.performRemoteChanges { (session) in
            session.removeMember(with: self.selfUser, from: mockTeam)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(userSession) // user should be logged from the account
        XCTAssertTrue(sessionManager!.accountManager.accounts.isEmpty) // account should be deleted
    }

    func testThatItNotifiesAboutOtherUserRemovedRemotely() {
        // given
        let mockTeam = remotelyInsertTeam(members: [self.selfUser, self.user1])

        XCTAssert(login())
        let teamObserver = TestTeamObserver(team: nil, userSession: userSession!)

        // when
        mockTransportSession.performRemoteChanges { (session) in
            session.removeMember(with: self.user1, from: mockTeam)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(teamObserver.notifications.count, 1)
        guard let change = teamObserver.notifications.last else {
            return XCTFail("no notification received")
        }
        XCTAssertTrue(change.membersChanged)
    }

}
