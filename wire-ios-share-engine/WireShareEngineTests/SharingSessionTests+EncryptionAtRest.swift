//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import LocalAuthentication
import WireDataModel
@testable import WireShareEngine

class SharingSessionTestsEncryptionAtRest: BaseSharingSessionTests {

    // MARK: - Life Cycle

    override func tearDown() {
        // Delete keychain items
        let account = Account(userName: "", userIdentifier: accountIdentifier)
        try! EncryptionKeys.deleteKeys(for: account)

        super.tearDown()
    }

    // MARK: - Database locking/unlocking

    func testThatDatabaseIsUnlocked_WhenEncryptionAtRestIsDisabled() {
        // given
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sharingSession.isDatabaseLocked)
    }

    func testThatDatabaseIsLocked_BeforeUnlockingDatabase() throws {
        // given
        enableEncryptionAtRest()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sharingSession.coreDataStack.clearEncryptionKeysInAllContexts()

        // then
        XCTAssertTrue(sharingSession.isDatabaseLocked)
    }

    func testThatDatabaseIsUnlocked_AfterUnlockingDatabase() throws {
        // given
        enableEncryptionAtRest()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let context = LAContext()
        try sharingSession.unlockDatabase(with: context)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sharingSession.isDatabaseLocked)
    }

    // MARK: - Helpers

    func enableEncryptionAtRest() {
        let account = Account(userName: "", userIdentifier: accountIdentifier)

        try! EncryptionKeys.deleteKeys(for: account)
        sharingSession.coreDataStack.clearEncryptionKeysInAllContexts()

        let encryptionKeys = try! EncryptionKeys.createKeys(for: account)
        try! sharingSession.userInterfaceContext.enableEncryptionAtRest(encryptionKeys: encryptionKeys, skipMigration: true)

        sharingSession.userInterfaceContext.saveOrRollback()
    }

}
