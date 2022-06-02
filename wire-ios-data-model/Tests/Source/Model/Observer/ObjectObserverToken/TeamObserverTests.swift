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

import XCTest
@testable import WireDataModel

class TestTeamObserver: NSObject, TeamObserver {

    var notifications = [TeamChangeInfo]()

    func clearNotifications() {
        notifications = []
    }

    func teamDidChange(_ changeInfo: TeamChangeInfo) {
        notifications.append(changeInfo)
    }
}

class TeamObserverTests: NotificationDispatcherTestBase {

    var teamObserver: TestTeamObserver!

    override func setUp() {
        super.setUp()
        teamObserver = TestTeamObserver()
    }

    override func tearDown() {
        teamObserver = nil
        super.tearDown()
    }

    var userInfoKeys: Set<String> {
        return [
            #keyPath(TeamChangeInfo.membersChanged),
            #keyPath(TeamChangeInfo.nameChanged),
            #keyPath(TeamChangeInfo.imageDataChanged)
        ]
    }

    func checkThatItNotifiesTheObserverOfAChange(_ team: Team, modifier: (Team) -> Void, expectedChangedFields: Set<String>, customAffectedKeys: AffectedKeys? = nil) {

        // given
        self.uiMOC.saveOrRollback()

        self.token = TeamChangeInfo.add(observer: teamObserver, for: team, managedObjectContext: self.uiMOC)

        // when
        modifier(team)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.uiMOC.saveOrRollback()

        // then
        let changeCount = teamObserver.notifications.count
        XCTAssertEqual(changeCount, 1)

        // and when
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(teamObserver.notifications.count, changeCount, "Should not have changed further once")

        guard let changes = teamObserver.notifications.first else { return }
        changes.checkForExpectedChangeFields(userInfoKeys: userInfoKeys,
                                             expectedChangedFields: expectedChangedFields)
    }

    func testThatItNotifiesTheObserverOfChangedName() {
        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        team.name = "bar"
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(team,
                                                     modifier: { $0.name =  "foo"},
                                                     expectedChangedFields: [#keyPath(TeamChangeInfo.nameChanged)]
        )

    }

    func testThatItNotifiesTheObserverOfChangedImageData() {
        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(team,
                                                     modifier: { $0.imageData = "image".data(using: .utf8)! },
                                                     expectedChangedFields: [#keyPath(TeamChangeInfo.imageDataChanged)]
        )
    }

    func testThatItNotifiesTheObserverOfInsertedMembers() {
        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(team,
                                                     modifier: {
                                                        let member = Member.insertNewObject(in: uiMOC)
                                                        member.team = $0
        },
                                                     expectedChangedFields: [#keyPath(TeamChangeInfo.membersChanged)]
        )
    }

    func testThatItNotifiesTheObserverOfDeletedMembers() {
        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        let member = Member.insertNewObject(in: uiMOC)
        member.team = team
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(team,
                                                     modifier: {
                                                        guard let member = $0.members.first else {
                                                            return XCTFail("No member? :(")
                                                        }
                                                        self.uiMOC.delete(member)
                                                        },
                                                     expectedChangedFields: [#keyPath(TeamChangeInfo.membersChanged)]
        )
    }

}
