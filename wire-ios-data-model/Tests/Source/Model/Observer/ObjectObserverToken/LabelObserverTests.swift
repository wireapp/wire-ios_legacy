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

final class TestLabelObserver: NSObject, LabelObserver {

    var notifications = [LabelChangeInfo]()

    func clearNotifications() {
        notifications = []
    }

    func labelDidChange(_ changeInfo: LabelChangeInfo) {
        notifications.append(changeInfo)
    }

}

final class LabelObserverTests: NotificationDispatcherTestBase {

    var labelObserver: TestLabelObserver!

    override func setUp() {
        super.setUp()
        labelObserver = TestLabelObserver()
    }

    override func tearDown() {
        labelObserver = nil
        super.tearDown()
    }

    var userInfoKeys: Set<String> {
        return [
            #keyPath(LabelChangeInfo.nameChanged)
        ]
    }

    func checkThatItNotifiesTheObserverOfAChange(_ team: Label, modifier: (Label) -> Void, expectedChangedFields: Set<String>, customAffectedKeys: AffectedKeys? = nil) {

        // given
        self.uiMOC.saveOrRollback()

        self.token = LabelChangeInfo.add(observer: labelObserver, for: team, managedObjectContext: self.uiMOC)

        // when
        modifier(team)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.uiMOC.saveOrRollback()

        // then
        let changeCount = labelObserver.notifications.count
        XCTAssertEqual(changeCount, 1)

        // and when
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(labelObserver.notifications.count, changeCount, "Should not have changed further once")

        guard let changes = labelObserver.notifications.first else { return }
        changes.checkForExpectedChangeFields(userInfoKeys: userInfoKeys, expectedChangedFields: expectedChangedFields)
    }

    func testThatItNotifiesTheObserverOfChangedName() {
        // given
        let label = Label.insertNewObject(in: self.uiMOC)
        label.name = "bar"
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(label,
                                                     modifier: { $0.name =  "foo"},
                                                     expectedChangedFields: [#keyPath(LabelChangeInfo.nameChanged)]
        )

    }

}
