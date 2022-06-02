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
@testable import WireDataModel

final class AccountStoreTests: ZMConversationTestsBase {

    var url: URL!

    override func setUp() {
        super.setUp()
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        url = applicationSupport.appendingPathComponent("AccountStoreTests")
    }

    override func tearDown() {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        url = nil
        super.tearDown()
    }

    func testThatItCreatesAnEmptyStore() {
        // given
        let store = AccountStore(root: url)

        // then
        XCTAssertEqual(store.load(), [])
    }

    func testThatItCanStoreAndRetrieveAnAccount() {
        // given
        let store = AccountStore(root: url)
        let account = Account(userName: "Silvan", userIdentifier: .create())

        // when
        XCTAssert(store.add(account))

        // then
        XCTAssertEqual(store.load(), [account])
    }

    func testThatItCanRemoveAnAccount() {
        // given
        let store = AccountStore(root: url)
        let account = Account(userName: "Jacob", userIdentifier: .create())

        XCTAssert(store.add(account))
        XCTAssertEqual(store.load(), [account])

        // when
        XCTAssert(store.remove(account))

        // then
        XCTAssertEqual(store.load(), [])
    }

    func testThatItCanDeleteAnAccountStore() {
        // given
        do {
            let store = AccountStore(root: url)
            let account = Account(userName: "John", userIdentifier: .create())

            XCTAssert(store.add(account))
            XCTAssertEqual(store.load(), [account])
        }

        // when
        XCTAssert(AccountStore.delete(at: url))

        // then
        do {
            let store = AccountStore(root: url)
            XCTAssertEqual(store.load(), [])
        }
    }

    func testThatItReturnsFalseWhenTryingToDeleteANonExistentAccountStore() {
        // then
        performIgnoringZMLogError {
            XCTAssertFalse(AccountStore.delete(at: self.url))
        }
    }

    func testThatItCanStoreMultipleAccounts() {
        // given
        let store = AccountStore(root: url)
        let account1 = Account(userName: "Sabine", userIdentifier: .create())
        let account2 = Account(userName: "Mike", userIdentifier: .create())

        // when
        XCTAssert(store.add(account1))
        XCTAssert(store.add(account2))

        // then
        XCTAssertEqual(store.load(), [account1, account2])
    }

    func testThatItOnlyRemovesSpecifiedAccounts() {
        // given
        let store = AccountStore(root: url)
        let account1 = Account(userName: "Vytis", userIdentifier: .create())
        let account2 = Account(userName: "Dasha", userIdentifier: .create())

        XCTAssert(store.add(account1))
        XCTAssert(store.add(account2))

        let stored = store.load()
        XCTAssertEqual(stored, [account1, account2])

        // when
        XCTAssert(store.remove(account2))

        // then
        XCTAssertEqual(store.load(), [account1])

        // when
        XCTAssert(store.remove(account1))

        // then
        XCTAssertEqual(store.load(), [])
    }

    func testThatItReturnsFalseIfTheAccountToBeRemovedIsNotContainedInTheStore() {
        // given
        let store = AccountStore(root: url)
        let account1 = Account(userName: "Vytis", userIdentifier: .create())
        let account2 = Account(userName: "Dasha", userIdentifier: .create())

        // when
        XCTAssert(store.add(account1))
        XCTAssertEqual(store.load(), [account1])

        // then
        XCTAssertFalse(store.remove(account2))
    }

    func testThatItUpdatesAnExistingAccount() {
        // given
        let store = AccountStore(root: url)
        let uuid = UUID.create()

        do {
            let account = Account(userName: "Silvan", userIdentifier: uuid)
            XCTAssert(store.add(account))
            XCTAssertEqual(store.load(), [account])
        }

        // when
        let name = "Marco", team = "Wire"
        do {
            let account = Account(userName: name, userIdentifier: uuid, teamName: team)
            XCTAssert(store.add(account))
        }

        // then
        guard let account = store.load(uuid) else { return XCTFail("Unable to load account") }
        XCTAssertEqual(account.userName, name)
        XCTAssertEqual(account.teamName, team)
        XCTAssertNil(account.imageData)
        XCTAssertNil(account.teamImageData)
    }

    func testThatItUpdatesAnExistingAccount_WithImages() {
        // given
        let store = AccountStore(root: url)
        let uuid = UUID.create()

        do {
            let account = Account(userName: "Silvan", userIdentifier: uuid)
            XCTAssert(store.add(account))
            XCTAssertEqual(store.load(), [account])
        }

        // when
        let name = "Marco", team = "Wire", image = verySmallJPEGData()
        do {
            let account = Account(userName: name, userIdentifier: uuid, teamName: team, imageData: image, teamImageData: image)
            XCTAssert(store.add(account))
        }

        // then
        guard let account = store.load(uuid) else { return XCTFail("Unable to load account") }
        XCTAssertEqual(account.userName, name)
        XCTAssertEqual(account.teamName, team)
        XCTAssertEqual(account.imageData, image)
        XCTAssertEqual(account.teamImageData, image)
    }

