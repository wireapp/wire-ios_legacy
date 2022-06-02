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

@testable import WireSyncEngine

class MockTyping: WireSyncEngine.Typing {
    var didTearDown: Bool = false
    var typingUsers: [ZMConversation: Set<ZMUser>] = [:]
    var didSetTypingUsers: Bool = false

    override func tearDown() {
        didTearDown = true
        typingUsers = [:]
        super.tearDown()
    }

    override func setIsTyping(_ isTyping: Bool, for user: ZMUser!, in conversation: ZMConversation!) {
        didSetTypingUsers = true
        var newTypingUsers = typingUsers[conversation] ?? Set()
        if isTyping {
            newTypingUsers.insert(user)
        } else {
            newTypingUsers.remove(user)
        }
        typingUsers[conversation] = newTypingUsers
    }

    func isUserTyping(user: ZMUser, in conversation: ZMConversation) -> Bool {
        guard let users = typingUsers[conversation] else {return false}
        return users.contains(user)
    }
}

class MockClientRegistrationDelegate: NSObject, ClientRegistrationDelegate {
    var mockReadiness = true
    var clientIsReadyForRequests: Bool {
        return mockReadiness
    }

    public func didDetectCurrentClientDeletion() {}
}

enum TestTyping {
    case noDelay, delay, clearTranscoder, appendMessage
}

class TypingStrategyTests: MessagingTest {

    var sut: TypingStrategy!
    var originalTimeout: TimeInterval = 0.0
    var typing: MockTyping!
    var mockApplicationStatus: MockApplicationStatus!
    var conversationA: ZMConversation!
    var userA: ZMUser!

    override func setUp() {
        super.setUp()
        originalTimeout = MockTyping.defaultTimeout
        MockTyping.defaultTimeout = 3.0

        self.typing = MockTyping(uiContext: uiMOC, syncContext: syncMOC)
        self.mockApplicationStatus = MockApplicationStatus()
        self.mockApplicationStatus.mockSynchronizationState = .online

        self.sut = TypingStrategy(applicationStatus: mockApplicationStatus, syncContext: syncMOC, uiContext: uiMOC, typing: typing)

        syncMOC.performGroupedBlockAndWait {
            self.conversationA = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversationA.remoteIdentifier = UUID.create()
            self.userA = ZMUser.insertNewObject(in: self.syncMOC)
            self.userA.remoteIdentifier = UUID.create()
            XCTAssert(self.syncMOC.saveOrRollback())
        }
    }

    override func tearDown() {
        self.conversationA = nil
        self.userA = nil

        self.sut.tearDown()
        XCTAssertTrue(typing.didTearDown)
        self.typing = nil
        self.sut = nil

        MockTyping.defaultTimeout = originalTimeout
        super.tearDown()
    }

    func insertUIConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        uiMOC.saveOrRollback()
        return conversation
    }

    func simulateTyping() {
        typing.setIsTyping(true, for: userA, in: conversationA)
        XCTAssertTrue(typing.isUserTyping(user: userA, in: conversationA))
        typing.didSetTypingUsers = false
    }

    func typingEvent(isTyping: Bool) -> ZMUpdateEvent {
        let payload = ["conversation": conversationA.remoteIdentifier!.transportString(),
                       "data": ["status": isTyping ? "started" : "stopped"],
                       "from": userA.remoteIdentifier!.transportString(),
                       "time": Date().transportString(),
                       "type": "conversation.typing"
                       ] as [String: Any]
        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!
    }

    func memberLeaveEvent() -> ZMUpdateEvent {
        let payload = ["conversation": conversationA.remoteIdentifier!.transportString(),
                       "data": ["user_ids": [userA.remoteIdentifier!.transportString()]],
                       "from": userA.remoteIdentifier!.transportString(),
                       "time": Date().transportString(),
                       "type": "conversation.member-leave"
                       ] as [String: Any]
        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!
    }

    func isExpected(request: ZMTransportRequest?, for conversation: ZMConversation, isTyping: Bool) -> Bool {
        let expectedPath = "/conversations/\(conversation.remoteIdentifier!.transportString())/typing"
        let expectedPayload = ["status": isTyping ? "started" : "stopped"]

        if let request = request, (request.path == expectedPath) && (request.method == .methodPOST) {
            if let payload = request.payload as? [String: String] {
                XCTAssertEqual(payload, expectedPayload)
            } else {
                return false
            }
        } else {
            return false
        }
        return true
    }
}

