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
//

@testable import WireDataModel
import XCTest

final class DatabaseMigrationTests: DatabaseBaseTest {

    func testThatItDoesNotMigrateFromANonE2EEVersionAndWipesTheDB() {

        // GIVEN
        self.createDatabaseWithOlderModelVersion(versionName: "1-24")

        // WHEN
        let directory = self.createStorageStackAndWaitForCompletion()

        // THEN
        let users = try! directory.viewContext.fetch(ZMUser.sortedFetchRequest())
        XCTAssertEqual(users.count, 1) // only self user
    }

    func testThatItPerformsMigrationFrom_1_25_ToCurrentModelVersion() {

        // GIVEN
        self.createDatabaseWithOlderModelVersion(versionName: "1-25")

        // WHEN
        let directory = self.createStorageStackAndWaitForCompletion(userID: DatabaseMigrationTests.testUUID)

        // THEN
        let conversationCount = try! directory.viewContext.count(for: ZMConversation.sortedFetchRequest())
        let messageCount = try! directory.viewContext.count(for: ZMTextMessage.sortedFetchRequest())
        let systemMessageCount = try! directory.viewContext.count(for: ZMSystemMessage.sortedFetchRequest())
        let connectionCount = try! directory.viewContext.count(for: ZMConnection.sortedFetchRequest())
        let userClientCount = try! directory.viewContext.count(for: UserClient.sortedFetchRequest())
        let helloWorldMessageCount = try! directory.viewContext.count(for: ZMTextMessage.sortedFetchRequest(with: NSPredicate(format: "%K BEGINSWITH[c] %@", "text", "Hello World")))
        let message = directory.viewContext.executeFetchRequestOrAssert(ZMTextMessage.sortedFetchRequest(with: NSPredicate(format: "%K == %@", "text", "You are the best Burno"))).first as? ZMMessage
        let messageServerTimestampTransportString = message?.serverTimestamp?.transportString()
        let userFetchRequest = ZMUser.sortedFetchRequest()
        userFetchRequest.resultType = .dictionaryResultType
        userFetchRequest.propertiesToFetch = self.userPropertiesToFetch
        let userDictionaries = directory.viewContext.executeFetchRequestOrAssert(userFetchRequest)

        XCTAssertEqual(conversationCount, 13)
        XCTAssertEqual(messageCount, 1681)
        XCTAssertEqual(systemMessageCount, 53)
        XCTAssertEqual(connectionCount, 5)
        XCTAssertEqual(userClientCount, 7)
        XCTAssertEqual(helloWorldMessageCount, 1515)

        XCTAssertNotNil(message)
        XCTAssertEqual(messageServerTimestampTransportString, "2015-12-18T16:57:06.836Z")

        XCTAssertNotNil(userDictionaries)
        XCTAssertEqual(userDictionaries.count, 7)
        XCTAssertEqual(userDictionaries as NSArray, DatabaseMigrationTests.userDictionaryFixture1_25 as NSArray)
    }

    func testThatItPerformsMigrationFrom_1_27_ToCurrentModelVersion() {

        // GIVEN
        self.createDatabaseWithOlderModelVersion(versionName: "1-27")

        // WHEN
        let directory = self.createStorageStackAndWaitForCompletion(userID: DatabaseMigrationTests.testUUID)

        // THEN
        let conversationCount = try! directory.viewContext.count(for: ZMConversation.sortedFetchRequest())
        let messageCount = try! directory.viewContext.count(for: ZMClientMessage.sortedFetchRequest())
        let systemMessageCount = try! directory.viewContext.count(for: ZMSystemMessage.sortedFetchRequest())
        let connectionCount = try! directory.viewContext.count(for: ZMConnection.sortedFetchRequest())
        let userClientCount = try! directory.viewContext.count(for: UserClient.sortedFetchRequest())

        let userFetchRequest = ZMUser.sortedFetchRequest()
        userFetchRequest.resultType = .dictionaryResultType
        userFetchRequest.propertiesToFetch = self.userPropertiesToFetch
        let userDictionaries = directory.viewContext.executeFetchRequestOrAssert(userFetchRequest)

        // THEN
        XCTAssertEqual(conversationCount, 18)
        XCTAssertEqual(messageCount, 27)
        XCTAssertEqual(systemMessageCount, 18)
        XCTAssertEqual(connectionCount, 9)
        XCTAssertEqual(userClientCount, 25)

        XCTAssertNotNil(userDictionaries)
        XCTAssertEqual(userDictionaries.count, 7)
        XCTAssertEqual(userDictionaries as NSArray, DatabaseMigrationTests.userDictionaryFixture1_27 as NSArray)
    }

