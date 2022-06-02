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
@testable import WireSyncEngine

class ZMLocalNotificationTests_Alerts: ZMLocalNotificationTests {

    func addSelfUserToTeam() {

        let team = Team.insertNewObject(in: self.uiMOC)
        team.name = "Team-A"
        let user = ZMUser.selfUser(in: self.uiMOC)
        self.performPretendingUiMocIsSyncMoc {
            _ = Member.getOrCreateMember(for: user, in: team, context: self.uiMOC)
        }
    }

    func testAvailabilityBehaviourChangeNotification_WhenAway() {
        // given
        addSelfUserToTeam()

        // when
        let note = ZMLocalNotification(availability: .away, managedObjectContext: uiMOC)

        // then
        XCTAssertEqual(note?.title, "Notifications are disabled in Team-A")
        XCTAssertEqual(note?.body, "Status affects notifications now. You’re set to “Away” and won’t receive any notifications.")
    }

    func testAvailabilityBehaviourChangeNotification_WhenBusy() {
        // given
        addSelfUserToTeam()

        // when
        let note = ZMLocalNotification(availability: .busy, managedObjectContext: uiMOC)

        // then
        XCTAssertEqual(note?.title, "Notifications have changed in Team-A")
        XCTAssertEqual(note?.body, "Status affects notifications now. You’re set to “Busy” and will only receive notifications when someone mentions you or replies to one of your messages.")
    }

}
