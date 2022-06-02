//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import XCTest
@testable import WireSyncEngine

class ZMUserSessionTests_PushNotifications: ZMUserSessionTestsBase {

    typealias Category = WireSyncEngine.PushNotificationCategory
    typealias ConversationAction = WireSyncEngine.ConversationNotificationAction
    typealias CallAction = WireSyncEngine.CallNotificationAction

    func testThatItCallsShowConversationList_ForPushNotificationCategoryConversationWithoutConversation() {
        // when
        handle(conversationAction: nil, category: .conversation, userInfo: NotificationUserInfo())

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversationsList, sut)
    }

    func testThatItCallsShowConversationList_ForPushNotificationCategoryConnect() {
        // given
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID()
        let userInfo = userInfoWithConnectionRequest(from: sender)

        // when
        handle(conversationAction: nil, category: .connect, userInfo: userInfo)

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID!)
        XCTAssertFalse(sender.isConnected)
    }

    // TODO jacob this can only be tested in an integration test or with better mocks
//    func testThatItCallsShowConversationListAndConnects_ForPushNotificationCategoryConnectWithAcceptAction() {
//        // given
//        let sender = ZMUser.insertNewObject(in: uiMOC)
//        sender.remoteIdentifier = UUID()
//
//        let userInfo = userInfoWithConnectionRequest(from: sender)
//
//        // when
//        handle(conversationAction: .connect, category: .connect, userInfo: userInfo)
//
//        // then
//        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
//        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID!)
//    }

    func testThatItMutesAndDoesNotShowConversation_ForPushNotificationCategoryConversationWithMuteAction() {
        // given
        let userInfo = userInfoWithConversation()
        let conversation = userInfo.conversation(in: uiMOC)!
        simulateLoggedInUser()

        // when
        handle(conversationAction: .mute, category: .conversation, userInfo: userInfo)

        // then
        XCTAssertNil(mockSessionManager.lastRequestToShowConversation)
        XCTAssertNil(mockSessionManager.lastRequestToShowConversationsList)
        XCTAssertEqual(conversation.mutedMessageTypes, .all)
    }

    func testThatItAddsLike_ForPushNotificationCategoryConversationWithLikeAction() {
        // given
        let userInfo = userInfoWithConversation(hasMessage: true)
        let conversation = userInfo.conversation(in: uiMOC)!

        simulateLoggedInUser()
        sut.applicationStatusDirectory?.operationStatus.isInBackground = true

        // when
        handle(conversationAction: .like, category: .conversation, userInfo: userInfo)

        // then
        XCTAssertEqual((conversation.lastMessage as? ZMMessage)?.reactions.count, 1)
    }

    func testThatItCallsShowConversation_ForPushNotificationCategoryConversation() {
        // given
        let userInfo = userInfoWithConversation()

        // when
        handle(conversationAction: nil, category: .conversation, userInfo: userInfo)

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID!)
    }

    func testThatItCallsShowConversationAtMessage_ForPushNotificationCategoryConversation() {
        // given
        let userInfo = userInfoWithConversation(hasMessage: true)

        // when
        handle(conversationAction: nil, category: .conversation, userInfo: userInfo)

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowMessage?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowMessage?.1.remoteIdentifier, userInfo.conversationID!)
        XCTAssertEqual(mockSessionManager.lastRequestToShowMessage?.2.nonce, userInfo.messageNonce!)
    }

    func testThatItCallsShowConversationAndAcceptsCall_ForPushNotificationCategoryIncomingCallWithAcceptAction() {
        // given
        simulateLoggedInUser()
        createSelfClient()

        let userInfo = userInfoWithConversation()
        let conversation = userInfo.conversation(in: uiMOC)!

        let callCenter = createCallCenter()
        simulateIncomingCall(fromUser: conversation.connectedUser!, conversation: conversation)

        // when
        handle(callAction: .accept, category: .incomingCall, userInfo: userInfo)

        // then
        XCTAssertTrue(callCenter.didCallAnswerCall)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID)
    }

    func testThatItDoesNotCallsShowConversationAndRejectsCall_ForPushNotificationCategoryIncomingCallWithIgnoreAction() {
        // given
        simulateLoggedInUser()
        createSelfClient()

        let userInfo = userInfoWithConversation()
        let conversation = userInfo.conversation(in: uiMOC)!

        let callCenter = createCallCenter()
        simulateIncomingCall(fromUser: conversation.connectedUser!, conversation: conversation)

        // when
        handle(callAction: .ignore, category: .incomingCall, userInfo: userInfo)

        // then
        XCTAssertTrue(callCenter.didCallRejectCall)
        XCTAssertNil(mockSessionManager.lastRequestToShowConversation)
    }

    func testThatItCallsShowConversationButDoesNotCallBack_ForPushNotificationCategoryMissedCallWithCallBackAction() {
        // given
        simulateLoggedInUser()
        createSelfClient()

        let userInfo = userInfoWithConversation()
        let callCenter = createCallCenter()

        // when
        handle(callAction: .callBack, category: .missedCall, userInfo: userInfo)

        // then
        XCTAssertFalse(callCenter.didCallStartCall)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID!)
    }

    func testThatItDoesNotCallShowConversationAndAppendsAMessage_ForPushNotificationCategoryConversationWithDirectReplyAction() {
        // given
        simulateLoggedInUser()
        sut.applicationStatusDirectory?.operationStatus.isInBackground = true

        let userInfo = userInfoWithConversation()
        let conversation = userInfo.conversation(in: uiMOC)!

        // when
        handle(conversationAction: .reply, category: .conversation, userInfo: userInfo, userText: "Hello World")

        // then
        XCTAssertEqual(conversation.allMessages.count, 1)
        XCTAssertNil(mockSessionManager.lastRequestToShowConversation)
    }

    func testThatItAppendsReadReceipt_ForPushNotificationCategoryConversationWithDirectReplyAction() {
        // given
        self.simulateLoggedInUser()
        self.sut.applicationStatusDirectory?.operationStatus.isInBackground = true

        let userInfo = userInfoWithConversation(hasMessage: true)
        let conversation = userInfo.conversation(in: self.uiMOC)!

        guard let originalMessage = conversation.lastMessages().last as? ZMClientMessage else { return XCTFail() }
        ZMUser.selfUser(in: uiMOC).readReceiptsEnabled = true
        var genericMessage = originalMessage.underlyingMessage!
        genericMessage.setExpectsReadConfirmation(true)
        do {
            try originalMessage.setUnderlyingMessage(genericMessage)
        } catch {
            XCTFail("Error in adding data: \(error)")
        }

        // when
        self.handle(conversationAction: .reply, category: .conversation, userInfo: userInfo, userText: "Hello World")

        // then
        let lastMessages = conversation.lastMessages()
        guard let replyMessage = lastMessages[1] as? ZMClientMessage,
        let confirmationMessage = lastMessages[0] as? ZMClientMessage else { return XCTFail() }
        XCTAssertEqual(conversation.allMessages.count, 3)
        XCTAssertTrue(originalMessage.isText)
        XCTAssertTrue(replyMessage.isText)
        XCTAssertFalse(confirmationMessage.isText)
        XCTAssertTrue(confirmationMessage.underlyingMessage?.hasConfirmation ?? false)
    }

    func testThatItAppendsReadReceipt_ForPushNotificationCategoryConversationWithLikeAction() {
        // given
        self.simulateLoggedInUser()
        self.sut.applicationStatusDirectory?.operationStatus.isInBackground = true

        let userInfo = userInfoWithConversation(hasMessage: true)
        let conversation = userInfo.conversation(in: self.uiMOC)!

        guard let originalMessage = conversation.lastMessages().last as? ZMClientMessage else { return XCTFail() }
        ZMUser.selfUser(in: uiMOC).readReceiptsEnabled = true
        var genericMessage = originalMessage.underlyingMessage!
        genericMessage.setExpectsReadConfirmation(true)
        do {
            try originalMessage.setUnderlyingMessage(genericMessage)
        } catch {
            XCTFail("Error in adding data: \(error)")
        }

        // when
        handle(conversationAction: .like, category: .conversation, userInfo: userInfo)

        // then
        guard let confirmationMessage = conversation.lastMessage as? ZMClientMessage else { return XCTFail() }
        XCTAssertEqual(conversation.allMessages.count, 2)
        XCTAssertFalse(confirmationMessage.isText)
        XCTAssertEqual(originalMessage.reactions.count, 1)
        XCTAssertTrue(confirmationMessage.underlyingMessage?.hasConfirmation ?? false)
    }

    func testThatOnLaunchItCallsShowConversationList_ForPushNotificationCategoryConversationWithoutConversation() {
        // given
        simulateLoggedInUser()

        // when
        handle(conversationAction: nil, category: .conversation, userInfo: NotificationUserInfo())

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversationsList, sut)
    }

    func testThatOnLaunchItCallsShowConversationConversation_ForPushNotificationCategoryConversation() {
        // given
        simulateLoggedInUser()

        let userInfo = userInfoWithConversation()

        // when
        handle(conversationAction: nil, category: .conversation, userInfo: userInfo)

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID!)
    }

}