    func testThatItPerformsMigrationFrom_1_28_ToCurrentModelVersion() {

        // GIVEN
        self.createDatabaseWithOlderModelVersion(versionName: "1-28")

        // WHEN
        let directory = self.createStorageStackAndWaitForCompletion(userID: DatabaseMigrationTests.testUUID)

        // THEN
        let conversationCount = try! directory.viewContext.count(for: ZMConversation.sortedFetchRequest())
        let messageCount = try! directory.viewContext.count(for: ZMClientMessage.sortedFetchRequest())
        let systemMessageCount = try! directory.viewContext.count(for: ZMSystemMessage.sortedFetchRequest())
        let connectionCount = try! directory.viewContext.count(for: ZMConnection.sortedFetchRequest())
        let userClientCount = try! directory.viewContext.count(for: UserClient.sortedFetchRequest())

        let userFetchRequest = ZMUser.sortedFetchRequest()
        userFetchRequest.resultType = .dictionaryResultType
        userFetchRequest.propertiesToFetch = self.userPropertiesToFetch
        let userDictionaries = directory.viewContext.executeFetchRequestOrAssert(userFetchRequest)

        // THEN
        XCTAssertEqual(conversationCount, 3)
        XCTAssertEqual(messageCount, 17)
        XCTAssertEqual(systemMessageCount, 1)
        XCTAssertEqual(connectionCount, 2)
        XCTAssertEqual(userClientCount, 3)

        XCTAssertNotNil(userDictionaries)
        XCTAssertEqual(userDictionaries.count, 3)
        XCTAssertEqual(userDictionaries as NSArray, DatabaseMigrationTests.userDictionaryFixture1_28 as NSArray)
    }

    func testThatItPerformsMigrationFrom_2_3_ToCurrentModelVersion() {

        // GIVEN
        self.createDatabaseWithOlderModelVersion(versionName: "2-3")

        // WHEN
        let directory = self.createStorageStackAndWaitForCompletion(userID: DatabaseMigrationTests.testUUID)

        // THEN
        let conversationCount = try! directory.viewContext.count(for: ZMConversation.sortedFetchRequest())
        let messageCount = try! directory.viewContext.count(for: ZMClientMessage.sortedFetchRequest())
        let systemMessageCount = try! directory.viewContext.count(for: ZMSystemMessage.sortedFetchRequest())
        let connectionCount = try! directory.viewContext.count(for: ZMConnection.sortedFetchRequest())
        let userClientCount = try! directory.viewContext.count(for: UserClient.sortedFetchRequest())

        let userFetchRequest = ZMUser.sortedFetchRequest()
        userFetchRequest.resultType = .dictionaryResultType
        userFetchRequest.propertiesToFetch = self.userPropertiesToFetch
        let userDictionaries = directory.viewContext.executeFetchRequestOrAssert(userFetchRequest)

        // THEN
        XCTAssertEqual(conversationCount, 2)
        XCTAssertEqual(messageCount, 5)
        XCTAssertEqual(systemMessageCount, 0)
        XCTAssertEqual(connectionCount, 2)
        XCTAssertEqual(userClientCount, 8)

        XCTAssertNotNil(userDictionaries)
        XCTAssertEqual(userDictionaries.count, 3)
        XCTAssertEqual(userDictionaries as NSArray, DatabaseMigrationTests.userDictionaryFixture2_3 as NSArray)
    }

