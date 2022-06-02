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

import UserNotifications

@testable import WireSyncEngine

class LocalNotificationDispatcherCallingTests: DatabaseTest {

    var sut: LocalNotificationDispatcher!
    var notificationCenter: UserNotificationCenterMock!
    var sender: ZMUser!
    var conversation: ZMConversation!

    var scheduledRequests: [UNNotificationRequest] {
        return self.notificationCenter.scheduledRequests
    }

    override func setUp() {
        super.setUp()

        sut = LocalNotificationDispatcher(in: syncMOC)

        notificationCenter = UserNotificationCenterMock()
        sut.notificationCenter = notificationCenter
        sut.callingNotifications.notificationCenter = notificationCenter

        syncMOC.performGroupedBlockAndWait {
            let sender = ZMUser.insertNewObject(in: self.syncMOC)
            sender.name = "Callie"
            sender.remoteIdentifier = UUID()

            self.sender = sender

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .oneOnOne
            conversation.remoteIdentifier = UUID()
            conversation.addParticipantAndUpdateConversationState(user: sender, role: nil)

            self.conversation = conversation

            ZMUser.selfUser(in: self.syncMOC).remoteIdentifier = UUID()
        }
    }

    override func tearDown() {
        sut = nil
        notificationCenter = nil
        sender = nil
        conversation = nil
        super.tearDown()
    }

    func testThatMissedCallCreatesCallingNotification() {
        // when
        sut.processMissedCall(in: conversation, caller: sender)

        // then
        XCTAssertEqual(sut.callingNotifications.notifications.count, 1)
        XCTAssertEqual(scheduledRequests.count, 1)
    }

    func testThatIncomingCallCreatesCallingNotification() {
        // when
        sut.process(callState: .incoming(video: false, shouldRing: true, degraded: false), in: conversation, caller: sender)

        // then
        XCTAssertEqual(sut.callingNotifications.notifications.count, 1)
        XCTAssertEqual(scheduledRequests.count, 1)
    }

    func testThatIgnoredCallStatesDoesNotCreateCallingNotifications() {

        let ignoredCallStates: [CallState] = [.established, .answered(degraded: false), .outgoing(degraded: false), .none, .unknown]

        for ignoredCallState in ignoredCallStates {
            // when
            sut.process(callState: ignoredCallState, in: conversation, caller: sender)

            // then
            XCTAssertEqual(sut.callingNotifications.notifications.count, 0)
            XCTAssertEqual(scheduledRequests.count, 0)
        }
    }

    func testThatIncomingCallIsReplacedByCanceledCallNotification() {
        // given
        sut.process(callState: .incoming(video: false, shouldRing: true, degraded: false), in: conversation, caller: sender)
        XCTAssertEqual(sut.callingNotifications.notifications.count, 1)
        XCTAssertEqual(scheduledRequests.count, 1)

        let incomingCallNotificationID = scheduledRequests.first!.identifier

        // when
        sut.processMissedCall(in: conversation, caller: sender)

        // then
        XCTAssertEqual(sut.callingNotifications.notifications.count, 1)
        XCTAssertEqual(scheduledRequests.count, 2)
        XCTAssertEqual(notificationCenter.removedNotifications, Set([incomingCallNotificationID]))
    }

    func testThatIncomingCallIsClearedWhenCallIsAnsweredElsewhere() {
        // given
        sut.process(callState: .incoming(video: false, shouldRing: true, degraded: false), in: conversation, caller: sender)
        XCTAssertEqual(sut.callingNotifications.notifications.count, 1)
        XCTAssertEqual(scheduledRequests.count, 1)

        let incomingCallNotificationID = scheduledRequests.first!.identifier

        // when
        sut.process(callState: .terminating(reason: .anweredElsewhere), in: conversation, caller: sender)

        // then
        XCTAssertEqual(sut.callingNotifications.notifications.count, 0)
        XCTAssertEqual(scheduledRequests.count, 1)
        XCTAssertEqual(notificationCenter.removedNotifications, Set([incomingCallNotificationID]))
    }
}
