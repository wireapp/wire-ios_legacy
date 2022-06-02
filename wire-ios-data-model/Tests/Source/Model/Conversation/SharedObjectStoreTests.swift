//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@testable import WireDataModel

fileprivate extension Notification {

    init(inserted: [NSManagedObject] = [], updated: [NSManagedObject] = [], deleted: [NSManagedObject] = []) {
        self.init(name: .NSManagedObjectContextDidSave, userInfo: [
            NSInsertedObjectsKey: Set<NSManagedObject>(inserted),
            NSUpdatedObjectsKey: Set<NSManagedObject>(updated),
            NSDeletedObjectsKey: Set<NSManagedObject>(deleted)
        ])
    }

}

class ContextDidSaveNotificationPersistenceTests: BaseZMMessageTests {

    var sut: ContextDidSaveNotificationPersistence!

    override func setUp() {
        super.setUp()
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        sut = ContextDidSaveNotificationPersistence(accountContainer: url)
    }

    override func tearDown() {
        sut.clear()
        sut = nil
        super.tearDown()
    }

    func testThatItCanStoreAndReadAChangeNotification() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let uri = conversation.objectID.uriRepresentation()
        XCTAssertNotNil(uri)

        // When
        XCTAssertTrue(sut.add(.init(inserted: [conversation])))

        // Then
        let expected = [NSInsertedObjectsKey: [uri] as AnyObject] as [AnyHashable: AnyObject]
        guard sut.storedNotifications.count == 1 else { return XCTFail("Wrong amount of notifications") }

        for (key, value) in sut.storedNotifications.first! {
            XCTAssertEqual(value as? Set<NSManagedObject>, expected[key] as? Set<NSManagedObject>)
        }
    }

    func testThatItCanClearTheStoredNotifications() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        XCTAssertNotNil(conversation.objectID.uriRepresentation())
        XCTAssertTrue(sut.add(.init(inserted: [conversation])))
        XCTAssertEqual(sut.storedNotifications.count, 1)

        // When
        sut.clear()

        // Then
        XCTAssertEqual(sut.storedNotifications.count, 0)

    }

    func testThatItCanSaveMultipleNotifications() {
        // Given
        let firstConversation = ZMConversation.insertNewObject(in: uiMOC)
        let firstURI = firstConversation.objectID.uriRepresentation()

        let secondConversation = ZMConversation.insertNewObject(in: uiMOC)
        let secondURI = secondConversation.objectID.uriRepresentation()

        // When
        XCTAssertTrue(sut.add(.init(inserted: [firstConversation], deleted: [firstConversation])))

        // Then
        XCTAssertEqual(sut.storedNotifications.count, 1)

        // When
        XCTAssertTrue(sut.add(.init(updated: [secondConversation])))

        // Then
        XCTAssertEqual(sut.storedNotifications.count, 2)

        // Then
        let firstExpected = [
            NSInsertedObjectsKey: [firstURI] as AnyObject,
            NSDeletedObjectsKey: [secondURI] as AnyObject
            ] as [AnyHashable: AnyObject]

        let secondExpected = [
            NSUpdatedObjectsKey: [secondURI] as AnyObject
            ] as [AnyHashable: AnyObject]

        guard sut.storedNotifications.count == 2 else { return XCTFail("Wrong amount of notifications") }

        for (key, value) in sut.storedNotifications.first! {
            XCTAssertEqual(value as? Set<NSManagedObject>, firstExpected[key] as? Set<NSManagedObject>)
        }

        for (key, value) in sut.storedNotifications.last! {
            XCTAssertEqual(value as? Set<NSManagedObject>, secondExpected[key] as? Set<NSManagedObject>)
        }
    }

}

class ShareExtensionAnalyticsPersistenceTests: BaseZMMessageTests {

    var sut: ShareExtensionAnalyticsPersistence!

    override func setUp() {
        super.setUp()
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        sut = ShareExtensionAnalyticsPersistence(accountContainer: url)
    }

    override func tearDown() {
        sut.clear()
        sut = nil
        super.tearDown()
    }

    func testThatItCanStoreAndReadAStorableTrackingEvent() {
        // Given
        let event = StorableTrackingEvent(name: "eventName", attributes: ["first": true])

        // When
        XCTAssertTrue(sut.add(event))

        // Then
        XCTAssertEqual(sut.storedTrackingEvents.count, 1)
        let actualEvent = sut.storedTrackingEvents.first
        XCTAssertEqual(event.name, actualEvent?.name)
        XCTAssertEqual(actualEvent?.attributes.keys.count, 2)
        XCTAssertNotNil(actualEvent?.attributes["timestamp"])
        XCTAssertEqual(actualEvent?.attributes["first"] as? Bool, true)
    }

    func testThatItCanClearTheStoredNotifications() {
        // Given
        let event = StorableTrackingEvent(name: "eventName", attributes: ["first": true])
        XCTAssertTrue(sut.add(event))
        XCTAssertEqual(sut.storedTrackingEvents.count, 1)

        // When
        sut.clear()

        // Then
        XCTAssertEqual(sut.storedTrackingEvents.count, 0)

    }

}

class ShareObjectStoreTests: ZMTBaseTest {
    var sut: SharedObjectStore<WireDataModel.SharedObjectTestClass>!

    override func setUp() {
        super.setUp()
        sut = createStore()
    }

    override func tearDown() {
        sut.clear()
        sut = nil
        super.tearDown()
    }

    func createStore() -> SharedObjectStore<WireDataModel.SharedObjectTestClass> {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return SharedObjectStore(accountContainer: url, fileName: "store")
    }

    func testThatItCanDecodeClassSavedBeforeProjectRename() {
        // Given

        // Module prefix before project rename
        NSKeyedArchiver.setClassName("ZMCDataModel.SharedObjectTestClass", for: WireDataModel.SharedObjectTestClass.self)
        let item = WireDataModel.SharedObjectTestClass()
        item.flag = true

        // When
        sut.store(item)
        sut = createStore()

        // Then
        let items = sut.load()
        XCTAssertEqual(items.first?.flag, item.flag)
    }

}