    func testThatItPerformsMigrationFrom_2_4_ToCurrentModelVersion() {

        // GIVEN
        self.createDatabaseWithOlderModelVersion(versionName: "2-4")

        // WHEN
        let directory = self.createStorageStackAndWaitForCompletion(userID: DatabaseMigrationTests.testUUID)

        // THEN
        let conversationCount = try! directory.viewContext.count(for: ZMConversation.sortedFetchRequest())
        let messageCount = try! directory.viewContext.count(for: ZMClientMessage.sortedFetchRequest())
        let systemMessageCount = try! directory.viewContext.count(for: ZMSystemMessage.sortedFetchRequest())
        let connectionCount = try! directory.viewContext.count(for: ZMConnection.sortedFetchRequest())
        let userClientCount = try! directory.viewContext.count(for: UserClient.sortedFetchRequest())

        let userFetchRequest = ZMUser.sortedFetchRequest()
        userFetchRequest.resultType = .dictionaryResultType
        userFetchRequest.propertiesToFetch = self.userPropertiesToFetch
        let userDictionaries = directory.viewContext.executeFetchRequestOrAssert(userFetchRequest)

        // THEN
        XCTAssertEqual(conversationCount, 2)
        XCTAssertEqual(messageCount, 15)
        XCTAssertEqual(systemMessageCount, 4)
        XCTAssertEqual(connectionCount, 2)
        XCTAssertEqual(userClientCount, 9)

        XCTAssertNotNil(userDictionaries)
        XCTAssertEqual(userDictionaries.count, 3)
        XCTAssertEqual(userDictionaries as NSArray, DatabaseMigrationTests.userDictionaryFixture_2_45 as NSArray)
    }

    func testThatItPerformsMigrationFrom_2_5_ToCurrentModelVersion() {

        // GIVEN
        self.createDatabaseWithOlderModelVersion(versionName: "2-5")

        // WHEN
        let directory = self.createStorageStackAndWaitForCompletion(userID: DatabaseMigrationTests.testUUID)

        // THEN
        let conversationCount = try! directory.viewContext.count(for: ZMConversation.sortedFetchRequest())
        let messageCount = try! directory.viewContext.count(for: ZMClientMessage.sortedFetchRequest())
        let systemMessageCount = try! directory.viewContext.count(for: ZMSystemMessage.sortedFetchRequest())
        let connectionCount = try! directory.viewContext.count(for: ZMConnection.sortedFetchRequest())
        let userClientCount = try! directory.viewContext.count(for: UserClient.sortedFetchRequest())
        let assetClientMessagesCount = try! directory.viewContext.count(for: ZMAssetClientMessage.sortedFetchRequest())

        let userFetchRequest = ZMUser.sortedFetchRequest()
        userFetchRequest.resultType = .dictionaryResultType
        userFetchRequest.propertiesToFetch = self.userPropertiesToFetch
        let userDictionaries = directory.viewContext.executeFetchRequestOrAssert(userFetchRequest)

        // THEN
        XCTAssertEqual(assetClientMessagesCount, 5)
        XCTAssertEqual(conversationCount, 2)
        XCTAssertEqual(messageCount, 13)
        XCTAssertEqual(systemMessageCount, 1)
        XCTAssertEqual(connectionCount, 2)
        XCTAssertEqual(userClientCount, 10)

        XCTAssertNotNil(userDictionaries)
        XCTAssertEqual(userDictionaries.count, 3)
        XCTAssertEqual(userDictionaries as NSArray, DatabaseMigrationTests.userDictionaryFixture_2_45 as NSArray)
    }

    func testThatItPerformsMigrationFrom_2_6_ToCurrentModelVersion() {

        // GIVEN
        self.createDatabaseWithOlderModelVersion(versionName: "2-6")

        // WHEN
        let directory = self.createStorageStackAndWaitForCompletion(userID: DatabaseMigrationTests.testUUID)

        // THEN
        let conversationCount = try! directory.viewContext.count(for: ZMConversation.sortedFetchRequest())
        let messageCount = try! directory.viewContext.count(for: ZMClientMessage.sortedFetchRequest())
        let systemMessageCount = try! directory.viewContext.count(for: ZMSystemMessage.sortedFetchRequest())
        let connectionCount = try! directory.viewContext.count(for: ZMConnection.sortedFetchRequest())
        let userClientCount = try! directory.viewContext.count(for: UserClient.sortedFetchRequest())
        let assetClientMessagesCount = try! directory.viewContext.count(for: ZMAssetClientMessage.sortedFetchRequest())

        let userFetchRequest = ZMUser.sortedFetchRequest()
        userFetchRequest.resultType = .dictionaryResultType
        userFetchRequest.propertiesToFetch = self.userPropertiesToFetch
        let userDictionaries = directory.viewContext.executeFetchRequestOrAssert(userFetchRequest)

        // THEN
        XCTAssertEqual(assetClientMessagesCount, 0)
        XCTAssertEqual(conversationCount, 20)
        XCTAssertEqual(messageCount, 3)
        XCTAssertEqual(systemMessageCount, 21)
        XCTAssertEqual(connectionCount, 16)
        XCTAssertEqual(userClientCount, 12)

        XCTAssertNotNil(userDictionaries)
        XCTAssertEqual(userDictionaries.count, 22)
        XCTAssertEqual(Array(userDictionaries[0..<3]) as NSArray, DatabaseMigrationTests.userDictionaryFixture2_6 as NSArray)
    }