extension TypingStrategyTests {

    func testThatItForwardsAStartedTypingEvent() {
        // given
        let event = typingEvent(isTyping: true)

        // when
        sut.processEvents([event], liveEvents: true, prefetchResult: nil)

        // then
        XCTAssertTrue(typing.isUserTyping(user: userA, in: conversationA))
    }

    func testThatItForwardsAStoppedTypingEvent() {
        // given
        let event = typingEvent(isTyping: false)
        simulateTyping()

        // when
        sut.processEvents([event], liveEvents: true, prefetchResult: nil)

        // then
        XCTAssertTrue(typing.didSetTypingUsers)
        XCTAssertFalse(typing.isUserTyping(user: userA, in: conversationA))
    }

    func testThatItDoesNotForwardsAnUnknownTypingEvent() {
        // given
        let payload = ["conversation": conversationA.remoteIdentifier!.transportString(),
                       "data": ["status": "foo"],
                       "from": userA.remoteIdentifier!.transportString(),
                       "time": Date().transportString(),
                       "type": "conversation.typing"
                       ] as [String: Any]
        let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!

        // when
        sut.processEvents([event], liveEvents: true, prefetchResult: nil)

        // then
        XCTAssertFalse(typing.didSetTypingUsers)
    }

    func testThatItForwardsOTRMessageAddEventsAndSetsIsTypingToNo() {
        // given

        // edit message is an allowed type that can fire a otr-message-add notification
        let message = GenericMessage(content: MessageEdit(replacingMessageID: .create(), text: Text(content: "demo")))
        let payload = payloadForOTRMessageAdd(with: message) as ZMTransportData
        let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!

        simulateTyping()

        // when
        sut.processEvents([event], liveEvents: true, prefetchResult: nil)

        // then
        XCTAssertTrue(typing.didSetTypingUsers)
        XCTAssertFalse(typing.isUserTyping(user: userA, in: conversationA))
    }

    func testThatDoesntForwardOTRMessageAddEventsForNonTextTypes() {
        // given
        // delete-message should not fire an Add Events notification
        let message = GenericMessage(content: MessageDelete(messageId: UUID.create()))
        tryToForwardOTRMessageWithoutReply(with: message)
    }

    func testThatDoesntForwardOTRMessageAddEventsForConfirmations() {

        // given
        // confirmations should not fire an Add Events notification
        let message = GenericMessage(content: Confirmation(messageId: UUID.create()))
        tryToForwardOTRMessageWithoutReply(with: message)
    }

    func tryToForwardOTRMessageWithoutReply(with message: GenericMessage) {
        let payload = payloadForOTRMessageAdd(with: message) as ZMTransportData
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

        simulateTyping()

        // when
        sut.processEvents([event], liveEvents: true, prefetchResult: nil)

        // then
        XCTAssertFalse(typing.didSetTypingUsers)
        XCTAssertTrue(typing.isUserTyping(user: userA, in: conversationA)) // user is still typing
    }

    func payloadForOTRMessageAdd(with message: GenericMessage) -> [String: Any] {
        let data = try? message.serializedData().base64String()
        return ["conversation": conversationA.remoteIdentifier!.transportString(),
                       "data": ["text": data],
                       "from": userA.remoteIdentifier!.transportString(),
                       "time": Date().transportString(),
                       "type": "conversation.otr-message-add"
                       ] as [String: Any]
    }

    func testThatItDoesNotForwardOtherEventTypes() {
        // given
        let payload = ["conversation": conversationA.remoteIdentifier!.transportString(),
                       "data": [],
                       "from": userA.remoteIdentifier!.transportString(),
                       "time": Date().transportString(),
                       "type": "conversation.rename"
                       ] as [String: Any]
        let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!

        // when
        sut.processEvents([event], liveEvents: true, prefetchResult: nil)

        // then
        XCTAssertFalse(typing.didSetTypingUsers)
    }

