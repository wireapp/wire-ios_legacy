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

import Foundation
@testable import WireDataModel

extension ObjectChangeInfo {

    func checkForExpectedChangeFields(userInfoKeys: Set<String>, expectedChangedFields: Set<String>, file: StaticString = #file, line: UInt = #line) {
        guard userInfoKeys.isSuperset(of: expectedChangedFields) else {
            return XCTFail("Expected change fields \(expectedChangedFields) not in userInfoKeys \(userInfoKeys). Please add them to the list.", file: file, line: line)
        }

        for key in userInfoKeys {
            guard let value = value(forKey: key) as? NSNumber else {
                return XCTFail("Can't find key or key is not boolean for '\(key)'", file: file, line: line)
            }
            if expectedChangedFields.contains(key) {
                XCTAssertTrue(value.boolValue, "\(key) was supposed to be true", file: file, line: line)
            } else {
                XCTAssertFalse(value.boolValue, "\(key) was supposed to be false", file: file, line: line)
            }
        }
    }
}

@objcMembers public class NotificationDispatcherTestBase: ZMBaseManagedObjectTest {

    var dispatcher: NotificationDispatcher! {
        return sut
    }
    var sut: NotificationDispatcher!
    var conversationObserver: ConversationObserver!
    var newUnreadMessageObserver: NewUnreadMessageObserver!
    var mergeNotifications = [Notification]()

    /// Holds a reference to the observer token, so that we don't release it during the test
    var token: Any?

    override public func setUp() {
        super.setUp()
        newUnreadMessageObserver = NewUnreadMessageObserver()
        conversationObserver = ConversationObserver()
        sut = NotificationDispatcher(managedObjectContext: uiMOC)
        NotificationCenter.default.addObserver(self, selector: #selector(NotificationDispatcherTestBase.contextDidMerge(_:)), name: Notification.Name.NSManagedObjectContextDidSave, object: syncMOC)
        mergeNotifications = []
    }

    override public func tearDown() {
        NotificationCenter.default.removeObserver(self)
        self.sut.tearDown()
        self.sut = nil
        self.conversationObserver = nil
        self.newUnreadMessageObserver = nil
        self.mergeNotifications = []
        self.token = nil
        super.tearDown()
    }

    public func contextDidMerge(_ note: Notification) {
        mergeNotifications.append(note)
    }

    public func mergeLastChanges() {
        let changedObjects =  mergeLastChangesWithoutNotifying()
        self.dispatcher.didMergeChanges(Set(changedObjects))
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

    }
    @discardableResult public func mergeLastChangesWithoutNotifying() -> [NSManagedObjectID] {
        guard let change = mergeNotifications.last else { return [] }
        let changedObjects = (change.userInfo?[NSUpdatedObjectsKey] as? Set<ZMManagedObject>)?.map {$0.objectID} ?? []
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.uiMOC.mergeChanges(fromContextDidSave: change)
        mergeNotifications = []
        return changedObjects
    }

}

class NotificationDispatcherTests: NotificationDispatcherTestBase {

    class Wrapper {
        let dispatcher: NotificationDispatcher

        init(managedObjectContext: NSManagedObjectContext) {
            self.dispatcher = NotificationDispatcher(managedObjectContext: managedObjectContext)
        }
        deinit {
            dispatcher.tearDown()
        }
    }

    func testThatDeallocates() {
        // when
        var wrapper: Wrapper? = Wrapper(managedObjectContext: uiMOC)
        weak var center = wrapper!.dispatcher
        XCTAssertNotNil(center)

        // when
        wrapper = nil

        // then
        XCTAssertNil(center)
    }

    func testThatItNotifiesAboutChanges() {

        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        withExtendedLifetime(ConversationChangeInfo.add(observer: conversationObserver, for: conversation)) { () -> Void in

            // when
            conversation.userDefinedName = "foo"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(conversationObserver.notifications.count, 1)
            guard let changeInfo = conversationObserver.notifications.first else {
                return XCTFail()
            }
            XCTAssertTrue(changeInfo.nameChanged)
        }
    }