    func testThatItPerformsMigrationFrom_Between_2_7_and_2_21_4_ToCurrentModelVersion() {

        ["2-7", "2-8", "2-21-1", "2-21-2"].forEach { storeFile in
            // GIVEN
            self.createDatabaseWithOlderModelVersion(versionName: storeFile)

            // WHEN
            var directory: CoreDataStack! = self.createStorageStackAndWaitForCompletion(userID: DatabaseMigrationTests.testUUID)

            // THEN
            let conversationCount = try! directory.viewContext.count(for: ZMConversation.sortedFetchRequest())
            let messageCount = try! directory.viewContext.count(for: ZMClientMessage.sortedFetchRequest())
            let systemMessageCount = try! directory.viewContext.count(for: ZMSystemMessage.sortedFetchRequest())
            let connectionCount = try! directory.viewContext.count(for: ZMConnection.sortedFetchRequest())
            let userClientCount = try! directory.viewContext.count(for: UserClient.sortedFetchRequest())
            let assetClientMessagesCount = try! directory.viewContext.count(for: ZMAssetClientMessage.sortedFetchRequest())

            let userFetchRequest = ZMUser.sortedFetchRequest()
            userFetchRequest.resultType = .dictionaryResultType
            userFetchRequest.propertiesToFetch = self.userPropertiesToFetch
            let userDictionaries = directory.viewContext.executeFetchRequestOrAssert(userFetchRequest)

            // THEN
            XCTAssertEqual(assetClientMessagesCount, 0)
            XCTAssertEqual(conversationCount, 20)
            XCTAssertEqual(messageCount, 3)
            XCTAssertEqual(systemMessageCount, 21)
            XCTAssertEqual(connectionCount, 16)
            XCTAssertEqual(userClientCount, 12)

            XCTAssertNotNil(userDictionaries)
            XCTAssertEqual(userDictionaries.count, 22)
            XCTAssertEqual(Array(userDictionaries[0..<3]) as NSArray, DatabaseMigrationTests.userDictionaryFixture2_7 as NSArray)

            directory = nil // need to release
            self.clearStorageFolder()
        }
    }

