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

class AvailabilityBehaviourChangeTests: ModelObjectsTests {

    func selfUserWithTeam() -> ZMUser {
        let team = self.createTeam(in: uiMOC)
        let selfUser = ZMUser.selfUser(in: uiMOC)
        _ = self.createMembership(in: uiMOC, user: selfUser, team: team)
        return selfUser
    }

    func testThatNonTeamUserIsNotNotified() {
        // given
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // when
        WireDataModel.AvailabilityBehaviourChange.notifyAvailabilityBehaviourChange(in: uiMOC)

        // then
        XCTAssertEqual(selfUser.needsToNotifyAvailabilityBehaviourChange, [])
    }

    func testThatTeamUserIsNotified() {
        // given
        let selfUser = selfUserWithTeam()

        // when
        WireDataModel.AvailabilityBehaviourChange.notifyAvailabilityBehaviourChange(in: uiMOC)

        // then
        XCTAssertEqual(selfUser.needsToNotifyAvailabilityBehaviourChange, [.alert])
    }

    func testThatTeamUserIsNotified_WithNotification_IfAway() {
        // given
        let selfUser = selfUserWithTeam()
        selfUser.availability = .away

        // when
        WireDataModel.AvailabilityBehaviourChange.notifyAvailabilityBehaviourChange(in: uiMOC)

        // then
        XCTAssertEqual(selfUser.needsToNotifyAvailabilityBehaviourChange, [.alert, .notification])
    }

    func testThatTeamUserIsNotified_WithNotification_IfBusy() {
        // given
        let selfUser = selfUserWithTeam()
        selfUser.availability = .busy

        // when
        WireDataModel.AvailabilityBehaviourChange.notifyAvailabilityBehaviourChange(in: uiMOC)

        // then
        XCTAssertEqual(selfUser.needsToNotifyAvailabilityBehaviourChange, [.alert, .notification])
    }

}