    func testThatItReturnsANextRequestWhenReceivingATypingNotification_Foreground() {
        // given
        let conversation = insertUIConversation()

        // when
        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let request = sut.nextRequest(for: .v0)

        // then
        XCTAssertNotNil(request)
        XCTAssertTrue(isExpected(request: request, for: conversation, isTyping: true))
    }

    func testThatItReturnsANextRequestWhenReceivingATypingNotification_Background() {
        // given
        let conversation = insertUIConversation()
        mockApplicationStatus.mockOperationState = .background

        // when
        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let request = sut.nextRequest(for: .v0)

        // then
        XCTAssertNotNil(request)
        XCTAssertTrue(isExpected(request: request, for: conversation, isTyping: true))
    }

    func testThatItReturnsARequestForEndingPreviousTypingWhenNewTypingStartInOtherConversation() {
        // given
        let conversation1 = insertUIConversation()
        let conversation2 = insertUIConversation()

        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation1)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let request = sut.nextRequest(for: .v0)
        XCTAssertTrue(isExpected(request: request, for: conversation1, isTyping: true))

        // when
        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation2)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let request1 = sut.nextRequest(for: .v0)
        let request2 = sut.nextRequest(for: .v0)

        // then
        let request1IsforConv1 = isExpected(request: request1, for: conversation1, isTyping: false)
        let request2IsforConv1 = isExpected(request: request2, for: conversation1, isTyping: false)
        let request1IsforConv2 = isExpected(request: request1, for: conversation2, isTyping: true)
        let request2IsforConv2 = isExpected(request: request2, for: conversation2, isTyping: true)

        XCTAssertTrue((request1IsforConv1 && request2IsforConv2) || (request2IsforConv1 && request1IsforConv2))
    }

    func testThatItDoesNotReturnARequestForEndingPreviousTypingWhenNewTypingEndInOtherConversation() {
        // given
        let conversation1 = insertUIConversation()
        let conversation2 = insertUIConversation()

        // when
        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation1)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let request1 = sut.nextRequest(for: .v0)

        // then
        XCTAssertNotNil(request1)
        XCTAssertTrue(isExpected(request: request1, for: conversation1, isTyping: true))

        // and when
        TypingStrategy.notifyTranscoderThatUser(isTyping: false, in: conversation2)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let request2 = sut.nextRequest(for: .v0)

        // then
        // and then returns the startTypingEvent of the new conversation
        XCTAssertNotNil(request2)
        XCTAssertTrue(isExpected(request: request2, for: conversation2, isTyping: false))

        // finally
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatItReturnsTheNextValidRequest() {
        // given
        let conversation = insertUIConversation()

        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let request = sut.nextRequest(for: .v0)
        XCTAssertTrue(isExpected(request: request, for: conversation, isTyping: true))

        // when
        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        TypingStrategy.notifyTranscoderThatUser(isTyping: false, in: conversation)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let request1 = sut.nextRequest(for: .v0)

        // then
        XCTAssertNotNil(request1)
        XCTAssertTrue(isExpected(request: request1, for: conversation, isTyping: false))

        // finally
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatItReturns_OnlyOne_RequestsWhenReceiving_One_TypingNotification() {
        // given
        let conversation = insertUIConversation()

        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let request1 = sut.nextRequest(for: .v0)
        XCTAssertNotNil(request1)

        // when
        let request2 = sut.nextRequest(for: .v0)

        // then
        XCTAssertNil(request2)
    }

    func testThatItReturns_Two_RequestsWhenReceiving_Two_TypingNotification_ForDifferentsConversation_Start() {
        // given
        let conversation1 = insertUIConversation()
        let conversation2 = insertUIConversation()

        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation1)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation2)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let request1 = sut.nextRequest(for: .v0)
        let request2 = sut.nextRequest(for: .v0)

        // then
        // Note: the first typing is ended because we assume that typing can only happen in one conversation at a time
        let request1IsforConv1 = isExpected(request: request1, for: conversation1, isTyping: false)
        let request2IsforConv1 = isExpected(request: request2, for: conversation1, isTyping: false)
        let request1IsforConv2 = isExpected(request: request1, for: conversation2, isTyping: true)
        let request2IsforConv2 = isExpected(request: request2, for: conversation2, isTyping: true)

        XCTAssertTrue((request1IsforConv1 && request2IsforConv2) ||
                      (request2IsforConv1 && request1IsforConv2))

    }

    func testThatItReturns_Two_RequestsWhenReceiving_Two_TypingNotification_ForDifferentsConversation_End() {
        // given
        let conversation1 = insertUIConversation()
        let conversation2 = insertUIConversation()

        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation1)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        TypingStrategy.notifyTranscoderThatUser(isTyping: false, in: conversation2)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let request1 = sut.nextRequest(for: .v0)
        let request2 = sut.nextRequest(for: .v0)

        // then
        // Note: the first typing is ended because we assume that typing can only happen in one conversation at a time
        let request1IsforConv1 = isExpected(request: request1, for: conversation1, isTyping: true)
        let request2IsforConv1 = isExpected(request: request2, for: conversation1, isTyping: true)
        let request1IsforConv2 = isExpected(request: request1, for: conversation2, isTyping: false)
        let request2IsforConv2 = isExpected(request: request2, for: conversation2, isTyping: false)

        XCTAssertTrue((request1IsforConv1 && request2IsforConv2) ||
            (request2IsforConv1 && request1IsforConv2))

    }

    func testThatItDoesNotReturnARequestsWhenTheConversationsRemoteIdentifierIsNotSet() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()

        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let request = self.sut.nextRequest(for: .v0)

        // then
        XCTAssertNil(request)
    }

    func testThatItDoesNotReturnARequestsWhenTheClientRegistrationDelegateIsNotReady() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()

        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        mockApplicationStatus.mockSynchronizationState = .unauthenticated
        let request = self.sut.nextRequest(for: .v0)

        // then
        XCTAssertNil(request)
    }

    func testThatAppendingAMessageClearsTheIsTypingState() {
        // given
        let conversation = insertUIConversation()

        // expect
        let expectation = self.expectation(description: "Notified")
        let token = NotificationInContext.addObserver(name: ZMConversation.clearTypingNotificationName,
                                                      context: self.uiMOC.notificationContext,
                                                      using: { note in
                                                        XCTAssertEqual(note.object as? ZMConversation, conversation)
                                                        expectation.fulfill()
        })

        // when
        try! conversation.appendText(content: "foo")

        // then
        withExtendedLifetime(token) {
            XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        }
    }

    func testThatRemovingMemberClearsTypingState() {
        // given
        simulateTyping()
        let event = memberLeaveEvent()
        XCTAssertTrue(typing.isUserTyping(user: userA, in: conversationA)) // user is still typing

        // when
        sut.processEvents([event], liveEvents: true, prefetchResult: nil)

        // then
        XCTAssertFalse(typing.isUserTyping(user: userA, in: conversationA)) // user is not typing
    }

}

