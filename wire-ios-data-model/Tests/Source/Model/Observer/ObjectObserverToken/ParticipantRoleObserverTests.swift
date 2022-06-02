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

import XCTest
@testable import WireDataModel

final class TestParticipantRoleObserver: NSObject, ParticipantRoleObserver {

    var notifications = [ParticipantRoleChangeInfo]()

    func clearNotifications() {
        notifications = []
    }

    func participantRoleDidChange(_ changeInfo: ParticipantRoleChangeInfo) {
        notifications.append(changeInfo)
    }
}

final class ParticipantRoleObserverTests: NotificationDispatcherTestBase {

    var observer: TestParticipantRoleObserver!

    override func setUp() {
        super.setUp()
        observer = TestParticipantRoleObserver()
    }

    override func tearDown() {
        observer = nil
        super.tearDown()
    }

    var userInfoKeys: Set<String> {
        return [
            #keyPath(ParticipantRoleChangeInfo.roleChanged)
        ]
    }

    func checkThatItNotifiesTheObserverOfAChange(_ participantRole: ParticipantRole, modifier: (ParticipantRole) -> Void, expectedChangedFields: Set<String>, customAffectedKeys: AffectedKeys? = nil,
                                                 file: StaticString = #file,
                                                 line: UInt = #line) {

        // given
        uiMOC.saveOrRollback()

        self.token = ParticipantRoleChangeInfo.add(observer: observer, for: participantRole, managedObjectContext: self.uiMOC)

        // when
        modifier(participantRole)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.uiMOC.saveOrRollback()

        // then
        let changeCount = observer.notifications.count
        if !expectedChangedFields.isEmpty {
            XCTAssertEqual(changeCount, 1, "Observer expected 1 notification, but received \(changeCount).", file: file, line: line)
        } else {
            XCTAssertEqual(changeCount, 0, "Observer was notified, but DID NOT expect a notification", file: file, line: line)
        }

        // and when
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(observer.notifications.count, changeCount, "Should not have changed further once")

        guard let changes = observer.notifications.first else { return }
        changes.checkForExpectedChangeFields(userInfoKeys: userInfoKeys,
                                             expectedChangedFields: expectedChangedFields,
                                             file: file,
                                             line: line)
    }
}