    func testThatItNotifiesAboutUnreadMessages() {

        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastReadServerTimeStamp = Date()
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        withExtendedLifetime(NewUnreadMessagesChangeInfo.add(observer: newUnreadMessageObserver, managedObjectContext: uiMOC)) { () -> Void in

            // when
            let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
            message.visibleInConversation = conversation
            message.serverTimestamp = Date()
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(newUnreadMessageObserver.notifications.first?.messages.count, 1)
        }
    }

    func testThatItDoesntNotifyAboutOldUnreadMessages() {

        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastReadServerTimeStamp = Date()
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.visibleInConversation = conversation
        message.serverTimestamp = Date()
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        withExtendedLifetime(NewUnreadMessagesChangeInfo.add(observer: newUnreadMessageObserver, managedObjectContext: uiMOC)) { () -> Void in

            // when
            let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
            message.visibleInConversation = conversation
            message.serverTimestamp = Date()
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(newUnreadMessageObserver.notifications.first?.messages.count, 1)
        }
    }

    func testThatItNotifiesAboutChangesInOtherObjects() {

        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        withExtendedLifetime(ConversationChangeInfo.add(observer: conversationObserver, for: conversation)) { () -> Void in
            // when
            user.name = "Brett"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(conversationObserver.notifications.count, 1)
            guard let changeInfo = conversationObserver.notifications.first else {
                XCTFail()
                return
            }
            XCTAssertTrue(changeInfo.nameChanged)
        }
    }