// MARK: - Sending multiple requests
extension TypingStrategyTests {

    func requestsForSendingNotifications(isTyping: [Bool], delay: TestTyping) -> (ZMConversation, [ZMTransportRequest?]) {
        var result = [ZMTransportRequest?]()
        let conversation = insertUIConversation()

        isTyping.forEach {
            TypingStrategy.notifyTranscoderThatUser(isTyping: $0, in: conversation)
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            if delay == .delay {
                let interval = (MockTyping.defaultTimeout + 0.5)
                Thread.sleep(forTimeInterval: interval)
            }

            let request = self.sut.nextRequest(for: .v0)
            result.append(request)

            if delay == .clearTranscoder {
                TypingStrategy.clearTranscoderStateForTyping(in: conversation)
                XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            } else if delay == .appendMessage {
                try! conversation.appendText(content: "foo")
                XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            }
        }
        return (conversation, result)
    }

    func testThatItDoesReturn_OnlyOne_RequestsWhenReceiving_AnotherIdentical_TypingNotification() {
        // when
        let (conversation, requests) = requestsForSendingNotifications(isTyping: [true, true], delay: .noDelay)
        XCTAssertEqual(requests.count, 2)
        let request1 = requests.first!
        let request2 = requests.last!

        // then
        XCTAssertTrue(isExpected(request: request1, for: conversation, isTyping: true))
        XCTAssertNil(request2)
    }