    func testThatItPerformsMigrationFrom_Between_2_24_1_and_PreLast_ToCurrentModelVersion() {
        // NOTICE: When a new version of data model is created, please increase the last number of the array.
        let allVersions = ["2-24-1"] + [(25...31), (39...57), (59...101)].joined().map {
            "2-\($0)-0"
        }

        let modelVersion = CoreDataStack.loadMessagingModel().version
        let fixtureVersion = String(databaseFixtureFileName(for: modelVersion).dropFirst("store".count))

        // Check that we have current version fixture file
        guard databaseFixtureURL(version: modelVersion) != nil else {
            let versionsWithoutCurrent = allVersions.filter { $0 != fixtureVersion }
            createDatabaseWithOlderModelVersion(versionName: versionsWithoutCurrent.last!)
            let directory = createStorageStackAndWaitForCompletion(userID: DatabaseMigrationTests.testUUID)
            let currentDatabaseURL = directory.syncContext.persistentStoreCoordinator!.persistentStores.last!.url!

            XCTFail("\nMissing current version database file: `store\(fixtureVersion).wiredatabase`. \n\n" +
                    "**HOW TO FIX THIS** \n" +
                    "- Run the test, until you hit the assertion\n" +
                    "- **WHILE THE TEST IS PAUSED** on the assertion, do the following:\n" +
                    "- open the the folder in Finder by typing this command in your terminal. IT WILL NOT WORK IF THE TEST IS NOT PAUSED!!!.\n" +
                    "\t cp \"\(currentDatabaseURL.path)\" ~/Desktop/store\(fixtureVersion).wiredatabase\n\n" +
                    "- The command will copy a file on your desktop called `store\(fixtureVersion).wiredatabase`\n" +
                    "- Copy it to test bundle if this project in `WireDataModel/Test/Resources` with the other stores\n\n")
            assert(false)
        }

        guard allVersions.contains(fixtureVersion) else {
            return XCTFail("Current model version '\(fixtureVersion)' is not added to allVersions array. \n" +
                "Please add it to the array above, so that we are sure it's there when we bump to the next version\n" +
                "and we don't forget to test the migration from that version")
        }

        allVersions.forEach { storeFile in
            // GIVEN
            self.createDatabaseWithOlderModelVersion(versionName: storeFile)

            // WHEN
            var directory: CoreDataStack! = self.createStorageStackAndWaitForCompletion(userID: DatabaseMigrationTests.testUUID)

            // THEN
            let conversationCount = try! directory.viewContext.count(for: ZMConversation.sortedFetchRequest())
            let messageCount = try! directory.viewContext.count(for: ZMClientMessage.sortedFetchRequest())
            let systemMessageCount = try! directory.viewContext.count(for: ZMSystemMessage.sortedFetchRequest())
            let connectionCount = try! directory.viewContext.count(for: ZMConnection.sortedFetchRequest())
            let userClientCount = try! directory.viewContext.count(for: UserClient.sortedFetchRequest())
            let assetClientMessagesCount = try! directory.viewContext.count(for: ZMAssetClientMessage.sortedFetchRequest())
            let messages = directory.viewContext.executeFetchRequestOrAssert(ZMMessage.sortedFetchRequest()) as! [ZMMessage]
            let users = directory.viewContext.fetchOrAssert(request: NSFetchRequest<ZMUser>(entityName: ZMUser.entityName()))

            let userFetchRequest = ZMUser.sortedFetchRequest()
            userFetchRequest.resultType = .dictionaryResultType
            userFetchRequest.propertiesToFetch = self.userPropertiesToFetch
            let userDictionaries = directory.viewContext.executeFetchRequestOrAssert(userFetchRequest)

            // THEN
            XCTAssertEqual(assetClientMessagesCount, 0)
            XCTAssertEqual(conversationCount, 20)
            XCTAssertEqual(messageCount, 3)
            XCTAssertEqual(systemMessageCount, 21)
            XCTAssertEqual(connectionCount, 16)
            XCTAssertEqual(userClientCount, 12)

            // TODO: check still needed after XCode 11
            /*
            if storeFile == "2-53-0" {
                let silencedConversations = ((directory.uiContext.executeFetchRequestOrAssert(ZMConversation.sortedFetchRequest()!)) as! [ZMConversation]).filter { conversation in
                    return conversation.mutedStatus != 0
                }

                XCTAssertEqual(silencedConversations.count, 1)
            }*/

            XCTAssertNotNil(userDictionaries)
            XCTAssertEqual(userDictionaries.count, 22)
            XCTAssertEqual(Array(userDictionaries[0..<3]) as NSArray, DatabaseMigrationTests.userDictionaryFixture2_25_1 as NSArray)
            users.forEach({
                XCTAssertFalse($0.isAccountDeleted)
            })

            XCTAssertGreaterThan(messages.count, 0)
            messages.forEach {
                XCTAssertNil($0.normalizedText)
            }

            directory = nil // need to release
            self.clearStorageFolder()
        }
    }

    func testThatTheVersionIdentifiersMatchModelNameAndDoNotDuplicate() throws {
        // given
        guard let source = Bundle(for: ZMMessage.self).url(forResource: "zmessaging", withExtension: "momd") else {
            fatalError("missing resource")
        }
        let fm = FileManager.default

        let excludedModels = Set(["zmessaging.mom", "zmessaging2.9.mom", "zmessaging2.10.mom", "zmessaging2.11.mom"])

        let regex = try NSRegularExpression(pattern: "[0-9\\.]+[0-9]+")

        var processedVersions = Set<String>()

        try fm.contentsOfDirectory(atPath: source.path).filter { URL(fileURLWithPath: $0).pathExtension == "mom" } .forEach { modelFileName in

            let nameMatches = regex.matches(in: modelFileName, range: NSRange(modelFileName.startIndex..., in: modelFileName)).map {
                String(modelFileName[Range($0.range, in: modelFileName)!])
            }

            if excludedModels.contains(modelFileName) { // first version
                return
            }

            guard let version = nameMatches.first else {
                fatal("Wrong name format: \(modelFileName)")
            }

            XCTAssertFalse(processedVersions.contains(version))

            let store = NSManagedObjectModel(contentsOf: source.appendingPathComponent(modelFileName))!
            // then
            XCTAssertTrue(store.versionIdentifiers.contains(version))
            processedVersions.insert(version)
        }
    }
}

