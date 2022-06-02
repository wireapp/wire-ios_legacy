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

final class AccountManagerTests: ZMConversationTestsBase {

    var url: URL!

    override func setUp() {
        super.setUp()
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        url = applicationSupport.appendingPathComponent("AccountManagerTests")
    }

    override func tearDown() {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        url = nil
        super.tearDown()
    }

    func testThatAccountsAndSelectedAccountAreEmptyInitially() {
        // given
        let manager = AccountManager(sharedDirectory: url)

        // then
        XCTAssertNil(manager.selectedAccount)
        XCTAssert(manager.accounts.isEmpty)
    }

    func testThatItCanAddAnAccount() {
        // given
        let manager = AccountManager(sharedDirectory: url)
        let account = Account(userName: "Jacob", userIdentifier: .create())

        // when
        manager.addOrUpdate(account)

        // then
        XCTAssertNil(manager.selectedAccount)
        XCTAssertEqual(manager.accounts, [account])
    }

    func testThatItCanRemoveAnAccount() {
        // given
        let manager = AccountManager(sharedDirectory: url)
        let account = Account(userName: "Jacob", userIdentifier: .create())

        // when
        manager.addOrUpdate(account)

        // then
        XCTAssertNil(manager.selectedAccount)
        XCTAssertEqual(manager.accounts, [account])

        // when
        manager.remove(account)

        // then
        XCTAssertNil(manager.selectedAccount)
        XCTAssertEqual(manager.accounts, [])
    }

    func testThatItCanSelectAnAccount() {
        // given
        let manager = AccountManager(sharedDirectory: url)
        let account = Account(userName: "Jacob", userIdentifier: .create())

        // when
        manager.addOrUpdate(account)
        manager.select(account)

        // then
        XCTAssertEqual(manager.selectedAccount, account)
        XCTAssertEqual(manager.accounts, [account])
    }

    func testThatItCanAddAndSelectAnAccount() {
        // given
        let manager = AccountManager(sharedDirectory: url)
        let account1 = Account(userName: "Silvan", userIdentifier: .create())
        let account2 = Account(userName: "Jacob", userIdentifier: .create())

        // when
        manager.addAndSelect(account1)

        // then
        XCTAssertEqual(manager.selectedAccount, account1)
        XCTAssertEqual(manager.accounts, [account1])

        // when
        manager.addAndSelect(account2)

        // then
        XCTAssertEqual(manager.selectedAccount, account2)
        XCTAssertEqual(manager.accounts, [account2, account1])
    }

    func testThatItCanDeleteAnAccountManager() {
        // given
        do {
            let manager = AccountManager(sharedDirectory: url)
            let account1 = Account(userName: "Silvan", userIdentifier: .create())
            let account2 = Account(userName: "Vytis", userIdentifier: .create(), teamName: "Wire")

            // when
            manager.addOrUpdate(account1)
            manager.addOrUpdate(account2)
            manager.select(account2)

            // then
            XCTAssertEqual(manager.selectedAccount, account2)
            XCTAssertEqual(manager.accounts, [account1, account2])
        }

        // when
        AccountManager.delete(at: url)

        // then
        do {
            let manager = AccountManager(sharedDirectory: url)
            XCTAssertNil(manager.selectedAccount)
            XCTAssertEqual(manager.accounts, [])
        }
    }

    func testThatItRemovesTheSelectedAccountWhenItIsRemoved() {
        // given
        let manager = AccountManager(sharedDirectory: url)
        let account = Account(userName: "Jacob", userIdentifier: .create())

        // when
        manager.addOrUpdate(account)
        manager.select(account)

        // then
        XCTAssertEqual(manager.selectedAccount, account)
        XCTAssertEqual(manager.accounts, [account])

        // when
        manager.remove(account)

        // then
        XCTAssertNil(manager.selectedAccount)
        XCTAssertEqual(manager.accounts, [])
    }

    func testThatItUpdatesExisitingAccountPropertiesFromStore() {
        // given
        let manager = AccountManager(sharedDirectory: url)
        let accountID = UUID.create()
        manager.addAndSelect(Account(userName: "Jacob", userIdentifier: accountID))
        let account = manager.selectedAccount!

        // when
        let updatedAccount = Account(userName: "Vytis", userIdentifier: accountID, teamName: "Wire")
        manager.addAndSelect(updatedAccount)

        // then
        XCTAssertTrue(manager.selectedAccount === account)
        XCTAssertEqual(account.userIdentifier, accountID)
        XCTAssertEqual(account.userName, "Vytis")
        XCTAssertEqual(account.teamName, "Wire")
    }

    func testThatItSortsAccountsWithoutTeamBeforeAccountsWithTeam() {
        // given
        let manager = AccountManager(sharedDirectory: url)
        let account1 = Account(userName: "Jacob", userIdentifier: .create())
        let account2 = Account(userName: "Jacob", userIdentifier: .create(), teamName: "Wire")

        // when
        manager.addOrUpdate(account2)
        manager.addOrUpdate(account1)

        // then
        XCTAssertEqual(manager.accounts, [account1, account2])
    }

    func testThatItSortsTeamAccountsAlphabetically() {
        // given
        let manager = AccountManager(sharedDirectory: url)
        let account1 = Account(userName: "Jacob", userIdentifier: .create(), teamName: "Wire")
        let account2 = Account(userName: "Vytis", userIdentifier: .create(), teamName: "Wire")

        // when
        manager.addOrUpdate(account2)
        manager.addOrUpdate(account1)

        // then
        XCTAssertEqual(manager.accounts, [account1, account2])
    }

    func testThatItSortsAccountsAlphabetically() {
        // given
        let manager = AccountManager(sharedDirectory: url)
        let account1 = Account(userName: "Jacob", userIdentifier: .create())
        let account2 = Account(userName: "Vytis", userIdentifier: .create())
        let account3 = Account(userName: "Jacob", userIdentifier: .create(), teamName: "Wire")
        let account4 = Account(userName: "Vytis", userIdentifier: .create(), teamName: "Wire")

        // when
        manager.addOrUpdate(account4)
        manager.addOrUpdate(account2)

        // then
        XCTAssertEqual(manager.accounts, [account2, account4])

        // when
        manager.addOrUpdate(account3)

        // then
        XCTAssertEqual(manager.accounts, [account2, account3, account4])

        // when
        manager.addOrUpdate(account1)

        // then
        XCTAssertEqual(manager.accounts, [account1, account2, account3, account4])
    }

}
