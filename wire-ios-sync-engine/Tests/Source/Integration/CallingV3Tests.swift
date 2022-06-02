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
import avs
import WireDataModel
@testable import WireSyncEngine

class CallStateTestObserver: WireCallCenterCallStateObserver {

    var changes: [CallState] = []
    var token: Any?

    func observe(conversation: ZMConversation, context: NSManagedObjectContext) {
        token = WireCallCenterV3.addCallStateObserver(observer: self, for: conversation, context: context)
    }

    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: ZMUser, timestamp: Date?, previousCallState: CallState?) {
        changes.append(callState)
    }

    func checkLastNotificationHasCallState(_ callState: CallState, line: UInt = #line, file: StaticString = #file) {
        guard let lastCallState = changes.last else {
            return XCTFail("Did not receive a notification", file: file, line: line)
        }

        XCTAssertEqual(lastCallState, callState, file: file, line: line)
    }

}

class CallParticipantTestObserver: WireCallCenterCallParticipantObserver {

    var changes: [[(UUID, CallParticipantState)]] = []
    var token: Any?

    func observe(conversation: ZMConversation, context: NSManagedObjectContext) {
        token = WireCallCenterV3.addCallParticipantObserver(observer: self, for: conversation, context: context)
    }

    func callParticipantsDidChange(conversation: ZMConversation, participants: [(UUID, CallParticipantState)]) {
        changes.append(participants)
    }

}

class CallingV3Tests: IntegrationTest {

    var stateObserver: CallStateTestObserver!
    var participantObserver: CallParticipantTestObserver!

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()