    func testThatItCanLoadAnAccountByUUID() {
        // given
        let store = AccountStore(root: url)
        let uuid = UUID.create()

        // when
        let account = Account(userName: "Sabine", userIdentifier: uuid)
        XCTAssert(store.add(account))
        XCTAssertEqual(store.load(uuid), account)
    }

    func testThatItDoesNotReturnAnAccountForAnUUIDIfThereIsNone() {
        // given
        let store = AccountStore(root: url)
        let uuid = UUID.create()

        // when
        let account = Account(userName: "Vytis", userIdentifier: uuid)
        XCTAssert(store.add(account))
        XCTAssertNil(store.load(.create()))
    }

    func testThatItReturnsTrueForAccountsContainedInTheStore() {
        // given
        let store = AccountStore(root: url)
        let uuid = UUID.create()

        // when
        let account = Account(userName: "Mike", userIdentifier: uuid)
        XCTAssert(store.add(account))

        // then
        XCTAssert(store.contains(account))
    }

    func testThatItReturnsFalseForAccountsNotContainedInTheStore() {
        // given
        let store = AccountStore(root: url)

        // when
        let account1 = Account(userName: "Jacob", userIdentifier: .create())
        let account2 = Account(userName: "Dasha", userIdentifier: .create())
        XCTAssert(store.add(account1))

        // then
        XCTAssertFalse(store.contains(account2))
    }

    func testThatASecondAccountAtTheSameLocationShowsTheSameAccounts() {
        // given
        let account1 = Account(userName: "John", userIdentifier: .create())
        let account2 = Account(userName: "Sabine", userIdentifier: .create())

        // when
        do {
            let store = AccountStore(root: url)
            XCTAssert(store.add(account1))
            XCTAssert(store.add(account2))
        }

        // then
        do {
            let store = AccountStore(root: url)
            XCTAssertEqual(store.load(), [account1, account2])
        }
    }

    func testThatItOnlyReadsFilesNamedByUUIDs() throws {
        // given
        let store = AccountStore(root: url)
        let account1 = Account(userName: "John", userIdentifier: .create())
        let account2 = Account(userName: "Sabine", userIdentifier: .create())

        // when
        let invalidAccountUrl = url.appendingPathComponent("Accounts/invalid_account")
        try account1.write(to: invalidAccountUrl)

        // then
        XCTAssert(store.load().isEmpty)

        // when
        store.add(account2)

        // then
        XCTAssertEqual(store.load(), [account2])
    }

    func testThatItDecodesAccountOnDiskWithoutLoginCredentials() throws {
        // given
        let store = AccountStore(root: url)
        let accountID = UUID(uuidString: "012B6D4F-590B-4355-AC8A-8A531F9F30EE")!

        let accountJSON = """
        {
            "name": "Alexis",
            "identifier": "\(accountID)",
            "team": "Wire",
            "image": "",
            "unreadConversationCount": 1
        }
        """.data(using: .utf8)!

        try accountJSON.write(to: url.appendingPathComponent("Accounts/" + accountID.uuidString))

        // when
        let account = store.load(accountID)

        // then
        let expectedAccount = Account(userName: "Alexis", userIdentifier: accountID, teamName: "Wire", imageData: Data(), teamImageData: nil, unreadConversationCount: 1, loginCredentials: nil)
        XCTAssertEqual(account, expectedAccount)
    }

    func testThatItDecodesAccountOnDiskWithLoginCredentials() throws {
        // given
        let store = AccountStore(root: url)
        let accountID = UUID(uuidString: "012B6D4F-590B-4355-AC8A-8A531F9F30EE")!

        let accountJSON = """
        {
            "name": "Alexis",
            "identifier": "\(accountID)",
            "team": "Wire",
            "image": "",
            "unreadConversationCount": 0,
            "loginCredentials": {
                "emailAddress": "alexis@example.com",
                "hasPassword": true,
                "usesCompanyLogin": false
            }
        }
        """.data(using: .utf8)!

        try accountJSON.write(to: url.appendingPathComponent("Accounts/" + accountID.uuidString))

        // when
        let account = store.load(accountID)

        // then
        let expectedCredentials = LoginCredentials(emailAddress: "alexis@example.com", phoneNumber: nil, hasPassword: true, usesCompanyLogin: false)
        let expectedAccount = Account(userName: "Alexis", userIdentifier: accountID, teamName: "Wire", imageData: Data(), teamImageData: nil, unreadConversationCount: 0, loginCredentials: expectedCredentials)
        XCTAssertEqual(account, expectedAccount)
    }

}