// MARK: - Helpers
extension DatabaseMigrationTests {

    static let testUUID: UUID = UUID()

    var userPropertiesToFetch: [String] {
        return [
                 "accentColorValue",
                 "emailAddress",
                 "modifiedKeys",
                 "name",
                 "normalizedEmailAddress",
                 "normalizedName",
                 "handle"
        ]
    }

    func createDatabaseWithOlderModelVersion(versionName: String, file: StaticString = #file, line: UInt = #line) {
        let storeFile = CoreDataStack.accountDataFolder(accountIdentifier: DatabaseMigrationTests.testUUID, applicationContainer: self.applicationContainer).appendingPersistentStoreLocation()
        try! FileManager.default.createDirectory(at: storeFile.deletingLastPathComponent(), withIntermediateDirectories: true)

        // copy old version database into the expected location
        guard let source = databaseFixtureURL(version: versionName, file: file, line: line) else {
            return
        }
        try! FileManager.default.copyItem(at: source, to: storeFile)
    }

    // The naming scheme is slightly different for fixture files
    func databaseFixtureFileName(for version: String) -> String {
        let fixedVersion = version.replacingOccurrences(of: ".", with: "-")
        let name = "store" + fixedVersion
        return name
    }

    func databaseFixtureURL(version: String, file: StaticString = #file, line: UInt = #line) -> URL? {
        let name = databaseFixtureFileName(for: version)
        guard let source = Bundle(for: type(of: self)).url(forResource: name, withExtension: "wiredatabase") else {
            XCTFail("Could not find \(name).wiredatabase in test bundle", file: file, line: line)
            return nil
        }
        return source
    }
}

// MARK: - Fixtures
extension DatabaseMigrationTests {

    static let userDictionaryFixture1_25 = [
        [
            "accentColorValue": 1,
            "emailAddress": "hello@example.com",
            "name": "awesome test user",
            "normalizedEmailAddress": "hello@example.com",
            "normalizedName": "awesome test user"
            ],
        [
            "accentColorValue": 1,
            "emailAddress": "censored@example.com",
            "name": "Bruno",
            "normalizedEmailAddress": "censored@example.com",
            "normalizedName": "bruno"
        ],
        [
            "accentColorValue": 6,
            "name": "Florian",
            "normalizedName": "florian"
        ],
        [
            "accentColorValue": 4,
            "name": "Heinzelmann",
            "normalizedName": "heinzelmann"
        ],
        [
            "accentColorValue": 3,
            "emailAddress": "migrationtest@example.com",
            "name": "MIGRATION TEST",
            "normalizedEmailAddress": "migrationtest@example.com",
            "normalizedName": "migration test"
        ],
        [
            "accentColorValue": 3,
            "emailAddress": "welcome+23@example.com",
            "name": "Otto the Bot",
            "normalizedEmailAddress": "welcome+23@example.com",
            "normalizedName": "otto the bot"
            ],
        [
            "accentColorValue": 6,
            "name": "Pierre-Joris",
            "normalizedName": "pierrejoris"
        ]
    ]

    static let userDictionaryFixture1_27 = [
        [
            "accentColorValue": (1),
            "emailAddress": "email@example.com",
            "name": "Bruno",
            "normalizedEmailAddress": "email@example.com",
            "normalizedName": "bruno"
            ],
        [
            "accentColorValue": (6),
            "emailAddress": "secret@example.com",
            "name": "Florian",
            "normalizedEmailAddress": "secret@example.com",
            "normalizedName": "florian"
            ],
        [
            "accentColorValue": (4),
            "emailAddress": "hidden@example.com",
            "name": "Heinzelmann",
            "normalizedEmailAddress": "hidden@example.com",
            "normalizedName": "heinzelmann"
            ],
        [
            "accentColorValue": (1),
            "emailAddress": "censored@example.com",
            "name": "It is me",
            "normalizedEmailAddress": "censored@example.com",
            "normalizedName": "it is me"
            ],
        [
            "accentColorValue": (3),
            "emailAddress": "welcome+23@example.com",
            "name": "Otto the Bot",
            "normalizedEmailAddress": "welcome+23@example.com",
            "normalizedName": "otto the bot"
            ],
        [
            "accentColorValue": (3),
            "name": "Pierre-Joris",
            "normalizedName": "pierrejoris"
            ],
        [
            "accentColorValue": (3),
            "emailAddress": "secret2@example.com",
            "name": "Test User",
            "normalizedEmailAddress": "secret2@example.com",
            "normalizedName": "test user"
            ]
    ]