        stateObserver = CallStateTestObserver()
        participantObserver = CallParticipantTestObserver()
    }

    override func tearDown() {
        stateObserver = nil
        participantObserver = nil
        super.tearDown()
    }

    func selfJoinCall(isStart: Bool) {
        _ = self.conversationUnderTest.voiceChannel?.join(video: false)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func selfLeaveCall() {
        let convIdRef = self.conversationIdRef
        let userIdRef = self.selfUser.identifier.cString(using: .utf8)
        self.conversationUnderTest.voiceChannel?.leave()
        WireSyncEngine.closedCallHandler(reason: WCALL_REASON_STILL_ONGOING,
                                         conversationId: convIdRef,
                                         messageTime: 0,
                                         userId: userIdRef,
                                         contextRef: self.wireCallCenterRef)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func otherStartCall(user: ZMUser, isVideoCall: Bool = false, shouldRing: Bool = true) {
        let userIdRef = user.remoteIdentifier!.transportString().cString(using: .utf8)
        WireSyncEngine.incomingCallHandler(conversationId: conversationIdRef, messageTime: UInt32(ceil(Date().timeIntervalSince1970)), userId: userIdRef, isVideoCall: isVideoCall ? 1 : 0, shouldRing: shouldRing ? 1 : 0, contextRef: wireCallCenterRef)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func otherJoinCall(user: ZMUser) {
        if useGroupConversation {
            participantsChanged(members: [(user: user, establishedFlow: false)])
        } else {
            WireSyncEngine.answeredCallHandler(conversationId: conversationIdRef, contextRef: wireCallCenterRef)
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }
    }

    private var wireCallCenterRef: UnsafeMutableRawPointer? {
        return Unmanaged<WireCallCenterV3>.passUnretained(userSession!.managedObjectContext.zm_callCenter!).toOpaque()
    }

    private var conversationIdRef: [CChar]? {
        return conversationUnderTest.remoteIdentifier!.transportString().cString(using: .utf8)
    }

    func establishedFlow(user: ZMUser) {
        let userIdRef = user.remoteIdentifier!.transportString().cString(using: .utf8)
        WireSyncEngine.establishedCallHandler(conversationId: conversationIdRef, userId: userIdRef, contextRef: wireCallCenterRef)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func participantsChanged(members: [(user: ZMUser, establishedFlow: Bool)]) {
        let mappedMembers = members.map {AVSCallMember(userId: $0.user.remoteIdentifier!, audioEstablished: $0.establishedFlow)}
        (userSession!.managedObjectContext.zm_callCenter as! WireCallCenterV3IntegrationMock).mockAVSWrapper.mockMembers = mappedMembers

        WireSyncEngine.groupMemberHandler(conversationIdRef: conversationIdRef, contextRef: wireCallCenterRef)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func closeCall(user: ZMUser, reason: CallClosedReason) {
        let userIdRef = user.remoteIdentifier!.transportString().cString(using: .utf8)
        WireSyncEngine.closedCallHandler(reason: reason.wcall_reason, conversationId: conversationIdRef, messageTime: 0, userId: userIdRef, contextRef: wireCallCenterRef)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func simulateMissedCall(user: ZMUser) {
        otherStartCall(user: user)

        let userIdRef = user.remoteIdentifier!.transportString().cString(using: .utf8)
        WireSyncEngine.missedCallHandler(conversationId: conversationIdRef, messageTime: UInt32(Date().timeIntervalSince1970), userId: userIdRef, isVideoCall: 0, contextRef: wireCallCenterRef)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    var useGroupConversation: Bool = false
    var mockConversationUnderTest: MockConversation {
        return useGroupConversation ? groupConversation : selfToUser2Conversation
    }

    var conversationUnderTest: ZMConversation {
        return conversation(for: mockConversationUnderTest)!
    }

    var localSelfUser: ZMUser {
        return user(for: selfUser)!
    }

    func testJoiningAndLeavingAnEmptyVoiceChannel_OneOnOne() {
        // given
        XCTAssertTrue(login())
        stateObserver.observe(conversation: conversationUnderTest, context: userSession!.managedObjectContext)

        // when
        selfJoinCall(isStart: true)

        // then
        XCTAssertEqual(stateObserver.changes.count, 1)
        stateObserver.checkLastNotificationHasCallState(.outgoing(degraded: false))

        // when
        selfLeaveCall()
        closeCall(user: self.localSelfUser, reason: .canceled)

        // then
        XCTAssertEqual(stateObserver.changes.count, 3)
        stateObserver.checkLastNotificationHasCallState(.terminating(reason: .canceled))
    }

    func testJoiningAndLeavingAnVoiceChannel_Group_2ParticipantsLeft() {
        // given
        XCTAssertTrue(login())
        useGroupConversation = true
        stateObserver.observe(conversation: conversationUnderTest, context: userSession!.managedObjectContext)

        // when
        selfJoinCall(isStart: true)

        // then
        XCTAssertEqual(stateObserver.changes.count, 1)
        stateObserver.checkLastNotificationHasCallState(.outgoing(degraded: false))

        // when
        participantsChanged(members: [(user: conversationUnderTest.localParticipants.firstObject as! ZMUser, establishedFlow: false),
                                      (user: conversationUnderTest.localParticipants.lastObject as! ZMUser, establishedFlow: false)])
        stateObserver.changes = []

        // when
        selfLeaveCall()

        // then
        XCTAssertEqual(stateObserver.changes.count, 1)
        stateObserver.checkLastNotificationHasCallState(.incoming(video: false, shouldRing: false, degraded: false))

        // and when
        closeCall(user: self.localSelfUser, reason: .canceled)

        XCTAssertEqual(stateObserver.changes.count, 2)
        stateObserver.checkLastNotificationHasCallState(.terminating(reason: .canceled))
    }

    func testJoiningAndLeavingAnEmptyVoiceChannel_Group() {
        // given
        XCTAssertTrue(login())
        useGroupConversation = true
        stateObserver.observe(conversation: conversationUnderTest, context: userSession!.managedObjectContext)

        // when
        selfJoinCall(isStart: true)

        // then
        XCTAssertEqual(stateObserver.changes.count, 1)
        stateObserver.checkLastNotificationHasCallState(.outgoing(degraded: false))
        stateObserver.changes = []

        // when
        selfLeaveCall()

        // then
        XCTAssertEqual(stateObserver.changes.count, 1)
        stateObserver.checkLastNotificationHasCallState(.incoming(video: false, shouldRing: false, degraded: false))

        // and when
        closeCall(user: self.localSelfUser, reason: .canceled)

        XCTAssertEqual(stateObserver.changes.count, 2)
        stateObserver.checkLastNotificationHasCallState(.terminating(reason: .canceled))
    }

    func testThatItSendsOutAllExpectedNotificationsWhenSelfUserCalls_OneOnOne() {

        // given
        XCTAssertTrue(login())
        stateObserver.observe(conversation: conversationUnderTest, context: userSession!.managedObjectContext)

        // (1) self calling & backend acknowledges
        //
        // when
        selfJoinCall(isStart: true)

        // then
        XCTAssertEqual(stateObserver.changes.count, 1)
        stateObserver.checkLastNotificationHasCallState(.outgoing(degraded: false))

        // (2) other party joins
        //
        // when
        let user = conversationUnderTest.connectedUser!
        otherJoinCall(user: user)

        // then
        XCTAssertEqual(stateObserver.changes.count, 2)
        stateObserver.checkLastNotificationHasCallState(.answered(degraded: false))

        // (3) flow aquired
        //
        // when
        establishedFlow(user: user)

        // then
        XCTAssertEqual(stateObserver.changes.count, 3)
        stateObserver.checkLastNotificationHasCallState(.established)

        // (4) self user leaves
        //
        // when
        selfLeaveCall()
        closeCall(user: self.localSelfUser, reason: .canceled)

        // then
        XCTAssertEqual(stateObserver.changes.count, 5)
        stateObserver.checkLastNotificationHasCallState(.terminating(reason: .canceled))
    }

    func testThatItSendsOutAllExpectedNotificationsWhenSelfUserCalls_Group() {

        // no active users -> self is calling -> self connected to active channel -> no active users

        // given
        XCTAssertTrue(login())
        useGroupConversation = true

        stateObserver.observe(conversation: conversationUnderTest, context: userSession!.managedObjectContext)
        participantObserver.observe(conversation: conversationUnderTest, context: userSession!.managedObjectContext)

        // (1) self calling & backend acknowledges
        //
        // when
        selfJoinCall(isStart: true)

        // then
        XCTAssertEqual(stateObserver.changes.count, 1)
        stateObserver.checkLastNotificationHasCallState(.outgoing(degraded: false))
        XCTAssertEqual(participantObserver.changes.count, 0)

        // (2) other party joins
        //
        // when
        let otherUser = conversationUnderTest.localParticipants.firstObject as! ZMUser
        participantsChanged(members: [(user: otherUser, establishedFlow: false)])

        // then
        XCTAssertEqual(participantObserver.changes.count, 1)

        // (3) flow aquired
        //
        // when
        participantsChanged(members: [(user: otherUser, establishedFlow: true)])

        // then
        XCTAssertEqual(participantObserver.changes.count, 2)

        // (4) self user leaves
        //
        // when
        selfLeaveCall()
        closeCall(user: self.localSelfUser, reason: .canceled)

        // then
        stateObserver.checkLastNotificationHasCallState(.terminating(reason: .canceled))
    }

    func testThatItSendsOutAllExpectedNotificationsWhenOtherUserCalls_OneOnOne() {
        // given
        XCTAssertTrue(login())
        stateObserver.observe(conversation: conversationUnderTest, context: userSession!.managedObjectContext)

        let user = conversationUnderTest.connectedUser!

        // (1) other user joins
        // when
        otherStartCall(user: user)

        // then
        XCTAssertEqual(stateObserver.changes.count, 1)
        stateObserver.checkLastNotificationHasCallState(.incoming(video: false, shouldRing: true, degraded: false))

        // (2) we join
        // when
        selfJoinCall(isStart: false)

        // then
        XCTAssertEqual(stateObserver.changes.count, 2)
        stateObserver.checkLastNotificationHasCallState(.answered(degraded: false))

        // (3) flow aquired
        // when
        establishedFlow(user: localSelfUser)

        // then
        XCTAssertEqual(stateObserver.changes.count, 3)
        stateObserver.checkLastNotificationHasCallState(.established)

        // (4) the other user leaves
        // when
        closeCall(user: user, reason: .canceled)

        // then
        XCTAssertEqual(stateObserver.changes.count, 4)
        stateObserver.checkLastNotificationHasCallState(.terminating(reason: .canceled))
    }

    func testThatItSendsOutAllExpectedNotificationsWhenOtherUserCalls_Group() {
        // given
        XCTAssertTrue(login())
        useGroupConversation = true
        stateObserver.observe(conversation: conversationUnderTest, context: userSession!.managedObjectContext)
        participantObserver.observe(conversation: conversationUnderTest, context: userSession!.managedObjectContext)

        let user = conversationUnderTest.localParticipants.firstObject as! ZMUser

        // (1) other user joins
        // when
        otherStartCall(user: user)

        // then
        XCTAssertEqual(stateObserver.changes.count, 1)
        stateObserver.checkLastNotificationHasCallState(.incoming(video: false, shouldRing: true, degraded: false))

        // (2) we join
        // when
        selfJoinCall(isStart: false)

        // then
        XCTAssertEqual(stateObserver.changes.count, 2)
        stateObserver.checkLastNotificationHasCallState(.answered(degraded: false))

        participantObserver.changes.removeAll()

        // (3) flow aquired
        // when
        participantsChanged(members: [(user: user, establishedFlow: true)])
        establishedFlow(user: localSelfUser)

        // then
        XCTAssertEqual(stateObserver.changes.count, 3)
        stateObserver.checkLastNotificationHasCallState(.established)
        XCTAssertEqual(participantObserver.changes.count, 1) // we notify that user connected

        // (4) the other user leaves
        // when
        closeCall(user: user, reason: .canceled)

        // then
        XCTAssertEqual(stateObserver.changes.count, 4)
        stateObserver.checkLastNotificationHasCallState(.terminating(reason: .canceled))
    }

    func testThatItSendsANotificationWhenWeIgnoreACall() {
        // given
        XCTAssertTrue(login())
        stateObserver.observe(conversation: conversationUnderTest, context: userSession!.managedObjectContext)
        let user = conversationUnderTest.connectedUser!

        // (1) other user joins
        // when
        otherStartCall(user: user)

        // then
        XCTAssertEqual(stateObserver.changes.count, 1)
        stateObserver.checkLastNotificationHasCallState(.incoming(video: false, shouldRing: true, degraded: false))

        // (2) we ignore
        // when
        selfLeaveCall()

        // then
        XCTAssertEqual(stateObserver.changes.count, 2)
        stateObserver.checkLastNotificationHasCallState(.incoming(video: false, shouldRing: false, degraded: false))

        // (3) the call is closed
        // when
        closeCall(user: user, reason: .canceled)

        // then
        XCTAssertEqual(stateObserver.changes.count, 3)
        stateObserver.checkLastNotificationHasCallState(.terminating(reason: .canceled))
    }

    func testThatItSendsANotificationIfIgnoringACallAndImmediatelyAcceptingIt() {

        // given
        XCTAssertTrue(login())
        stateObserver.observe(conversation: conversationUnderTest, context: userSession!.managedObjectContext)
        let user = conversationUnderTest.connectedUser!

        // (1) other user joins and we ignore
        // when
        otherStartCall(user: user)
        selfLeaveCall()

        // then
        XCTAssertEqual(stateObserver.changes.count, 2)
        stateObserver.checkLastNotificationHasCallState(.incoming(video: false, shouldRing: false, degraded: false))

        // (2) we join
        // when
        selfJoinCall(isStart: false)

        // then
        XCTAssertEqual(stateObserver.changes.count, 3)
        stateObserver.checkLastNotificationHasCallState(.answered(degraded: false))
    }

    func testThatItFiresAConversationChangeNotificationWhenAGroupCallIsDeclined() {
        // given
        XCTAssertTrue(login())
        useGroupConversation = true

        let user = conversationUnderTest.localParticipants.firstObject as! ZMUser
        let convObserver = ConversationChangeObserver(conversation: conversationUnderTest)

        // (1) Other user calls
        // when
        otherStartCall(user: user)

        // then
        XCTAssertGreaterThan(convObserver!.notifications.count, 0)
        XCTAssertEqual(conversationUnderTest.conversationListIndicator, .none)
        convObserver?.clearNotifications()

        // (2) Self ignores call
        // and when
        selfLeaveCall()

        // then
        XCTAssertEqual(convObserver!.notifications.count, 1)
        if let change = convObserver!.notifications.lastObject as? ConversationChangeInfo {
            XCTAssertTrue(change.conversationListIndicatorChanged)
        }
        XCTAssertEqual(conversationUnderTest.conversationListIndicator, .inactiveCall)

        // (3) Other user ends call
        // and when
        closeCall(user: user, reason: .canceled)

        // then (We don't show a missed call indicator for calls which the self user previously ignored)
        XCTAssertEqual(conversationUnderTest.conversationListIndicator, .none)
    }

    func testThatItFiresAConversationChangeNotificationWhenAGroupCallIsJoined() {
        // given
        XCTAssertTrue(login())
        useGroupConversation = true

        let localUser1 = conversationUnderTest.localParticipants.firstObject as! ZMUser
        let localUser2 = conversationUnderTest.localParticipants.lastObject as! ZMUser
        let convObserver = ConversationChangeObserver(conversation: conversationUnderTest)

        // (1) Other user calls
        // when
        otherStartCall(user: localUser1)

        // then
        XCTAssertEqual(conversationUnderTest.conversationListIndicator, .none)
        convObserver?.clearNotifications()

        // (2) Self joins the call
        // and when
        selfJoinCall(isStart: false)
        establishedFlow(user: localSelfUser)

        // second user joins
        participantsChanged(members: [(user: localUser1, establishedFlow: false),
                                      (user: localUser2, establishedFlow: false)])

        // then
        XCTAssertEqual(convObserver!.notifications.count, 1)
        if let change = convObserver!.notifications.lastObject as? ConversationChangeInfo {
            XCTAssertTrue(change.conversationListIndicatorChanged)
        }
        XCTAssertEqual(conversationUnderTest.conversationListIndicator, .activeCall)

        // (3) selfUser user ends call
        // and when
        selfLeaveCall()

        // then
        XCTAssertEqual(convObserver!.notifications.count, 2)
        if let change = convObserver!.notifications.lastObject as? ConversationChangeInfo {
            XCTAssertTrue(change.conversationListIndicatorChanged)
        }
        XCTAssertEqual(conversationUnderTest.conversationListIndicator, .inactiveCall)

        // (4) other user ends call
        // and when
        closeCall(user: localUser1, reason: .canceled)

        // then
        XCTAssertEqual(convObserver!.notifications.count, 3)
        if let change = convObserver!.notifications[2] as? ConversationChangeInfo {
            XCTAssertTrue(change.conversationListIndicatorChanged)
        }
        XCTAssertEqual(conversationUnderTest.conversationListIndicator, .none)
    }

    func testThatItCanIgnoreACallAndReinitiateNewCallWhenCallEnded() {
        // given
        XCTAssertTrue(login())
        useGroupConversation = true
        let user = conversationUnderTest.localParticipants.firstObject as! ZMUser

        // Other user calls
        otherStartCall(user: user)

        // Self ignores call
        selfLeaveCall()

        // Other user ends call
        closeCall(user: user, reason: .canceled)
        XCTAssertEqual(conversationUnderTest.voiceChannel?.state, CallState.none)

        // SelfUser calls
        // when
        selfJoinCall(isStart: true)

        // then
        XCTAssertEqual(conversationUnderTest.voiceChannel?.state, .outgoing(degraded: false))
    }

    func testThatItCanIgnoreACallAndSeeNewCallWhenCallEnded() {
        // given
        XCTAssertTrue(login())
        useGroupConversation = true
        let user = conversationUnderTest.localParticipants.firstObject as! ZMUser

        // Other user calls
        otherStartCall(user: user)

        // Self ignores call
        selfLeaveCall()

        // Other user ends call
        closeCall(user: user, reason: .canceled)
        XCTAssertEqual(conversationUnderTest.voiceChannel?.state, CallState.none)

        // Other user calls
        // when
        otherStartCall(user: user)

        // then
        XCTAssertEqual(conversationUnderTest.voiceChannel?.state, .incoming(video: false, shouldRing: true, degraded: false))
    }

    func testThatCallIsTerminatedIfConversationSecurityDegrades() {

        // given
        XCTAssertTrue(login())

        let remoteUser = user(for: user2)!

        // Make conversation secure
        establishSession(with: user2)
        let selfClient = ZMUser.selfUser(inUserSession: userSession!).selfClient()!
        userSession?.perform {
            remoteUser.clients.forEach({ selfClient.trustClient($0) })
        }
        XCTAssertEqual(conversationUnderTest.securityLevel, .secure)

        // Other user calls
        otherStartCall(user: remoteUser)

        // Self joins the call
        selfJoinCall(isStart: true)

        // Call is established
        establishedFlow(user: remoteUser)
        XCTAssertEqual(conversationUnderTest.voiceChannel?.state, .established)

        // when
        mockTransportSession.performRemoteChanges { session in
            session.registerClient(for: self.selfUser, label: "Foo client", type: "permanent")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversationUnderTest.voiceChannel?.state, .terminating(reason: .securityDegraded))
    }

}

// MARK: - SystemMessages
extension CallingV3Tests {

    func fetchAllClients() {
        userSession?.perform {
            self.conversationUnderTest.appendMessage(withText: "foo") // make sure we have all clients
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        spinMainQueue(withTimeout: 1.5)
    }

    func testThatItCreatesASystemMessageWhenWeMissedACall() {

        // given
        XCTAssertTrue(login())
        let user = conversationUnderTest.connectedUser!
        fetchAllClients()

        let messageCount = conversationUnderTest.recentMessages.count

        // expect
        expectation(forNotification: WireSyncEngine.WireCallCenterMissedCallNotification.notificationName, object: nil)

        // when
        simulateMissedCall(user: user)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

        // then
        // we receive a systemMessage that we missed a call
        XCTAssertEqual(conversationUnderTest.recentMessages.count, messageCount+1)
        guard let systemMessage = conversationUnderTest.recentMessages.last as? ZMSystemMessage
        else {
            return XCTFail("Did not insert a system message")
        }

        XCTAssertNotNil(systemMessage.systemMessageData)
        XCTAssertEqual(systemMessage.systemMessageData?.systemMessageType, ZMSystemMessageType.missedCall)
    }

    func testThatTheMissedCallSystemMessageUnarchivesTheConversation() {
        // given
        XCTAssertTrue(login())
        fetchAllClients()

        self.userSession?.perform {
            self.conversationUnderTest.isArchived = true
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let user = conversationUnderTest.connectedUser!
        let messageCount = conversationUnderTest.recentMessages.count

        // expect
        expectation(forNotification: WireSyncEngine.WireCallCenterMissedCallNotification.notificationName, object: nil)

        // when
        simulateMissedCall(user: user)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversationUnderTest.recentMessages.count, messageCount+1)
        XCTAssertFalse(conversationUnderTest.isArchived)
    }

    func testThatItCreatesAPerformedCallSystemMessageWhenTheCallIsEnded() {

        // given
        XCTAssertTrue(login())
        fetchAllClients()
        let user = conversationUnderTest.connectedUser!
        let messageCount = conversationUnderTest.recentMessages.count

        // when
        otherStartCall(user: user)
        selfJoinCall(isStart: false)
        establishedFlow(user: user)
        closeCall(user: user, reason: .canceled)

        // we receive a performed call systemMessage
        XCTAssertEqual(conversationUnderTest.recentMessages.count, messageCount+1)
        guard let systemMessage = conversationUnderTest.recentMessages.last as? ZMSystemMessage
            else {
                return XCTFail("Did not insert a system message")
        }

        XCTAssertNotNil(systemMessage.systemMessageData)
        XCTAssertEqual(systemMessage.systemMessageData?.systemMessageType, ZMSystemMessageType.performedCall)
    }

    func testThatThePerformedCallSystemMessageUnarchivesTheConversation() {
        // given
        XCTAssertTrue(login())
        fetchAllClients()
        let user = conversationUnderTest.connectedUser!

        self.userSession?.perform {
            self.conversationUnderTest.isArchived = true
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertTrue(conversationUnderTest.isArchived)
        let messageCount = conversationUnderTest.recentMessages.count

        // when
        otherStartCall(user: user)
        selfJoinCall(isStart: false)
        establishedFlow(user: user)
        closeCall(user: user, reason: .canceled)

        // the conversation is unarchived
        XCTAssertEqual(conversationUnderTest.recentMessages.count, messageCount+1)
        XCTAssertFalse(conversationUnderTest.isArchived)
    }

    func testThatItUpdatesTheLastModifiedDateOfTheConversationWithTheIncomingCallTimestamp() {
        // given
        XCTAssertTrue(login())
        let user = conversationUnderTest.connectedUser!

        let timeIntervalBeforeCall = conversationUnderTest.lastModifiedDate!.timeIntervalSince1970

        // when
        otherStartCall(user: user)

        // then
        let modified = conversationUnderTest.lastModifiedDate!.timeIntervalSince1970
        XCTAssertGreaterThan(modified, timeIntervalBeforeCall)
    }

}