    func testThatItDoesReturn_Another_RequestsWhenReceiving_AnotherIdentical_TypingNotificationAfterTheFirstOneIsCleared() {
        // when
        let (conversation, requests) = requestsForSendingNotifications(isTyping: [true, true], delay: .clearTranscoder)
        XCTAssertEqual(requests.count, 2)
        let request1 = requests.first!
        let request2 = requests.last!

        // then
        XCTAssertTrue(isExpected(request: request1, for: conversation, isTyping: true))
        XCTAssertTrue(isExpected(request: request2, for: conversation, isTyping: true))
    }

    func testThatItDoesReturn_Another_RequestsWhenReceiving_AnotherIdentical_TypingNotificationAfterAppendingAMessage() {
        // when
        let (conversation, requests) = requestsForSendingNotifications(isTyping: [true, true], delay: .appendMessage)
        XCTAssertEqual(requests.count, 2)
        let request1 = requests.first!
        let request2 = requests.last!

        // then
        XCTAssertTrue(isExpected(request: request1, for: conversation, isTyping: true))
        XCTAssertTrue(isExpected(request: request2, for: conversation, isTyping: true))
    }

    func testThatItDoesReturn_Two_RequestsWhenReceiving_AnotherDifferent_TypingNotification() {
        // when
        let (conversation, requests) = requestsForSendingNotifications(isTyping: [true, false], delay: .noDelay)
        XCTAssertEqual(requests.count, 2)
        let request1 = requests.first!
        let request2 = requests.last!

        // then
        XCTAssertTrue(isExpected(request: request1, for: conversation, isTyping: true))
        XCTAssertTrue(isExpected(request: request2, for: conversation, isTyping: false))
    }

    func testThatItDoesReturn_Two_RequestsWhenReceiving_AnotherIdentical_TypingNotification_AfterADelay() {
        // when
        let (conversation, requests) = requestsForSendingNotifications(isTyping: [true, true], delay: .delay)
        XCTAssertEqual(requests.count, 2)
        let request1 = requests.first!
        let request2 = requests.last!

        // then
        XCTAssertTrue(isExpected(request: request1, for: conversation, isTyping: true))
        XCTAssertTrue(isExpected(request: request2, for: conversation, isTyping: true))
    }

    func testThatLocalTypingNotificationDoesNotInterferesWithRemoteNotifications() {
        // given
        let conversation = insertUIConversation()

        // expect
        let expectation = self.expectation(description: "Notified")
        let token = NotificationInContext.addObserver(name: ZMConversation.typingChangeNotificationName,
                                                      context: self.uiMOC.notificationContext,
                                                      using: { _ in
                                                        expectation.fulfill()
        })
        _ = NotificationInContext.addObserver(name: ZMConversation.typingNotificationName,
                                              context: self.uiMOC.notificationContext,
                                              using: { _ in
                                                assertionFailure()
        })

        // when
        TypingStrategy.notifyTranscoderThatUser(isTyping: true, in: conversation)

        // then
        withExtendedLifetime(token) {
            XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        }
    }

    func testThatRemoteTypingNotificationDoesNotInterferesWithLocalNotifications() {
        // given
        let conversation = insertUIConversation()

        // expect
        let expectation = self.expectation(description: "Notified")
        let token = NotificationInContext.addObserver(name: ZMConversation.typingNotificationName,
                                                      context: self.uiMOC.notificationContext,
                                                      using: { _ in
                                                        expectation.fulfill()
        })
        _ = NotificationInContext.addObserver(name: ZMConversation.typingChangeNotificationName,
                                              context: self.uiMOC.notificationContext,
                                              using: { _ in
                                                assertionFailure()
        })

        // when
        simulateTyping()
        conversation.notifyTyping(typingUsers: Set())

        // then
        withExtendedLifetime(token) {
            XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        }
    }

    func testThatClearTypingNotificationIsFired() {
        // given
        let conversation = insertUIConversation()

        // expect
        let expectation = self.expectation(description: "Notified")
        let token = NotificationInContext.addObserver(name: ZMConversation.clearTypingNotificationName,
                                                      context: self.uiMOC.notificationContext,
                                                      using: { _ in
                                                        expectation.fulfill()
        })

        // when
        TypingStrategy.clearTranscoderStateForTyping(in: conversation)

        // then
        withExtendedLifetime(token) {
            XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        }
    }
}

