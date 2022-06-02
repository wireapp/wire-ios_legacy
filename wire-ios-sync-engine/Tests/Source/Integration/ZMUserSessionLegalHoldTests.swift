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
import WireSyncEngine

class ZMUserSessionLegalHoldTests: IntegrationTest {

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    func testThatUserClientIsInsertedWhenUserReceivesLegalHoldRequest() {
        // GIVEN
        var team: MockTeam!

        // 1) I come from a legal-hold enabled team
        mockTransportSession.performRemoteChanges { session in
            team = session.insertTeam(withName: "Team", isBound: true, users: [self.selfUser])
            team.hasLegalHoldService = true
            team.creator = self.selfUser
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // 2) I log in
        XCTAssert(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let realSelfUser = user(for: selfUser)!
        XCTAssertEqual(realSelfUser.legalHoldStatus, .disabled)

        // 3) My team admin requests legal hold for me
        mockTransportSession.performRemoteChanges { _ in
            XCTAssertTrue(self.selfUser.requestLegalHold())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        guard case let .pending(legalHoldRequest) = realSelfUser.legalHoldStatus else {
            return XCTFail("No update event was fired for the incoming legal hold request.")
        }

        // WHEN: I accept the legal hold request
        let completionExpectation = expectation(description: "The request completes.")

        userSession?.accept(legalHoldRequest: legalHoldRequest, password: IntegrationTest.SelfUserPassword) { error in
            XCTAssertNil(error)
            completionExpectation.fulfill()
        }

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 1))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(realSelfUser.clients.count, 2)
        XCTAssertEqual(realSelfUser.legalHoldStatus, .enabled)
    }

    func testThatLegalHoldClientIsRemovedWhenLegalHoldRequestFails() {
        var team: MockTeam!

        // 1) I come from up a legal-hold enabled team
        mockTransportSession.performRemoteChanges { session in
            team = session.insertTeam(withName: "Team", isBound: true, users: [self.selfUser])
            team.hasLegalHoldService = true
            team.creator = self.selfUser
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // 2) I log in
        XCTAssert(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let realSelfUser = user(for: selfUser)!
        XCTAssertEqual(realSelfUser.legalHoldStatus, .disabled)

        // 3) My team admin requests legal hold for me (even though
        mockTransportSession.performRemoteChanges { _ in
            XCTAssertTrue(self.selfUser.requestLegalHold())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        guard case let .pending(legalHoldRequest) = realSelfUser.legalHoldStatus else {
            return XCTFail("No update event was fired for the incoming legal hold request.")
        }

        // WHEN: I accept the legal hold request with the wrong password
        let completionExpectation = expectation(description: "The request completes.")

        userSession?.accept(legalHoldRequest: legalHoldRequest, password: "I tRieD 3 tImeS!") { error in
            XCTAssertEqual(error, .invalidPassword)
            completionExpectation.fulfill()
        }

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 1))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(realSelfUser.clients.count, 1)
        XCTAssertEqual(realSelfUser.legalHoldStatus, .pending(legalHoldRequest))
    }

}
