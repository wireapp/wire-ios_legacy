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

class ManagedObjectContextChangeObserverTests: ZMBaseManagedObjectTest {

    func testThatItCallsTheCallbackWhenObjectsAreInserted() {
        // given
        let changeExpectation = expectation(description: "The callback should be called")
        let sut = ManagedObjectContextChangeObserver(context: uiMOC) {
            changeExpectation.fulfill()
        }

        // when
        uiMOC.perform {
            _ = ZMMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        _ = sut
    }

    func testThatItCallsTheCallbackWhenObjectsAreDeleted() {
        // given
        let message = ZMMessage(nonce: UUID(), managedObjectContext: uiMOC)
        XCTAssert(uiMOC.saveOrRollback())

        let changeExpectation = expectation(description: "The callback should be called")
        let sut = ManagedObjectContextChangeObserver(context: uiMOC) {
            changeExpectation.fulfill()
        }

        // when
        uiMOC.perform {
            self.uiMOC.delete(message)
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        _ = sut
    }

    func testThatItCallsTheCallbackWhenObjectsAreUpdated() {
        // given
        let message = ZMMessage(nonce: UUID(), managedObjectContext: uiMOC)
        XCTAssert(uiMOC.saveOrRollback())

        let changeExpectation = expectation(description: "The callback should be called")
        let sut = ManagedObjectContextChangeObserver(context: uiMOC) {
            changeExpectation.fulfill()
        }

        // when
        uiMOC.perform {
            message.markAsSent()
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        _ = sut
    }

    func testThatItRemovesItselfAsObserverWhenReleased() {
        // given
        var called = false
        var sut: ManagedObjectContextChangeObserver? = ManagedObjectContextChangeObserver(context: uiMOC) {
            called = true
        }

        // when
        _ = sut
        sut = nil
        uiMOC.perform {
            _ = ZMMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
        }

        // then
        spinMainQueue(withTimeout: 0.05)
        XCTAssertFalse(called)
    }

}
