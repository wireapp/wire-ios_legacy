////
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

import Foundation
import WireProtos

@testable import WireMockTransport

class MockTransportSessionConversationsTests_Swift: MockTransportSessionTests {

    var selfUser: MockUser!
    var team: MockTeam!

    override func setUp() {
        super.setUp()
        sut.performRemoteChanges { session in
            self.team = session.insertTeam(withName: "Name", isBound: true)
            self.selfUser = session.insertSelfUser(withName: "me")
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    override func tearDown() {
        self.team = nil
        self.selfUser = nil
        super.tearDown()
    }
    
    // MARK: - AccessMode

    func testThatDefaultAccessModeForOneToOneConversationIsCorrect() {
        // when
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertOneOnOneConversation(withSelfUser: self.selfUser, otherUser: session.insertUser(withName: "friend"))
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation.accessMode, ["private"])
        XCTAssertEqual(conversation.accessRole, "private")
    }

    func testThatDefaultAccessModeForGroupConversationIsCorrect() {
        // when
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertGroupConversation(withSelfUser: self.selfUser, otherUsers: [session.insertUser(withName: "friend"), session.insertUser(withName: "other friend")])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation.accessMode, ["invite"])
        XCTAssertEqual(conversation.accessRole, "activated")
    }

    func testThatDefaultAccessModeForTeamGroupConversationIsCorrect() {
        // when
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertTeamConversation(to: self.team, with: [session.insertUser(withName: "friend"), session.insertUser(withName: "other friend")], creator: self.selfUser)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation.accessMode, ["invite"])
        XCTAssertEqual(conversation.accessRole, "activated")
    }

    func testThatPushPayloadIsNilWhenThereAreNoChanges() {
        // given
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertTeamConversation(to: self.team, with: [], creator: self.selfUser)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(conversation.changePushPayload)
    }

    func testThatPushPayloadIsPresentWhenChangingAccessMode() {
        // given
        let newAccessMode = ["invite", "code"]
        let newAccessRoleV2 = ["team_member", "non_team_member"]
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertTeamConversation(to: self.team, with: [], creator: self.selfUser)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotEqual(conversation.accessMode, newAccessMode)
        XCTAssertNotEqual(conversation.accessRoleV2, newAccessRoleV2)

        // when
        conversation.accessMode = newAccessMode
        conversation.accessRoleV2 = newAccessRoleV2

        // then
        XCTAssertNotNil(conversation.changePushPayload)
        guard let access = conversation.changePushPayload?["access"] as? [String] else { XCTFail(); return }
        guard let accessRoleV2 = conversation.changePushPayload?["access_role_v2"] as? [String] else { XCTFail(); return }
        XCTAssertEqual(access, newAccessMode)
        XCTAssertEqual(accessRoleV2, newAccessRoleV2)
    }

    func testThatPushPayloadIsPresentWhenChangingAccessRole() {
        // given
        let newAccessRole = "non_activated"
        let newAccessRoleV2 = ["team_member", "non_team_member", "guest", "service"]
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertTeamConversation(to: self.team, with: [], creator: self.selfUser)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotEqual(conversation.accessRole, newAccessRole)
        XCTAssertNotEqual(conversation.accessRoleV2, newAccessRoleV2)

        // when
        conversation.accessRole = newAccessRole
        conversation.accessRoleV2 = newAccessRoleV2

        // then
        XCTAssertNotNil(conversation.changePushPayload)
        guard let accessRole = conversation.changePushPayload?["access_role"] as? String else { XCTFail(); return }
        guard let accessRoleV2 = conversation.changePushPayload?["access_role_v2"] as? [String] else { XCTFail(); return }

        XCTAssertEqual(accessRole, newAccessRole)
        XCTAssertEqual(accessRoleV2, newAccessRoleV2)
    }

    func testThatUpdateEventIsGeneratedWhenChangingAccessRoles() {
        // given
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertTeamConversation(to: self.team, with: [self.selfUser], creator: session.insertUser(withName: "some"))
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sut.saveAndCreatePushChannelEventForSelfUser()
        let eventsCount = sut.generatedPushEvents.count

        // when
        sut.performRemoteChanges { session in
            conversation.accessRole = "non_activated"
            conversation.accessMode = ["invite", "code"]
            conversation.accessRoleV2 = ["[team_member", "non_team_member", "guest", "service"]
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.generatedPushEvents.count, eventsCount + 1)
        guard let lastEvent = sut.generatedPushEvents.lastObject as? MockPushEvent else { XCTFail(); return }
        guard let payloadData = lastEvent.payload as? [String : Any] else { XCTFail(); return }
        guard let data = payloadData["data"] as? [String : Any] else { XCTFail(); return }

        XCTAssertNotNil(data["access"])
        XCTAssertNotNil(data["access_role"])
        XCTAssertNotNil(data["access_role_v2"])

    }
    
    func testThatItReturnsConversationRolesIfConversationIsNotPartOfATeam() {
        // given
        var conversation: MockConversation!
        var user1: MockUser!
        var user2: MockUser!
        
        sut.performRemoteChanges { session in
            user1 = session.insertUser(withName: "one")
            user2 = session.insertUser(withName: "two")
            conversation = session.insertConversation(withSelfUserAndGroupRoles: self.selfUser, otherUsers: [user1!, user2!])
        }
       
        // when
        let path = "/conversations/\(conversation.identifier)/roles"
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 200)
        XCTAssertNotNil(response?.payload)
        
        // then
        let payload = response?.payload?.asDictionary() as? [String : Any?]
        guard let conversationRoles = payload?["conversation_roles"] as? [[String : Any]] else {
            XCTFail("Should have conversation roles array")
            return
        }
        XCTAssertNil(conversation.team)
        XCTAssertEqual(conversationRoles.count, conversation.nonTeamRoles!.count)
        let admin = conversationRoles.first(where: {($0["conversation_role"] as? String) == MockConversation.admin})
        XCTAssertEqual((admin?["actions"] as? [String]).map({Set($0)}), Set([
            "add_conversation_member",
            "remove_conversation_member",
            "modify_conversation_name",
            "modify_conversation_message_timer",
            "modify_conversation_receipt_mode",
            "modify_conversation_access",
            "modify_other_conversation_member",
            "leave_conversation","delete_conversation"
            ]))
        
        let member = conversationRoles.first(where: {($0["conversation_role"] as? String) == MockConversation.member})
        XCTAssertEqual(member?["actions"] as? [String], ["leave_conversation"])
    }
    
    func testThatItReturnsTeamRolesIfConversationIsPartOfATeam() {
        // given
        var conversation: MockConversation!
        var user1: MockUser!
        var user2: MockUser!
        var team: MockTeam!
        
        sut.performRemoteChanges { session in
            user1 = session.insertUser(withName: "one")
            user2 = session.insertUser(withName: "two")
            team = session.insertTeam(withName: "Name", isBound: true)
            conversation = session.insertTeamConversation(to: team, with: [user1, user2], creator: self.selfUser)
        }
        
        // when
        let path = "/conversations/\(conversation.identifier)/roles"
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 200)
        XCTAssertNotNil(response?.payload)
        
        // then
        let payload = response?.payload?.asDictionary() as? [String : Any?]
        guard let conversationRoles = payload?["conversation_roles"] as? [[String : Any]] else {
            XCTFail("Should have conversation roles array")
            return
        }
        XCTAssertNotNil(conversation.team)
        XCTAssertEqual(conversationRoles.count, team.roles.count)
        let admin = conversationRoles.first(where: {($0["conversation_role"] as? String) == MockConversation.admin})
        XCTAssertEqual((admin?["actions"] as? [String]).map({Set($0)}), Set([
            "add_conversation_member",
            "remove_conversation_member",
            "modify_conversation_name",
            "modify_conversation_message_timer",
            "modify_conversation_receipt_mode",
            "modify_conversation_access",
            "modify_other_conversation_member",
            "leave_conversation","delete_conversation"
            ]))
        
        let member = conversationRoles.first(where: {($0["conversation_role"] as? String) == MockConversation.member})
        XCTAssertEqual(member?["actions"] as? [String], ["leave_conversation"])
    }
    
    func testThatItDecodesOTRMessageProtobufOnReceivingClient() {
        // GIVEN
        var selfClient: MockUserClient?
        
        var otherUser: MockUser?
        var otherUserClient: MockUserClient?
        
        var conversation: MockConversation?
        
        self.sut.performRemoteChanges { (session) in
            session.registerClient(for: self.selfUser!, label: "self user", type: "permanent", deviceClass: "phone")
    
            otherUser = session.insertUser(withName: "bar")
            conversation = session.insertConversation(withCreator: self.selfUser, otherUsers: [otherUser!], type: ZMTConversationType.oneOnOne)
            
            selfClient = self.selfUser?.clients.anyObject() as? MockUserClient
            otherUserClient = otherUser?.clients.anyObject() as? MockUserClient
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        let messageText = "Fofooof"
        let text = Text.with {
            $0.content = messageText
        }

        let messageID = UUID.create().transportString()
        let message = GenericMessage.with {
            $0.text = text
            $0.messageID = messageID
        }
        
        var messageData: Data?
        do {
            let data = try message.serializedData()
            messageData = try selfClient?.newOtrMessageWithRecipients(for: [otherUserClient!], plainText: data).serializedData()
        } catch {
            return XCTFail()
        }
        
        // WHEN
        let requestPath = "/conversations/\(conversation!.identifier)/otr/messages"
        let response = self.response(forProtobufData: messageData, path: requestPath, method: ZMTransportRequestMethod.methodPOST, apiVersion: .v0)
        
        // THEN
        XCTAssertEqual(response!.httpStatus, 201)
        let lastEvent = conversation!.events.lastObject as! MockEvent
        XCTAssertNotNil(lastEvent)
        XCTAssertEqual(lastEvent.eventType, ZMUpdateEventType.conversationOtrMessageAdd)
        XCTAssertNotNil(lastEvent.decryptedOTRData)
        let decryptedMessage = try! GenericMessage(serializedData: lastEvent.decryptedOTRData!)
        XCTAssertEqual(decryptedMessage.text.content, messageText)
    }
    
    func testThatItReturnsMissingClientsWhenReceivingOTRMessage_Protobuf() {
        // GIVEN
        var selfClient: MockUserClient!
        var secondSelfClient: MockUserClient!
        
        var otherUser: MockUser!
        var otherUserClient: MockUserClient!
        var secondOtherUserClient: MockUserClient!
        var redundantClient: MockUserClient!
        var conversation: MockConversation!
        
        sut.performRemoteChanges { session in
            session.registerClient(for: self.selfUser, label: "self user", type: "permanent", deviceClass: "phone")
            
            otherUser = session.insertUser(withName: "bar")
            otherUserClient = otherUser.clients.anyObject() as? MockUserClient
            secondOtherUserClient = session.registerClient(for: otherUser, label: "other2", type: "permanent", deviceClass: "phone")
            redundantClient = session.registerClient(for: otherUser, label: "Wire for OS/2", type: "permanent", deviceClass: "phone")
            
            selfClient = self.selfUser.clients.anyObject() as? MockUserClient
            secondSelfClient = session.registerClient(for: self.selfUser, label: "self2", type: "permanent", deviceClass: "phone")
            
            conversation = session.insertConversation(withCreator: self.selfUser, otherUsers: [otherUser!], type: .oneOnOne)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        let previousNotificationsCount = sut.generatedPushEvents.count
        
        let data = "foobar".data(using: .utf8)!
        let messageData = try? selfClient.newOtrMessageWithRecipients(for: [otherUserClient, redundantClient], plainText: data).serializedData()
        
        sut.performRemoteChanges { _ in
            redundantClient.user = nil
        }
        
        // WHEN
        let requestPath = "/conversations/\(conversation.identifier)/otr/messages"
        let response = self.response(forProtobufData: messageData, path: requestPath, method: .methodPOST, apiVersion: .v0)
        
        // THEN
        XCTAssertNotNil(response)
        XCTAssertNil(response?.transportSessionError)
        
        XCTAssertEqual(response?.httpStatus, 412)
        let expectedResponsePayload = [
            "missing": [
                selfUser.identifier: [secondSelfClient.identifier],
                otherUser.identifier: [secondOtherUserClient.identifier]
            ],
            "deleted": [
                otherUser.identifier: [redundantClient.identifier]
            ]
        ]
        
        if let response = response {
            assertExpectedPayload(expectedResponsePayload, in: response)
        }

        XCTAssertEqual(sut.generatedPushEvents.count, previousNotificationsCount)
    }

    func testThatItCreatesPushEventsWhenReceivingOTRMessageWithoutMissedClients_Protobuf() {
        // GIVEN
        var selfClient: MockUserClient!
        var secondSelfClient: MockUserClient!
        
        var otherUser: MockUser!
        var otherUserClient: MockUserClient!
        var secondOtherUserClient: MockUserClient!
        var conversation: MockConversation!
        
        sut.performRemoteChanges { session in
            session.registerClient(for: self.selfUser, label: "self user", type: "permanent", deviceClass: "phone")
                       
            otherUser = session.insertUser(withName: "bar")
            conversation = session.insertConversation(withCreator: self.selfUser, otherUsers: [otherUser!], type: .oneOnOne)
            
            selfClient = self.selfUser.clients.anyObject() as? MockUserClient
            secondSelfClient = session.registerClient(for: self.selfUser, label: "self2", type: "permanent", deviceClass: "phone")
            
            otherUserClient = otherUser.clients.anyObject() as? MockUserClient
            secondOtherUserClient = session.registerClient(for: otherUser, label: "other2", type: "permanent", deviceClass: "phone")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        let previousNotificationCount = sut.generatedPushEvents.count
        
        let data = "foobar".data(using: .utf8)!
        let message = selfClient.newOtrMessageWithRecipients(for: [secondSelfClient, otherUserClient, secondOtherUserClient], plainText: data)
        let messageData = try? message.serializedData()
        
        // WHEN
        let requestPath = "/conversations/\(conversation.identifier)/otr/messages"
        let response = self.response(forProtobufData: messageData, path: requestPath, method: .methodPOST, apiVersion: .v0)
        
        // THEN
        XCTAssertNotNil(response)
        XCTAssertNil(response?.transportSessionError)
        
        XCTAssertEqual(response?.httpStatus, 201)
        
        let expectedResponsePayload = [
            "missing": [:],
            "redundant": [:]
        ]
       
       if let response = response {
            assertExpectedPayload(expectedResponsePayload, in: response)
        }

        XCTAssertEqual(sut.generatedPushEvents.count, previousNotificationCount + 3)
        if sut.generatedPushEvents.count > 4 {
            let otrEvents = sut.generatedPushEvents.subarray(with: NSRange(location: sut.generatedPushEvents.count-3, length: 3)) as! [MockPushEvent]
            
            for event in otrEvents {
                let eventPayload = event.payload.asDictionary()
                XCTAssertEqual(eventPayload?["type"] as? String, "conversation.otr-message-add")
            }
        }
    }
}