    static let userDictionaryFixture1_28 = [
        [
            "accentColorValue": 1,
            "emailAddress": "user1@example.com",
            "name": "user1",
            "normalizedEmailAddress": "user1@example.com",
            "normalizedName": "user1"
        ],
        [
            "accentColorValue": 6,
            "emailAddress": "user2@example.com",
            "name": "user2",
            "normalizedEmailAddress": "user2@example.com",
            "normalizedName": "user2"
        ],
        [
            "accentColorValue": 1,
            "emailAddress": "user3@example.com",
            "name": "user3",
            "normalizedEmailAddress": "user3@example.com",
            "normalizedName": "user3"
            ]
        ]

    static let userDictionaryFixture2_3 = [
        [
            "accentColorValue": 1,
            "emailAddress": "user1@example.com",
            "name": "Example User 1",
            "normalizedEmailAddress": "user1@example.com",
            "normalizedName": "example user 1"
        ],
        [
            "accentColorValue": 6,
            "name": "Example User 2",
            "normalizedName": "example user 2"
        ],
        [
            "accentColorValue": 3,
            "emailAddress": "user3@example.com",
            "name": "Example User 3",
            "normalizedEmailAddress": "user3@example.com",
            "normalizedName": "example user 3"
            ]
    ]

    static let userDictionaryFixture_2_45 = [
        [
            "accentColorValue": 4,
            "emailAddress": "user1@example.com",
            "name": "User 1",
            "normalizedEmailAddress": "user1@example.com",
            "normalizedName": "user 1"
        ],
        [
            "accentColorValue": 6,
            "name": "User 2",
            "normalizedName": "user 2"
        ],
        [
            "accentColorValue": 1,
            "emailAddress": "user3@example.com",
            "name": "User 3",
            "normalizedEmailAddress": "user3@example.com",
            "normalizedName": "user 3"
            ]
        ]

    static let userDictionaryFixture2_6 = [
        [
            "accentColorValue": 3,
            "name": "Andreas",
            "normalizedName": "Andreas"
        ],
        [
            "accentColorValue": 3,
            "emailAddress": "574@example.com",
            "name": "Chad",
            "normalizedEmailAddress": "574@example.com",
            "normalizedName": "Chad"
        ],
        [
            "accentColorValue": 5,
            "emailAddress": "183@example.com",
            "name": "Daniel",
            "normalizedEmailAddress": "183@example.com",
            "normalizedName": "Daniel"
            ]
        ]

    static let userDictionaryFixture2_7 = [
        [
            "accentColorValue": 3,
            "name": "Andreas",
            "normalizedName": "Andreas"
        ],
        [
            "accentColorValue": 3,
            "emailAddress": "574@example.com",
            "name": "Chad",
            "normalizedEmailAddress": "574@example.com",
            "normalizedName": "Chad"
        ],
        [
            "accentColorValue": 5,
            "emailAddress": "183@example.com",
            "name": "Daniel",
            "normalizedEmailAddress": "183@example.com",
            "normalizedName": "Daniel"
            ]
        ]

    static let userDictionaryFixture2_25_1 = [
        [
            "accentColorValue": 3,
            "name": "Andreas",
            "normalizedName": "Andreas",
            "handle": "andre"
        ],
        [
            "accentColorValue": 3,
            "emailAddress": "574@example.com",
            "name": "Chad",
            "normalizedEmailAddress": "574@example.com",
            "normalizedName": "Chad",
            "handle": "titus"
        ],
        [
            "accentColorValue": 5,
            "emailAddress": "183@example.com",
            "name": "Daniel",
            "normalizedEmailAddress": "183@example.com",
            "normalizedName": "Daniel"
            ]
        ]

}
