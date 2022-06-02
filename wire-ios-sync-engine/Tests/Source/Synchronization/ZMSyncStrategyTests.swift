//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

extension ZMSyncStrategyTests {
    func testThatContextChangeTrackerIsInformed_WhenObjectIsInserted_OnUIContext() {
        // given
        _ = ZMClientMessage(nonce: NSUUID.create(), managedObjectContext: uiMOC)

        // when
        uiMOC.saveOrRollback()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // then
        XCTAssertTrue(mockContextChangeTracker.objectsDidChangeCalled)
    }

    func testThatContextChangeTrackerIsInformed_WhenObjectIsInserted_OnSyncContext() {
        // given
        syncMOC.performGroupedBlockThenWait(forReasonableTimeout: { [self] in
            _ = ZMClientMessage(nonce: NSUUID.create(), managedObjectContext: syncMOC)
        })

        // when
        syncMOC.performGroupedBlockThenWait(forReasonableTimeout: { [self] in
            XCTAssertTrue(syncMOC.saveOrRollback())
        })
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // then
        XCTAssertTrue(mockContextChangeTracker.objectsDidChangeCalled)
    }

    func testThatItNotifiesTheOperationLoopOfNewOperation_WhenContextIsSaved() {
        // expect
        expectation(forNotification: NSNotification.Name("RequestAvailableNotification"), object: nil, handler: nil)

        // when
        _ = ZMClientMessage(nonce: NSUUID.create(), managedObjectContext: uiMOC)
        uiMOC.saveOrRollback()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
}