class TypingEventTests: MessagingTest {

    var originalTimeout: TimeInterval = 0.0

    override func setUp() {
        super.setUp()
        originalTimeout = MockTyping.defaultTimeout
        MockTyping.defaultTimeout = 0.5
    }

    override func tearDown() {
        MockTyping.defaultTimeout = self.originalTimeout
        super.tearDown()
    }

    func insertUIConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        uiMOC.saveOrRollback()
        return conversation
    }

    func testThatItComparesBasedOnIsTyping() {
        // given
        let conversation = insertUIConversation()

        let eventA = TypingEvent.typingEvent(with: conversation.objectID, isTyping: true, ifDifferentFrom: nil)
        let eventB = TypingEvent.typingEvent(with: conversation.objectID, isTyping: false, ifDifferentFrom: nil)

        // when
        let eventACopy = TypingEvent.typingEvent(with: conversation.objectID, isTyping: true, ifDifferentFrom: eventA)
        let eventBCopy = TypingEvent.typingEvent(with: conversation.objectID, isTyping: false, ifDifferentFrom: eventB)
        let eventAOpposite = TypingEvent.typingEvent(with: conversation.objectID, isTyping: false, ifDifferentFrom: eventA)
        let eventBOpposite = TypingEvent.typingEvent(with: conversation.objectID, isTyping: true, ifDifferentFrom: eventB)

        // then
        XCTAssertNil(eventACopy)
        XCTAssertNil(eventBCopy)
        XCTAssertNotNil(eventAOpposite)
        XCTAssertNotNil(eventBOpposite)
    }

    func testThatItComparesBasedOnConversation() {
        // given
        let conversation1 = insertUIConversation()
        let conversation2 = insertUIConversation()

        let eventA = TypingEvent.typingEvent(with: conversation1.objectID, isTyping: true, ifDifferentFrom: nil)
        let eventB = TypingEvent.typingEvent(with: conversation2.objectID, isTyping: true, ifDifferentFrom: nil)

        // when
        let eventACopy = TypingEvent.typingEvent(with: conversation1.objectID, isTyping: true, ifDifferentFrom: eventA)
        let eventBCopy = TypingEvent.typingEvent(with: conversation2.objectID, isTyping: true, ifDifferentFrom: eventB)
        let eventAOpposite = TypingEvent.typingEvent(with: conversation2.objectID, isTyping: true, ifDifferentFrom: eventA)
        let eventBOpposite = TypingEvent.typingEvent(with: conversation1.objectID, isTyping: true, ifDifferentFrom: eventB)

        // then
        XCTAssertNil(eventACopy)
        XCTAssertNil(eventBCopy)
        XCTAssertNotNil(eventAOpposite)
        XCTAssertNotNil(eventBOpposite)
    }

    func testThatItComparesBasedOnTime() {
        // given
        let conversation = insertUIConversation()

        let eventA = TypingEvent.typingEvent(with: conversation.objectID, isTyping: true, ifDifferentFrom: nil)
        let eventB = TypingEvent.typingEvent(with: conversation.objectID, isTyping: false, ifDifferentFrom: nil)

        // when
        let eventACopy = TypingEvent.typingEvent(with: conversation.objectID, isTyping: true, ifDifferentFrom: eventA)
        let eventBCopy = TypingEvent.typingEvent(with: conversation.objectID, isTyping: false, ifDifferentFrom: eventB)

        let interval = MockTyping.defaultTimeout + 1.0
        Thread.sleep(forTimeInterval: interval)

        let eventADifferent = TypingEvent.typingEvent(with: conversation.objectID, isTyping: true, ifDifferentFrom: eventA)
        let eventBDifferent = TypingEvent.typingEvent(with: conversation.objectID, isTyping: false, ifDifferentFrom: eventB)

        // then
        XCTAssertNil(eventACopy)
        XCTAssertNil(eventBCopy)
        XCTAssertNotNil(eventADifferent)
        XCTAssertNotNil(eventBDifferent)

    }
}
