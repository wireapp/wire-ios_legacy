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
import XCTest
import WireRequestStrategy
import WireDataModel

class MessageExpirationTimerTests: MessagingTestBase {

    var sut: MessageExpirationTimer!
    var localNotificationDispatcher: MockPushMessageHandler!

    override func setUp() {
        super.setUp()
        self.localNotificationDispatcher = MockPushMessageHandler()
        self.sut = MessageExpirationTimer(moc: self.uiMOC, entityNames: [ZMClientMessage.entityName(), ZMAssetClientMessage.entityName()], localNotificationDispatcher: self.localNotificationDispatcher)
    }

    override func tearDown() {
        self.sut.tearDown()
        self.sut = nil
        self.localNotificationDispatcher = nil
        super.tearDown()
    }
}

extension MessageExpirationTimerTests {

    func testThatItExpireAMessageImmediately() {
        // GIVEN
        let message = self.clientMessage(expirationTime: -2)
        let messageSet: Set<NSManagedObject> = [message]

        // WHEN
        self.sut.objectsDidChange(messageSet)

        // THEN
        self.checkExpiration(of: message)
    }

    func testThatItExpiresAMessageWhenItsTimeRunsOut() {
        // GIVEN
        let message = self.clientMessage(expirationTime: 0.1)
        let messageSet: Set<NSManagedObject> = [message]

        // WHEN
        self.sut.objectsDidChange(messageSet)
        self.waitForExpiration(of: message)

        // THEN
        self.checkExpiration(of: message)
    }

    func testThatItNotifiesTheLocalNotificaitonDispatcherWhenItsTimeRunsOut() {
        // GIVEN
        let message = self.clientMessage(expirationTime: 0.1)
        let messageSet: Set<NSManagedObject> = [message]

        // WHEN
        self.sut.objectsDidChange(messageSet)
        self.waitForExpiration(of: message)

        // THEN
        XCTAssertEqual(self.localNotificationDispatcher.failedToSend, [message])
    }

    func testThatItDoesNotExpireAMessageWhenDeliveredIsSetToTrue() {
        // GIVEN
        let message = self.clientMessage(expirationTime: 0.1)
        let messageSet: Set<NSManagedObject> = [message]
        message.delivered = true

        // WHEN
        self.sut.objectsDidChange(messageSet)
        self.spinMainQueue(withTimeout: 0.4)

        // THEN
        XCTAssertFalse(message.isExpired)
    }

    func testThatItExpiresAMessageWhenDeliveredIsNotTrue() {
        // GIVEN
        let message = self.clientMessage(expirationTime: 0.1)
        let messageSet: Set<NSManagedObject> = [message]
        message.delivered = false

        // WHEN
        self.sut.objectsDidChange(messageSet)
        self.spinMainQueue(withTimeout: 0.4)

        // THEN
        self.checkExpiration(of: message)
    }

    func testThatItDoesNotExpireAMessageForWhichTheTimerWasStopped() {
        // GIVEN
        let message = self.clientMessage(expirationTime: 0.2)
        let messageSet: Set<NSManagedObject> = [message]
        self.sut.objectsDidChange(messageSet)

        // WHEN
        self.sut.stop(for: message)
        self.spinMainQueue(withTimeout: 0.4)

        // THEN
        XCTAssertNotNil(message.expirationDate)
        XCTAssertFalse(message.isExpired)
    }

    func testThatItDoesNotExpireAMessageThatHasNoExpirationDate() {
        // GIVEN
        let message = self.clientMessage(expirationTime: 0.1)
        let messageSet: Set<NSManagedObject> = [message]
        message.removeExpirationDate()

        // WHEN
        self.sut.objectsDidChange(messageSet)
        self.spinMainQueue(withTimeout: 0.4)

        // THEN
        XCTAssertNil(message.expirationDate)
        XCTAssertFalse(message.isExpired)
    }

    func testThatItStartsTimerForStoredMessagesOnFirstRequest() {
        // GIVEN
        let message = self.clientMessage(expirationTime: 0.1)

        // WHEN
        ZMChangeTrackerBootstrap.bootStrapChangeTrackers([self.sut!], on: self.uiMOC)
        self.waitForExpiration(of: message)

        // THEN
        self.checkExpiration(of: message)
    }

    func testThatItDoesNotHaveMessageTimersRunningWhenThereIsNoMessage() {
        XCTAssertFalse(self.sut.hasMessageTimersRunning)
    }

    func testThatItDoesNotHaveMessageTimersRunningWhenThereIsNoMessageBecauseTheyAreExpired() {
        // GIVEN
        let message = self.clientMessage(expirationTime: -2)
        let messageSet: Set<NSManagedObject> = [message]

        // WHEN
        self.sut.objectsDidChange(messageSet)
        self.waitForExpiration(of: message)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertFalse(self.sut.hasMessageTimersRunning)
    }

    func testThatItHasMessageTimersRunningWhenThereIsAMessage() {
        // GIVEN
        let message = self.clientMessage(expirationTime: 0.5)
        let messageSet: Set<NSManagedObject> = [message]

        // WHEN
        self.sut.objectsDidChange(messageSet)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertTrue(self.sut.hasMessageTimersRunning)
        self.waitForExpiration(of: message)
    }
}

// MARK: - Slow sync
extension MessageExpirationTimerTests {

    func testThatItReturnsCorrectFetchRequest() {
        // WHEN
        let request = self.sut.fetchRequestForTrackedObjects()

        // THEN
        let expected = ZMMessage.sortedFetchRequest(with: ZMMessage.predicateForMessagesThatWillExpire())
        XCTAssertEqual(request, expected)
    }

    func testThatItAddsObjectsThatNeedProcessing() {
        // GIVEN
        let message = self.clientMessage(expirationTime: 0.4)
        let anotherMessage = self.clientMessage(expirationTime: 0.4)

        XCTAssertFalse(self.sut.hasMessageTimersRunning)

        // WHEN
        let messageAndAnotherMessageSet: Set<NSManagedObject> = [message, anotherMessage]
        self.sut.addTrackedObjects(messageAndAnotherMessageSet)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertTrue(self.sut.hasMessageTimersRunning)
        XCTAssertEqual(self.sut.runningTimersCount, 2)
    }
}

// MARK: - Helpers
extension MessageExpirationTimerTests {

    /// Creates a message with expiration time
    fileprivate func clientMessage(expirationTime: TimeInterval) -> ZMClientMessage {
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        ZMMessage.setDefaultExpirationTime(expirationTime)
        message.setExpirationDate()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        ZMMessage.resetDefaultExpirationTime()
        return message
    }

    /// Checks that the message is expired. Asserts if not.
    fileprivate func checkExpiration(of message: ZMMessage, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
        XCTAssertFalse(message.hasChanges, file: file, line: line)
        XCTAssertNil(message.expirationDate, file: file, line: line)
        XCTAssertTrue(message.isExpired, file: file, line: line)
    }

    /// Wait for a message to expire. Asserts if it doesn't.
    fileprivate func waitForExpiration(of message: ZMMessage, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(self.waitOnMainLoop(until: { return message.isExpired }, timeout: 2), file: file, line: line)
    }
}
