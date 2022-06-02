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

import Foundation
import XCTest
import WireDataModel
@testable import WireSyncEngine

extension ZMUser {
    func mockSetExpires(at date: Date) {
        self.update(withTransportData: ["id": self.remoteIdentifier?.transportString() as Any,
                                        "expires_at": date.transportString()], authoritative: false)
    }
}

extension XCTestCase {
    func waitInRunLoop(for condition: () -> (Bool), tick: TimeInterval = 0.05) -> Bool {
        let maximumWait = Date(timeIntervalSinceNow: 5)

        while !condition() {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: tick))
            if Date().compare(maximumWait) == .orderedDescending {
                return false
            }
        }

        return true
    }
}

public class UserExpirationObserverTests: MessagingTest {
    var sut: UserExpirationObserver!

    override public func setUp() {
        super.setUp()
        sut = UserExpirationObserver(managedObjectContext: self.uiMOC)
    }

    override public func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItIgnoresNonExpiringUsers() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.name = "User"
        user.remoteIdentifier = UUID()
        user.needsToBeUpdatedFromBackend = false
        // when
        sut.check(users: Set([user]))
        // then
        XCTAssertFalse(user.needsToBeUpdatedFromBackend)
    }

    func testThatItMarkToBeFetchedExpiredUsers() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.name = "User"
        user.remoteIdentifier = UUID()
        user.needsToBeUpdatedFromBackend = false
        user.mockSetExpires(at: Date(timeIntervalSinceNow: -1))
        // when
        sut.check(users: Set([user]))
        // then
        XCTAssertTrue(user.needsToBeUpdatedFromBackend)
    }

    func testThatItDoesNotMarkSameUserTwice() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.name = "User"
        user.remoteIdentifier = UUID()
        user.needsToBeUpdatedFromBackend = false
        user.mockSetExpires(at: Date(timeIntervalSinceNow: 1))
        // when
        sut.check(users: Set([user]))
        // then
        XCTAssertFalse(user.needsToBeUpdatedFromBackend)
        XCTAssertTrue(sut.expiringUsers.contains(user))
        // when
        sut.check(users: Set([user]))
        // then
        XCTAssertFalse(user.needsToBeUpdatedFromBackend)
        XCTAssertTrue(sut.expiringUsers.contains(user))
    }

    func testThatItStartsTimerForExpiringUsers() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.name = "User"
        user.remoteIdentifier = UUID()
        user.needsToBeUpdatedFromBackend = false
        user.mockSetExpires(at: Date(timeIntervalSinceNow: 0.25))
        // when
        sut.check(users: Set([user]))
        // then
        XCTAssertFalse(user.needsToBeUpdatedFromBackend)
        XCTAssertTrue(sut.expiringUsers.contains(user))
        // when
        XCTAssertTrue(self.waitInRunLoop(for: { () -> (Bool) in
            user.needsToBeUpdatedFromBackend == true
        }))
        XCTAssertFalse(sut.expiringUsers.contains(user))
    }

    func testThatItDoesNotRetainItself() {
        weak var sut: UserExpirationObserver?
        autoreleasepool {
            let localSut = UserExpirationObserver(managedObjectContext: self.uiMOC)
            // given
            let user = ZMUser.insertNewObject(in: self.uiMOC)
            user.name = "User"
            user.remoteIdentifier = UUID()
            user.needsToBeUpdatedFromBackend = false
            user.mockSetExpires(at: Date(timeIntervalSinceNow: 100000))
            // when
            localSut.check(users: Set([user]))
            sut = localSut
            // then
            XCTAssertNotNil(sut)
        }

        // ...and then
        XCTAssertNil(sut)
    }
}
