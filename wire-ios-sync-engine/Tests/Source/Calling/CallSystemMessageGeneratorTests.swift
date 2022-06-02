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
@testable import WireSyncEngine

class CallSystemMessageGeneratorTests: MessagingTest {

    var sut: WireSyncEngine.CallSystemMessageGenerator!
    var mockWireCallCenterV3: WireCallCenterV3Mock!
    var selfUserID: AVSIdentifier!
    var clientID: String!
    var conversation: ZMConversation!
    var user: ZMUser!
    var selfUser: ZMUser!

    override func setUp() {
        super.setUp()
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.remoteIdentifier = UUID()

        user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID()
        user.name = "Hans"

        selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID()
        selfUserID = selfUser.avsIdentifier
        clientID = "foo"

        sut = WireSyncEngine.CallSystemMessageGenerator()
        mockWireCallCenterV3 = WireCallCenterV3Mock(userId: selfUserID, clientId: clientID, uiMOC: uiMOC, flowManager: FlowManagerMock(), transport: WireCallCenterTransportMock())
    }

    override func tearDown() {
        sut = nil
        selfUserID = nil
        clientID = nil
        selfUser = nil
        conversation = nil
        user = nil
        super.tearDown()
        mockWireCallCenterV3 = nil
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItAppendsPerformedCallSystemMessage_AnsweredOutgoingCall() {
        // given
        let messageCount = conversation.allMessages.count

        // when
        let msg1 = sut.appendSystemMessageIfNeeded(callState: .outgoing(degraded: false), conversation: conversation, caller: selfUser, timestamp: nil, previousCallState: nil)
        let msg2 = sut.appendSystemMessageIfNeeded(callState: .established, conversation: conversation, caller: selfUser, timestamp: nil, previousCallState: nil)
        let msg3 = sut.appendSystemMessageIfNeeded(callState: .terminating(reason: .canceled), conversation: conversation, caller: selfUser, timestamp: nil, previousCallState: nil)

        // then
        XCTAssertEqual(conversation.allMessages.count, messageCount+1)
        XCTAssertNil(msg1)
        XCTAssertNil(msg2)
        if let message = conversation.lastMessage as? ZMSystemMessage {
            XCTAssertEqual(message, msg3)
            XCTAssertEqual(message.systemMessageType, .performedCall)
            XCTAssertTrue(message.users.contains(selfUser))
        } else {
            XCTFail("No system message inserted")
        }
    }

    func testThatItAppendsPerformedCallSystemMessage_AnsweredIncomingCall() {
        // given
        let messageCount = conversation.allMessages.count

        // when
        let msg1 = sut.appendSystemMessageIfNeeded(callState: .incoming(video: false, shouldRing: true, degraded: false), conversation: conversation, caller: user, timestamp: nil, previousCallState: nil)
        let msg2 = sut.appendSystemMessageIfNeeded(callState: .established, conversation: conversation, caller: user, timestamp: nil, previousCallState: nil)
        let msg3 = sut.appendSystemMessageIfNeeded(callState: .terminating(reason: .canceled), conversation: conversation, caller: user, timestamp: nil, previousCallState: nil)

        // then
        XCTAssertEqual(conversation.allMessages.count, messageCount+1)
        XCTAssertNil(msg1)
        XCTAssertNil(msg2)
        if let message = conversation.lastMessage as? ZMSystemMessage {
            XCTAssertEqual(message, msg3)
            XCTAssertEqual(message.systemMessageType, .performedCall)
            XCTAssertTrue(message.users.contains(user))
        } else {
            XCTFail("No system message inserted")
        }
    }

    func testThatItAppendsPerformedCallSystemMessage_UnansweredIncomingCallFromSelfuser() {
        // given
        let messageCount = conversation.allMessages.count

        // when
        let msg1 = sut.appendSystemMessageIfNeeded(callState: .incoming(video: false, shouldRing: true, degraded: false), conversation: conversation, caller: selfUser, timestamp: nil, previousCallState: nil)
        let msg2 = sut.appendSystemMessageIfNeeded(callState: .terminating(reason: .canceled), conversation: conversation, caller: selfUser, timestamp: nil, previousCallState: nil)

        // then
        XCTAssertEqual(conversation.allMessages.count, messageCount+1)
        XCTAssertNil(msg1)
        if let message = conversation.lastMessage as? ZMSystemMessage {
            XCTAssertEqual(message, msg2)
            XCTAssertEqual(message.systemMessageType, .performedCall)
            XCTAssertTrue(message.users.contains(selfUser))
        } else {
            XCTFail("No system message inserted")
        }
    }

    func testThatItAppendsMissedCallSystemMessage_UnansweredIncomingCall() {
        // given
        let messageCount = conversation.allMessages.count

        // when
        let msg1 =  sut.appendSystemMessageIfNeeded(callState: .incoming(video: false, shouldRing: true, degraded: false), conversation: conversation, caller: user, timestamp: nil, previousCallState: nil)
        var msg2: ZMSystemMessage?
        self.performIgnoringZMLogError {
            msg2 = self.sut.appendSystemMessageIfNeeded(callState: .terminating(reason: .canceled), conversation: self.conversation, caller: self.user, timestamp: nil, previousCallState: nil)
        }

        // then
        XCTAssertEqual(conversation.allMessages.count, messageCount+1)
        XCTAssertNil(msg1)
        if let message = conversation.lastMessage as? ZMSystemMessage {
            XCTAssertEqual(message, msg2)
            XCTAssertEqual(message.systemMessageType, .missedCall)
            XCTAssertTrue(message.users.contains(user))
        } else {
            XCTFail("No system message inserted")
        }
    }
}
