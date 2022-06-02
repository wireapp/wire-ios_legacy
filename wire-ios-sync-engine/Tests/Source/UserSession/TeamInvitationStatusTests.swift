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

import XCTest
import WireTesting

@testable import WireSyncEngine

class TeamInvitationStatusTests: ZMTBaseTest {

    let exampleEmailAddress1 = "example1@test.com"
    let exampleEmailAddress2 = "example2@test.com"

    var sut: TeamInvitationStatus!

    override func setUp() {
        super.setUp()

        sut = TeamInvitationStatus()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func testThatInvitedEmailIsReturnedOnce() {
        // given
        sut.invite(exampleEmailAddress1, completionHandler: { _ in })

        // when
        let email1 = sut.nextEmail()
        let email2 = sut.nextEmail()

        // then
        XCTAssertEqual(email1, exampleEmailAddress1)
        XCTAssertNil(email2)
    }

    func testThatRepeatedlyInvitedEmailIsStillOnlyReturnedOnce() {
        // given
        sut.invite(exampleEmailAddress1, completionHandler: { _ in })
        sut.invite(exampleEmailAddress1, completionHandler: { _ in })

        // when
        let email1 = sut.nextEmail()
        let email2 = sut.nextEmail()

        // then
        XCTAssertEqual(email1, exampleEmailAddress1)
        XCTAssertNil(email2)
    }

    func testThatMultipleInvitesAreReturned() {
        // given
        sut.invite(exampleEmailAddress1, completionHandler: { _ in })
        sut.invite(exampleEmailAddress2, completionHandler: { _ in })

        // when
        let email1 = sut.nextEmail()
        let email2 = sut.nextEmail()

        // then
        let emails = Set([email1, email2].compactMap { $0 })
        let expectedEmails = Set([exampleEmailAddress1, exampleEmailAddress2])
        XCTAssertEqual(emails, expectedEmails)
    }

    func testThatInvitedEmailIsReturnedAgainAfterRetrying() {
        // given
        sut.invite(exampleEmailAddress1, completionHandler: { _ in })
        XCTAssertEqual(sut.nextEmail(), exampleEmailAddress1)

        // when
        sut.retry(exampleEmailAddress1)

        // then
        XCTAssertEqual(sut.nextEmail(), exampleEmailAddress1)
    }

    func testThatCompletionHandlerIsCalledWhenProcessingResponse() {
        // given
        let expectaction = expectation(description: "Completion handler was called")
        sut.invite(exampleEmailAddress1, completionHandler: { _ in
            expectaction.fulfill()
        })

        // when
        _ = sut.nextEmail()
        sut.handle(result: .success(email: exampleEmailAddress1), email: exampleEmailAddress1)

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatCompletionHandlerIsRemovedAfterProcessingResponse() {
        var completionHandlerCallCount = 0

        // given
        sut.invite(exampleEmailAddress1, completionHandler: { _ in
            completionHandlerCallCount += 1
        })

        // when
        _ = sut.nextEmail()
        sut.handle(result: .success(email: exampleEmailAddress1), email: exampleEmailAddress1)
        sut.handle(result: .success(email: exampleEmailAddress1), email: exampleEmailAddress1)

        // then
        XCTAssertEqual(completionHandlerCallCount, 1)
    }

}