    func testThatItCanCalculateChangesWhenObjectIsFaulted() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        uiMOC.refresh(user, mergeChanges: true)
        XCTAssertTrue(user.isFault)
        XCTAssertEqual(user.name, "foo")
        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, in: self.uiMOC)) { () -> Void in

            // when
            syncMOC.performGroupedBlockAndWait {
                let syncUser = self.syncMOC.object(with: user.objectID) as! ZMUser
                syncUser.name = "bar"
                self.syncMOC.saveOrRollback()
            }
            mergeLastChanges()

            // then
            XCTAssertEqual(user.name, "bar")
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }

    func testThatItNotifiesAboutChangeWhenObjectIsFaultedAndDisappears() {
        // given
        var user: ZMUser? = ZMUser.insertNewObject(in: uiMOC)
        user?.name = "foo"
        uiMOC.saveOrRollback()
        let objectID = user!.objectID
        uiMOC.refresh(user!, mergeChanges: true)
        XCTAssertTrue(user!.isFault)
        let observer = UserObserver()

        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user!, in: self.uiMOC)) { () -> Void in

            // when
            user = nil
            syncMOC.performGroupedBlockAndWait {
                let syncUser = self.syncMOC.object(with: objectID) as! ZMUser
                syncUser.name = "bar"
                self.syncMOC.saveOrRollback()
            }
            mergeLastChanges()

            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }

    func testThatItProcessesNonCoreDataChangeNotifications() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()

        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, in: self.uiMOC)) { () -> Void in

            // when
            NotificationDispatcher.notifyNonCoreDataChanges(objectID: user.objectID, changedKeys: ["name"], uiContext: uiMOC)
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }

    func testThatItOnlySendsNotificationsWhenDidMergeIsCalled() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()

        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, in: self.uiMOC)) { () -> Void in

            // when
            user.name = "bar"
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            // then
            XCTAssertEqual(observer.notifications.count, 0)

            // and when
            sut.didMergeChanges(Set(arrayLiteral: user.objectID))

            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }

    func testThatItOnlySendsNotificationsWhenDidSaveIsCalled() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()

        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, in: self.uiMOC)) { () -> Void in

            // when
            user.name = "bar"
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            // then
            XCTAssertEqual(observer.notifications.count, 0)

            // and when
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }

    // MARK: Background behaviour

    func testThatItDoesNotProcessChangesWhenDisabled() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()

        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, in: self.uiMOC)) { () -> Void in

            // when
            sut.isEnabled = false
            user.name = "bar"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(observer.notifications.count, 0)
        }
    }

    func testThatItProcessesChangesAfterBeingEnabled() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        sut.isEnabled = false

        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, in: self.uiMOC)) { () -> Void in

            // when
            sut.isEnabled = true
            user.name = "bar"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }

    func testThatItDoesNotProcessChangesWhenAppEntersBackground() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()

        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, in: self.uiMOC)) { () -> Void in

            // when
            sut.applicationDidEnterBackground()
            user.name = "bar"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(observer.notifications.count, 0)
        }
    }

    func testThatItProcessesChangesAfterAppEnteredBackgroundAndNowEntersForegroundAgain() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        sut.applicationDidEnterBackground()

        let observer = UserObserver()
        withExtendedLifetime(UserChangeInfo.add(observer: observer, for: user, in: self.uiMOC)) { () -> Void in

            // when
            sut.applicationWillEnterForeground()
            user.name = "bar"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // then
            XCTAssertEqual(observer.notifications.count, 1)
            if let note = observer.notifications.first {
                XCTAssertTrue(note.nameChanged)
            }
        }
    }

    // MARK: ChangeInfoConsumer
    class ChangeConsumer: NSObject, ChangeInfoConsumer {
        var changes: [ClassIdentifier: [ObjectChangeInfo]]?
        var didCallStopObserving = false
        var didCallStartObserving = false

        func objectsDidChange(changes: [ClassIdentifier: [ObjectChangeInfo]]) {
            self.changes = changes
        }

        func stopObserving() {
            didCallStopObserving = true
        }

        func startObserving() {
            didCallStartObserving = true
        }
    }

    func testThatItNotifiesChangeInfoConsumersWhenObservationStops_enteringBackground() {
        // given
        let consumer = ChangeConsumer()
        sut.addChangeInfoConsumer(consumer)
        XCTAssertFalse(consumer.didCallStopObserving)

        // when
        sut.applicationDidEnterBackground()

        // then
        XCTAssertTrue(consumer.didCallStopObserving)
    }

    func testThatItNotifiesChangeInfoConsumersWhenObservationStarts_enteringForeground() {
        // given
        let consumer = ChangeConsumer()
        sut.applicationDidEnterBackground()
        sut.addChangeInfoConsumer(consumer)
        XCTAssertFalse(consumer.didCallStartObserving)

        // when
        sut.applicationWillEnterForeground()

        // then
        XCTAssertTrue(consumer.didCallStartObserving)
    }

    func testThatItNotifiesChangeInfoConsumersWhenObservationStops_disabled() {
        // given
        let consumer = ChangeConsumer()
        sut.addChangeInfoConsumer(consumer)
        XCTAssertFalse(consumer.didCallStopObserving)

        // when
        sut.isEnabled = false

        // then
        XCTAssertTrue(consumer.didCallStopObserving)
    }

    func testThatItNotifiesChangeInfoConsumersWhenObservationStarts_enabled() {
        // given
        let consumer = ChangeConsumer()
        sut.isEnabled = false
        sut.addChangeInfoConsumer(consumer)
        XCTAssertFalse(consumer.didCallStartObserving)

        // when
        sut.isEnabled = true

        // then
        XCTAssertTrue(consumer.didCallStartObserving)
    }

    func testThatItNotifiesChangeInfoConsumersWhenObjectChanged() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()

        let consumer = ChangeConsumer()
        sut.addChangeInfoConsumer(consumer)
        XCTAssertNil(consumer.changes)

        // when
        user.name = "bar"
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNotNil(consumer.changes)
        if let changes = consumer.changes {
            XCTAssertEqual(changes.count, 1)
            guard let userChanges = changes[ZMUser.entityName()] as? [UserChangeInfo],
                  let change = userChanges.first
            else { return XCTFail()}
            XCTAssertTrue(change.nameChanged)
        }
    }

    func testThatItProcessesChangedObjectIDsFromMerge() {
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
        withExtendedLifetime(ConversationChangeInfo.add(observer: conversationObserver, for: conv)) { () -> Void in

            syncMOC.performGroupedBlockAndWait {
                let syncConv = try! self.syncMOC.existingObject(with: conv.objectID) as! ZMConversation
                syncConv.userDefinedName = "foo"
                self.syncMOC.saveOrRollback()
            }
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            self.uiMOC.mergeChanges(fromContextDidSave: mergeNotifications.last!)

            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertEqual(conversationObserver.notifications.count, 0)

            // when
            sut.didMergeChanges(Set(arrayLiteral: conv.objectID))

            // then
            XCTAssertEqual(conversationObserver.notifications.count, 1)
            guard let changeInfo = conversationObserver.notifications.first else {
                return XCTFail()
            }
            XCTAssertTrue(changeInfo.nameChanged)
        }
    }

    // MARK: - Operation Mode

    func testThatItCollectsMinimalChangesWhileInEconomicalMode() {
        // Given
        sut.operationMode = .economical

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        withExtendedLifetime(ConversationChangeInfo.add(observer: conversationObserver, for: conversation)) { () -> Void in
            // When the conversation changes
            conversation.userDefinedName = "foo"
            conversation.mutedMessageTypes = .mentionsAndReplies
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // Go back to normal mode to trigger notification.
            sut.operationMode = .normal

            // Then there is a notification with minimal changes.
            let changeInfos = conversationObserver.notifications
            XCTAssertEqual(changeInfos.count, 1)

            guard let changeInfo = changeInfos.first else { return XCTFail() }
            XCTAssertTrue(changeInfo.changedKeys.isEmpty)
            XCTAssertTrue(changeInfo.considerAllKeysChanged)
        }
    }

    func testThatItOnlyFiresANotificationWhenLeavingEconomicalMode() {
        // Given
        sut.operationMode = .economical

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        withExtendedLifetime(ConversationChangeInfo.add(observer: conversationObserver, for: conversation)) { () -> Void in
            // Make some changes
            conversation.userDefinedName = "foo"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            XCTAssertTrue(conversationObserver.notifications.isEmpty)

            // When
            sut.operationMode = .normal

            // Then
            let changeInfos = conversationObserver.notifications
            XCTAssertEqual(changeInfos.count, 1)
        }
    }

    func testThatItOperatesNormalWhenAfterReturningToNormalMode() {
        // Given
        sut.operationMode = .economical

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        withExtendedLifetime(ConversationChangeInfo.add(observer: conversationObserver, for: conversation)) { () -> Void in
            // Make some changes
            conversation.userDefinedName = "foo"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // When
            sut.operationMode = .normal

            // Notification for economical mode is fired.
            let changeInfos = conversationObserver.notifications
            XCTAssertEqual(changeInfos.count, 1)

            guard let changeInfo = changeInfos.first else { return XCTFail() }
            XCTAssertTrue(changeInfo.changedKeys.isEmpty)
            XCTAssertTrue(changeInfo.considerAllKeysChanged)

            conversationObserver.notifications.removeAll()

            // Make some more changes in normal mode.
            conversation.userDefinedName = "bar"
            uiMOC.saveOrRollback()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            // Then a normal change notification is received.
            let newChangeInfos = conversationObserver.notifications
            XCTAssertEqual(newChangeInfos.count, 1)

            guard let newChangeInfo = newChangeInfos.first else { return XCTFail() }
            XCTAssertEqual(newChangeInfo.changedKeys, [#keyPath(ZMConversation.displayName)])
            XCTAssertFalse(newChangeInfo.considerAllKeysChanged)
        }
    }

}
