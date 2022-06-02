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

import WireTesting
import WireDataModel

@testable import WireRequestStrategy

public final class MockKVStore: NSObject, ZMSynchonizableKeyValueStore {

    var keysAndValues = [String: Any]()

    public func store(value: PersistableInMetadata?, key: String) {
        keysAndValues[key] = value
    }

    public func storedValue(key: String) -> Any? {
        return keysAndValues[key]
    }

    public func enqueueDelayedSave() {
        // no op
    }

}

class ZMLocalNotificationSetTests: MessagingTestBase {

    typealias ZMLocalNotification = WireRequestStrategy.ZMLocalNotification
    typealias ZMLocalNotificationSet = WireRequestStrategy.ZMLocalNotificationSet

    var sut: ZMLocalNotificationSet!
    var notificationCenter: UserNotificationCenterMock!
    var keyValueStore: MockKVStore!
    let archivingKey = "archivingKey"

    var sender: ZMUser!
    var conversation1: ZMConversation!
    var conversation2: ZMConversation!

    override func setUp() {
        super.setUp()
        keyValueStore = MockKVStore()
        sut = ZMLocalNotificationSet(archivingKey: archivingKey, keyValueStore: keyValueStore)

        notificationCenter = UserNotificationCenterMock()
        sut.notificationCenter = notificationCenter

        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.remoteIdentifier = UUID.create()
        sender = ZMUser.insertNewObject(in: self.uiMOC)
        sender.remoteIdentifier = UUID.create()
        conversation1 = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation1.remoteIdentifier = UUID.create()
        conversation2 = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation2.remoteIdentifier = UUID.create()
    }

    override func tearDown() {
        keyValueStore = nil
        sut = nil
        notificationCenter = nil
        sender = nil
        conversation1 = nil
        conversation2 = nil
        super.tearDown()
    }

    func createMessage(with text: String, in conversation: ZMConversation) -> ZMOTRMessage {
        let message = try! conversation.appendText(content: text) as! ZMOTRMessage
        message.sender = sender
        message.serverTimestamp = Date()
        return message
    }

    func testThatYouCanAddNAndRemoveNotifications() {

        // given
        let text = GenericMessage(content: WireProtos.Text(content: "Hello Hello"))
        let event = createUpdateEvent(UUID.create(), conversationID: conversation1.remoteIdentifier!, genericMessage: text, senderID: sender.remoteIdentifier!)
        let note = ZMLocalNotification(event: event, conversation: conversation1, managedObjectContext: self.uiMOC)

        // when
        sut.addObject(note!)

        // then
        XCTAssertEqual(sut.notifications.count, 1)

        // and when
        _ = sut.remove(note!)

        // then
        XCTAssertEqual(sut.notifications.count, 0)
    }

    func testThatItCancelsNotificationsOnlyForSpecificConversations() {

        // given
        let event1 = createUpdateEvent(UUID.create(), conversationID: conversation1.remoteIdentifier!, genericMessage: GenericMessage(content: WireProtos.Text(content: "Hello Hello")), senderID: sender.remoteIdentifier!)
        let note1 = ZMLocalNotification(event: event1, conversation: conversation1, managedObjectContext: self.uiMOC)

        let event2 = createUpdateEvent(UUID.create(), conversationID: conversation1.remoteIdentifier!, genericMessage: GenericMessage(content: WireProtos.Text(content: "Bye BYe")), senderID: sender.remoteIdentifier!)
        let note2 = ZMLocalNotification(event: event2, conversation: conversation2, managedObjectContext: self.uiMOC)

        // when
        sut.addObject(note1!)
        sut.addObject(note2!)
        sut.cancelNotifications(conversation1)

        // then
        XCTAssertFalse(sut.notifications.contains(note1!))
        XCTAssertTrue(notificationCenter.removedNotifications.contains(note1!.id.uuidString))

        XCTAssertTrue(sut.notifications.contains(note2!))
        XCTAssertFalse(notificationCenter.removedNotifications.contains(note2!.id.uuidString))
    }

    func testThatItPersistsNotifications() {

        // given
        let event = createUpdateEvent(UUID.create(), conversationID: conversation1.remoteIdentifier!, genericMessage: GenericMessage(content: WireProtos.Text(content: "Hello")), senderID: sender.remoteIdentifier!)
        let note = ZMLocalNotification(event: event, conversation: conversation1, managedObjectContext: self.uiMOC)
        sut.addObject(note!)

        // when recreate sut to release non-persisted objects
        sut = ZMLocalNotificationSet(archivingKey: archivingKey, keyValueStore: keyValueStore)

        // then
        XCTAssertTrue(sut.oldNotifications.contains(note!.userInfo!))
    }

    func testThatItResetsTheNotificationSetWhenCancellingAllNotifications() {

        // given
        let event = createUpdateEvent(UUID.create(), conversationID: conversation1.remoteIdentifier!, genericMessage: GenericMessage(content: WireProtos.Text(content: "Hello")), senderID: sender.remoteIdentifier!)
        let note = ZMLocalNotification(event: event, conversation: conversation1, managedObjectContext: self.uiMOC)
        sut.addObject(note!)

        // when
        sut.cancelAllNotifications()

        // then
        XCTAssertEqual(sut.notifications.count, 0)
    }

    func createUpdateEvent(_ nonce: UUID, conversationID: UUID, genericMessage: GenericMessage, senderID: UUID = UUID.create()) -> ZMUpdateEvent {
        let payload: [String: Any] = [
            "id": UUID.create().transportString(),
            "conversation": conversationID.transportString(),
            "from": senderID.transportString(),
            "time": Date().transportString(),
            "data": ["text": try? genericMessage.serializedData().base64String()],
            "type": "conversation.otr-message-add"
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nonce)!
    }
}