extension ZMUserSessionTests_PushNotifications {

    func handle(conversationAction: ConversationAction?, category: Category, userInfo: NotificationUserInfo, userText: String? = nil) {
        handle(action: conversationAction?.rawValue ?? "", category: category.rawValue, userInfo: userInfo, userText: userText)
    }

    func handle(callAction: CallAction, category: Category, userInfo: NotificationUserInfo) {
        handle(action: callAction.rawValue, category: category.rawValue, userInfo: userInfo)
    }

    func handle(action: String, category: String, userInfo: NotificationUserInfo, userText: String? = nil) {
        sut.handleNotificationResponse(actionIdentifier: action, categoryIdentifier: category, userInfo: userInfo, userText: userText) {}
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sut.didFinishQuickSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func userInfoWithConversation(hasMessage: Bool = false) -> NotificationUserInfo {
        let conversationId = UUID()
        var messageNonce: UUID?
        syncMOC.performGroupedBlockAndWait {

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .oneOnOne
            conversation.remoteIdentifier = conversationId

            let sender = ZMUser.insertNewObject(in: self.syncMOC)
            sender.remoteIdentifier = UUID()

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.conversation = conversation
            connection.to = sender
            connection.status = .accepted

            if hasMessage {
                let message = try! conversation.appendText(content: "123") as? ZMClientMessage
                message?.markAsSent()
                messageNonce = message?.nonce
            }

            self.syncMOC.saveOrRollback()
        }

        let userInfo = NotificationUserInfo()
        userInfo.conversationID = conversationId

        if hasMessage {
            userInfo.messageNonce = messageNonce
        }

        return userInfo
    }

    func userInfoWithConnectionRequest(from sender: ZMUser) -> NotificationUserInfo {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .connection
        conversation.remoteIdentifier = UUID()

        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.conversation = conversation
        connection.to = sender
        connection.status = .pending

        uiMOC.saveOrRollback()

        let userInfo = NotificationUserInfo()
        userInfo.conversationID = conversation.remoteIdentifier
        userInfo.senderID = sender.remoteIdentifier

        return userInfo
    }
}
