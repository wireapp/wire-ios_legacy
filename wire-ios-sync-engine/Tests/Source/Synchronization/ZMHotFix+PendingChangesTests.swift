//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

class HotFix_PendingChangesTests: IntegrationTestBase {

    // MARK: – HotFix 62.3.1

    func testThatItReportsPendingHotFixChangesWhenTheSelfUserNeedsToBeUpdated() {
        // given
        XCTAssertTrue(logInAndWaitForSyncToBeComplete())
        let selfUser = ZMUser.selfUser(in: uiMOC)
        XCTAssertFalse(selfUser.needsToBeUpdatedFromBackend)
        selfUser.needsToBeUpdatedFromBackend = true

        // then
        XCTAssertTrue(userSession.isPendingHotFixChanges)
    }

    func testThatItDoesNotReportPendingHotFixChangesWhenTheSelfUserDoesNotNeedToBeUpdated() {
        // given
        XCTAssertTrue(logInAndWaitForSyncToBeComplete())
        let selfUser = ZMUser.selfUser(in: uiMOC)
        XCTAssertFalse(selfUser.needsToBeUpdatedFromBackend)

        // then
        XCTAssertFalse(userSession.isPendingHotFixChanges)
    }

    func testThatItDoesNotReportPendingHotFixChangesWhenAUserOtherThanTheSelfUserNeedsToBeUpdated() {
        // given
        XCTAssertTrue(logInAndWaitForSyncToBeComplete())
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = .create()
        uiMOC.saveOrRollback()
        XCTAssertTrue(waitForEverythingToBeDone())

        let selfUser = ZMUser.selfUser(in: uiMOC)
        XCTAssertFalse(otherUser.needsToBeUpdatedFromBackend)
        XCTAssertFalse(selfUser.needsToBeUpdatedFromBackend)
        otherUser.needsToBeUpdatedFromBackend = true

        // then
        XCTAssertFalse(userSession.isPendingHotFixChanges)
    }

}
