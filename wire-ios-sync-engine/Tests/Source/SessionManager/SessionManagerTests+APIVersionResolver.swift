//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

class SessionManagerTests_APIVersionResolver: IntegrationTest {

    func testThatDatabaseIsMigrated_WhenFederationIsEnabled() throws {
        // GIVEN

        // Setup Session Manager
        let sessionManager = try XCTUnwrap(self.sessionManager)
        let account = addAccount(name: "John Doe", userIdentifier: UUID())
        sessionManager.accountManager.select(account)

        // Load session
        var session: ZMUserSession!
        sessionManager.loadSession(for: account, completion: {
            session = $0
        })

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Create user and conversation
        let user = ZMUser.insertNewObject(in: session.syncContext)
        let conversation = ZMConversation.insertNewObject(in: session.syncContext)
        user.remoteIdentifier = UUID()
        conversation.remoteIdentifier = UUID()

        XCTAssertNil(user.domain)
        XCTAssertNil(conversation.domain)

        // Setup domain
        let domain = "example.domain.com"
        APIVersion.domain = domain

        // Setup expectation & Session Manager delegate
        let expectation = XCTestExpectation(description: "Migration completed")
        let delegate = MockSessionManagerDelegate()
        delegate.expectation = expectation
        sessionManager.delegate = delegate

        // WHEN
        sessionManager.apiVersionResolverDetectedFederationHasBeenEnabled()

        // THEN
        XCTAssertTrue(delegate.didCallWillMigrateAccount)

        wait(for: [expectation], timeout: 5)

        XCTAssertTrue(delegate.didCallDidPerformFederationMigration)
        XCTAssertTrue(delegate.didCallDidChangeActiveUserSession)
        let newSession = try XCTUnwrap(delegate.session)

        let migratedUser = ZMUser.fetch(with: user.remoteIdentifier, domain: domain, in: newSession.syncContext)
        XCTAssertNotNil(migratedUser)
        XCTAssertEqual(migratedUser?.domain, domain)

        let migratedConversation = ZMConversation.fetch(with: conversation.remoteIdentifier!, domain: domain, in: newSession.syncContext)
        XCTAssertNotNil(migratedConversation)
        XCTAssertEqual(migratedConversation?.domain, domain)

        userSession = nil
    }
}

private class MockSessionManagerDelegate: SessionManagerDelegate {
    var didCallDidPerformFederationMigration: Bool = false
    var expectation: XCTestExpectation?
    func sessionManagerDidPerformFederationMigration(authenticated: Bool) {
        didCallDidPerformFederationMigration = true
        expectation?.fulfill()
    }

    var didCallWillMigrateAccount: Bool = false
    func sessionManagerWillMigrateAccount(userSessionCanBeTornDown: @escaping () -> Void) {
        didCallWillMigrateAccount = true
        userSessionCanBeTornDown()
    }

    var didCallDidChangeActiveUserSession: Bool = false
    var session: ZMUserSession?
    func sessionManagerDidChangeActiveUserSession(userSession: ZMUserSession) {
        didCallDidChangeActiveUserSession = true
        session = userSession
    }

    func sessionManagerDidReportLockChange(forSession session: UserSessionAppLockInterface) {
        // no op
    }

    func sessionManagerDidFailToLogin(error: Error?) {
        // no op
    }

    func sessionManagerWillLogout(error: Error?, userSessionCanBeTornDown: (() -> Void)?) {
        // no op
    }

    func sessionManagerWillOpenAccount(_ account: Account, from selectedAccount: Account?, userSessionCanBeTornDown: @escaping () -> Void) {
        // no op
    }

    func sessionManagerDidFailToLoadDatabase() {
        // no op
    }

    func sessionManagerDidBlacklistCurrentVersion(reason: BlacklistReason) {
        // no op
    }

    func sessionManagerDidBlacklistJailbrokenDevice() {
        // no op
    }

    var isInAuthenticatedAppState: Bool {
        return true
    }

    var isInUnathenticatedAppState: Bool {
        return false
    }

}
