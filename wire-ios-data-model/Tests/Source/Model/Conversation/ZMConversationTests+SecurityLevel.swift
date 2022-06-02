//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
@testable import WireDataModel

class ZMConversationTests_SecurityLevel: ZMConversationTestsBase {

    private func createUsersWithClientsOnSyncMOC(count: Int) -> [ZMUser] {
        self.selfUser = ZMUser.selfUser(in: self.syncMOC)
        return (0..<count).map { i in
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            let userClient = UserClient.insertNewObject(in: self.syncMOC)
            let userConnection = ZMConnection.insertNewSentConnection(to: user)
            userConnection.status = .accepted
            userClient.user = user
            user.name = "createdUser \(i+1)"
            return user
        }
    }

    func testThatConversationInitialSecurityLevelIsNotSecured() {
        self.syncMOC.performGroupedAndWait {_ in
            // given
            let users = self.createUsersWithClientsOnSyncMOC(count: 2)
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!

            // then
            XCTAssertEqual(conversation.securityLevel, .notSecure)
        }
    }

    func testThatItIncreasesSecurityLevelIfAllClientsInConversationAreTrusted() {
        self.syncMOC.performGroupedAndWait {_ in
            // given
            let users = self.createUsersWithClientsOnSyncMOC(count: 2)
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            // when
            selfClient.trustClients(Set(users.map { $0.clients.first! }))

            // then
            XCTAssertEqual(conversation.securityLevel, .secure)
        }
    }

    func testThatItDoesNotIncreaseTheSecurityLevelIfAConversationIsAConnection() {
        self.syncMOC.performGroupedAndWait {_ in
            // given
            let selfUser = ZMUser.selfUser(in: self.uiMOC)

            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.conversationType = .connection
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
            let selfClient = self.createSelfClient(onMOC: self.uiMOC)

            let userClient = UserClient.insertNewObject(in: self.uiMOC)
            userClient.remoteIdentifier = UUID.create().uuidString
            userClient.user = selfUser

            // when
            XCTAssertEqual(conversation.securityLevel, .notSecure)
            XCTAssertFalse(conversation.allUsersTrusted)

            selfClient.trustClient(userClient)
            conversation.increaseSecurityLevelIfNeededAfterTrusting(clients: Set([userClient]))

            // then
            XCTAssertTrue(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .notSecure)
        }
    }

    func testThatItDoesNotIncreaseTheSecurityLevelIfAConversationContainsUsersWithoutAConnection() {
        self.syncMOC.performGroupedAndWait {_ in
            // given
            let users = self.createUsersWithClientsOnSyncMOC(count: 2)

            let unconnectedUser = users.first!
            let connectedUser = users.last!
            unconnectedUser.connection!.status = .sent

            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            // when
            selfClient.trustClients(connectedUser.clients)

            // then
            XCTAssertFalse(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .notSecure)

            // when
            unconnectedUser.connection!.status = .accepted
            selfClient.trustClients(unconnectedUser.clients)

            // then
            XCTAssertTrue(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .secure)

            let newUnconnectedUser = ZMUser.insertNewObject(in: self.syncMOC)
            let unconnectedUserClient = UserClient.insertNewObject(in: self.syncMOC)
            unconnectedUserClient.user = newUnconnectedUser

            // when adding a new participant
            conversation.addParticipantAndUpdateConversationState(user: newUnconnectedUser, role: nil)

            // then the conversation should degrade
            XCTAssertFalse(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .secureWithIgnored)

            // when
            conversation.removeParticipantAndUpdateConversationState(user: newUnconnectedUser, initiatingUser: self.selfUser)

            // then
            XCTAssertTrue(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .secure)
        }
    }

    func testThatItIncreaseTheSecurityLevelIfAConversationContainsUsersWithoutAConnection_Wireless() {
        self.syncMOC.performGroupedAndWait {_ in
            // given
            let users = self.createUsersWithClientsOnSyncMOC(count: 2)

            let unconnectedUser = users.first!
            let connectedUser = users.last!
            unconnectedUser.expiresAt = Date(timeIntervalSinceNow: 60)
            unconnectedUser.connection = nil

            XCTAssertTrue(unconnectedUser.isWirelessUser)
            XCTAssertFalse(unconnectedUser.isConnected)
            XCTAssertNil(unconnectedUser.team)

            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            // when
            selfClient.trustClients(connectedUser.clients)
            selfClient.trustClients(unconnectedUser.clients)

            // then
            XCTAssertTrue(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .secure)
        }
    }

    func testThatItDoesDecreaseTheSecurityLevelWhenAskedToMakeNotSecure() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.securityLevel = .secureWithIgnored

        // when
        conversation.acknowledgePrivacyWarning(withResendIntent: false)

        // then
        XCTAssertEqual(conversation.securityLevel, .notSecure)
    }

    func testThatItInsertsAnIgnoredClientsSystemMessageWhenAddingAConversationParticipantInASecuredConversation() {
        self.syncMOC.performGroupedAndWait { _ in
            // given
            let users = self.createUsersWithClientsOnSyncMOC(count: 2)

            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            // when
            selfClient.trustClients(users.first!.clients)
            selfClient.trustClients(users.last!.clients)

            // then
            XCTAssertTrue(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .secure)

            // when adding a new participant
            let user3 = self.createUsersWithClientsOnSyncMOC(count: 1).last!
            conversation.addParticipantAndUpdateConversationState(user: user3, role: nil)

            // then the conversation should degrade
            XCTAssertFalse(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .secureWithIgnored)

            // Conversation degraded message
            let conversationDegradedMessage = conversation.lastMessage as? ZMSystemMessage
            XCTAssertEqual(conversationDegradedMessage?.systemMessageType, .newClient)
            XCTAssertEqual(conversationDegradedMessage?.addedUsers, Set([user3]))
            XCTAssertEqual(conversationDegradedMessage?.users, Set([user3]))

            // when
            conversation.removeParticipantAndUpdateConversationState(user: user3, initiatingUser: self.selfUser)

            // then
            XCTAssertTrue(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .secure)
            let message2 = conversation.lastMessage as? ZMSystemMessage
            XCTAssertEqual(message2?.systemMessageType, .conversationIsSecure)
        }
    }

    func testThatItDoesNotIncreaseSecurityLevelIfNotAllClientsAreTrusted() {
        self.syncMOC.performGroupedAndWait { _ in
            // given
            let users = self.createUsersWithClientsOnSyncMOC(count: 2)
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            // when
            selfClient.trustClients(users.first!.clients)

            // then
            XCTAssertEqual(conversation.securityLevel, .notSecure)
        }
    }

    func testThatItDoesNotIncreaseSecurityLevelIfNotAllUsersHaveClients() {
        self.syncMOC.performGroupedAndWait { _ in
            // given
            let userWithoutClients = ZMUser.insertNewObject(in: self.syncMOC)
            let users = self.createUsersWithClientsOnSyncMOC(count: 2) + [userWithoutClients]
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            let allClients = users.flatMap {
                $0.clients
            }

            // when
            selfClient.trustClients(Set(allClients))

            // then
            XCTAssertEqual(conversation.securityLevel, .notSecure)
        }
    }

    func testThatItDecreaseSecurityLevelIfSomeOfTheClientsIsIgnored() {
        self.syncMOC.performGroupedAndWait { _ in
            // given
            let users = self.createUsersWithClientsOnSyncMOC(count: 2)
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            // when
            selfClient.trustClients(users.first!.clients.union(users.last!.clients))
            selfClient.ignoreClients(users.first!.clients)

            // then
            XCTAssertEqual(conversation.securityLevel, .secureWithIgnored)
        }
    }

    func testThatItDoesNotDecreaseSecurityLevelIfItIsInPartialSecureLevel() {
        self.syncMOC.performGroupedAndWait { _ in
            // given
            let users = self.createUsersWithClientsOnSyncMOC(count: 2)
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            // when
            selfClient.trustClients(users.first!.clients.union(users.last!.clients))
            selfClient.ignoreClients(users.first!.clients)

            // then
            XCTAssertEqual(conversation.securityLevel, .secureWithIgnored)

            // and when
            selfClient.ignoreClients(users.last!.clients)

            // then we should not change the security level as we were already ignored
            XCTAssertEqual(conversation.securityLevel, .secureWithIgnored)
        }
    }

    func testThatItCorrectlySetsNeedUpdatingUsersFlagOnPotentialGapSystemMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.appendNewPotentialGapSystemMessage(users: nil, timestamp: Date())

        // then
        var fetchedMessage = ZMSystemMessage.fetchLatestPotentialGapSystemMessage(in: conversation)
        XCTAssertEqual(conversation.allMessages.count, 1)
        XCTAssertNotNil(fetchedMessage)
        XCTAssertTrue(fetchedMessage!.needsUpdatingUsers)

        // when
        conversation.updatePotentialGapSystemMessagesIfNeeded(users: Set())

        // then
        XCTAssertFalse(fetchedMessage!.needsUpdatingUsers)
        fetchedMessage = ZMSystemMessage.fetchLatestPotentialGapSystemMessage(in: conversation)
        XCTAssertEqual(conversation.allMessages.count, 1)
        XCTAssertNil(fetchedMessage)
    }

    func testThatItNotifiesWhenAllClientAreVerified() {
        var conversationObjectID: NSManagedObjectID! = nil
        var token: Any?
        self.syncMOC.performGroupedAndWait { _ in
            // given
            let users = self.createUsersWithClientsOnSyncMOC(count: 2)
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            // expect
            let expectation = self.expectation(description: "Notified")
            token = NotificationInContext.addObserver(
                name: ZMConversation.isVerifiedNotificationName,
                context: self.uiMOC.notificationContext) {
                    XCTAssertEqual($0.object as? ZMConversation, conversation)
                    if ($0.object as? ZMConversation) == conversation {
                        expectation.fulfill()
                    }
                }

            // when
            XCTAssertNotEqual(conversation.securityLevel, .secure)
            selfClient.trustClients(users.first!.clients.union(users.last!.clients))

            conversationObjectID = conversation.objectID
            self.syncMOC.saveOrRollback()
        }

        // then
        let uiConversation = try! self.uiMOC.existingObject(with: conversationObjectID!) as! ZMConversation
        XCTAssertEqual(uiConversation.securityLevel, .secure)
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        _ = String(describing: token) // so that it does not complain that is never read
    }

    func testThatIncreasesSecurityLevelOfCreatedGroupConversationWithAllParticipantsAlreadyTrusted() {

        self.syncMOC.performGroupedAndWait { _ -> Void in
            // given
            let users = self.createUsersWithClientsOnSyncMOC(count: 2)
            let clients = users.first!.clients.union(users.last!.clients)
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            selfClient.trustClients(clients)

            // when
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!
            // then
            XCTAssertEqual(conversation.securityLevel, .secure)
            guard let message = conversation.lastMessage as? ZMSystemMessage,
                let systemMessageData = message.systemMessageData else {
                return XCTFail()
            }
            XCTAssertEqual(systemMessageData.systemMessageType, .conversationIsSecure)
            XCTAssertEqual(systemMessageData.clients, clients.union([selfClient]))
        }

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDoesNotIncreaseSecurityLevelOfCreatedGroupConversationWithAllParticipantsIfNotAlreadyTrusted() {
        self.syncMOC.performGroupedAndWait { _ -> Void in
            // given
            let users = self.createUsersWithClientsOnSyncMOC(count: 2)
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            selfClient.trustClients(users.first!.clients)

            // when
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: users)!
            // then
            XCTAssertEqual(conversation.securityLevel, .notSecure)
            guard let message = conversation.lastMessage as? ZMSystemMessage else {
                return XCTFail()
            }
            XCTAssertNotEqual(message.systemMessageType, .conversationIsSecure)
        }

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }

    private var creationCounter = 1 // used to distinguish users

    func insertUser(conversation: ZMConversation, userIsTrusted: Bool, moc: NSManagedObjectContext) -> ZMUser {
        let selfClient = self.createSelfClient(onMOC: moc)
        self.uiMOC.refreshAllObjects()

        let user = ZMUser.insertNewObject(in: moc)
        user.name = "insertUser \(creationCounter)"
        self.creationCounter += 1
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        let client = UserClient.insertNewObject(in: moc)
        client.user  = user
        if userIsTrusted {
            selfClient.trustClient(client)
        } else {
            selfClient.ignoreClient(client)
        }
        return user
    }

    func testThatItReturns_HasUntrustedClients_YES_ifThereAreUntrustedClients() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group

        // when
        _ = self.insertUser(conversation: conversation, userIsTrusted: false, moc: self.uiMOC)
        let hasUntrustedClients = conversation.hasUntrustedClients

        // then
        XCTAssertTrue(hasUntrustedClients)

    }

    func testThatItReturns_HasUntrustedClients_NO_ifThereAreNoUntrustedClients() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group

        // when
        _ = self.insertUser(conversation: conversation, userIsTrusted: true, moc: self.uiMOC)
        let hasUntrustedClients = conversation.hasUntrustedClients

        // then
        XCTAssertFalse(hasUntrustedClients)
    }

    func testThatItReturns_HasUntrustedClients_NO_ifThereAreNoOtherClients() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)

        // when
        let hasUntrustedClients = conversation.hasUntrustedClients

        // then
        XCTAssertFalse(hasUntrustedClients)
    }

    func testThatItReturns_HasUntrustedClients_NO_ifThereAreNoOtherUsers() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group

        // when
        let hasUntrustedClients = conversation.hasUntrustedClients

        // then
        XCTAssertFalse(hasUntrustedClients)
    }

    func testThatItAppendsASystemMessageOfTypeRemoteIDChangedForCBErrorCodeRemoteIdentityChanged() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.name = "Fancy One"
        let decryptionError = CBOX_REMOTE_IDENTITY_CHANGED

        // when
        conversation.appendDecryptionFailedSystemMessage(at: Date(), sender: user, client: nil, errorCode: Int(decryptionError.rawValue))

        // then
        guard let lastMessage = conversation.lastMessage as? ZMSystemMessage else {
            return XCTFail()
        }
        XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageType.decryptionFailed_RemoteIdentityChanged)
        XCTAssertEqual(lastMessage.decryptionErrorCode?.intValue, Int(decryptionError.rawValue))
    }

    func testThatItAppendsASystemMessageOfGeneralTypeForCBErrorCodeInvalidMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.name = "Fancy One"
        let decryptionError = CBOX_INVALID_MESSAGE

        // when
        conversation.appendDecryptionFailedSystemMessage(at: Date(), sender: user, client: nil, errorCode: Int(decryptionError.rawValue))

        // then
        guard let lastMessage = conversation.lastMessage as? ZMSystemMessage else {
            return XCTFail()
        }
        XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageType.decryptionFailed)
        XCTAssertEqual(lastMessage.decryptionErrorCode?.intValue, Int(decryptionError.rawValue))
    }

    func testThatAConversationIsNotTrustedIfItHasNoOtherParticipants() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group

        // THEN
        XCTAssertFalse(conversation.allUsersTrusted)
    }

    func testThatAConversationIsTrustedIfItHasTeamUsers() {
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.name = "MYSELF"
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

            let mainTeam = Team.fetchOrCreate(with: UUID.create(),
                                              create: true,
                                              in: self.syncMOC,
                                              created: nil)!

            _ = Member.getOrCreateMember(for: selfUser, in: mainTeam, context: self.syncMOC)

            // WHEN
            let user = self.insertUser(conversation: conversation, userIsTrusted: true, moc: self.syncMOC)
            _ = Member.getOrCreateMember(for: user, in: mainTeam, context: self.syncMOC)

            // THEN
            XCTAssertTrue(conversation.allUsersTrusted)
        }
    }

    func testThatAConversationIsNotTrustedIfItExternalUsers() {
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group

            let selfUser = ZMUser.selfUser(in: self.syncMOC)

            let mainTeam = Team.fetchOrCreate(with: UUID.create(),
                                              create: true,
                                              in: self.syncMOC,
                                              created: nil)!

            _ = Member.getOrCreateMember(for: selfUser, in: mainTeam, context: self.syncMOC)

            // WHEN
            _ = self.insertUser(conversation: conversation, userIsTrusted: true, moc: self.syncMOC)

            // THEN
            XCTAssertFalse(conversation.allUsersTrusted)
        }
    }

    func testThatAConversationIsNotTrustedIfNotAMemberAnymore() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)
        let client = UserClient.insertNewObject(in: self.uiMOC)
        client.user = otherUser
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.selfClient()?.trustClient(client)

        // WHEN
        conversation.removeParticipantAndUpdateConversationState(user: selfUser, initiatingUser: otherUser)

        // THEN
        XCTAssertFalse(conversation.allUsersTrusted)
    }

    // MARK: - Resending / cancelling messages in degraded conversation

    func testItExpiresAllMessagesAfterTheCurrentOneWhenAUserCausesDegradation() {
        self.syncMOC.performGroupedAndWait { _ in

            // GIVEN
            self.createSelfClient()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group
            let selfUser = ZMUser.selfUser(in: self.syncMOC)

            let user = ZMUser.insertNewObject(in: self.syncMOC)
            conversation.addParticipantsAndUpdateConversationState(users: Set([user, selfUser]), role: nil)
            conversation.securityLevel = .secure

            let message1 = try! conversation.appendImage(from: self.verySmallJPEGData()) as! ZMOTRMessage
            Thread.sleep(forTimeInterval: 0.1)  // cause system time to advance
            let message2 = try! conversation.appendText(content: "foo 2") as! ZMOTRMessage

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "aabbccdd"
            client.user = user

            // WHEN
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(
                clients: Set([client]), causedBy: Set([user]))

            // THEN
            XCTAssertTrue(message1.isExpired)
            XCTAssertTrue(message1.causedSecurityLevelDegradation)
            XCTAssertTrue(message2.isExpired)
            XCTAssertTrue(message2.causedSecurityLevelDegradation)
            XCTAssertFalse(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .secureWithIgnored)
        }
    }

    func testItExpiresAllMessagesAfterTheCurrentOneWhenAMessageCausesDegradation() {
        self.syncMOC.performGroupedAndWait { _ in

            // GIVEN
            self.createSelfClient()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group
            let user = self.insertUser(conversation: conversation, userIsTrusted: true, moc: self.syncMOC)
            conversation.securityLevel = .secure

            let message1 = try! conversation.appendImage(from: self.verySmallJPEGData()) as! ZMOTRMessage
            Thread.sleep(forTimeInterval: 0.1) // cause system time to advance
            let message2 = try! conversation.appendText(content: "foo 2") as! ZMOTRMessage
            Thread.sleep(forTimeInterval: 0.1) // cause system time to advance
            let message3 = try! conversation.appendText(content: "foo 3") as! ZMOTRMessage
            Thread.sleep(forTimeInterval: 0.1) // cause system time to advance
            let message4 = try! conversation.appendText(content: "foo 4") as! ZMOTRMessage
            Thread.sleep(forTimeInterval: 0.1) // cause system time to advance
            let message5 = try! conversation.appendImage(from: self.verySmallJPEGData()) as! ZMOTRMessage

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "aabbccdd"
            client.user = user

            // WHEN
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: Set([client]), causedBy: message3)

            // THEN
            XCTAssertTrue(message1.isExpired)
            XCTAssertTrue(message1.causedSecurityLevelDegradation)
            XCTAssertTrue(message2.isExpired)
            XCTAssertTrue(message2.causedSecurityLevelDegradation)
            XCTAssertTrue(message3.isExpired)
            XCTAssertTrue(message3.causedSecurityLevelDegradation)
            XCTAssertTrue(message4.isExpired)
            XCTAssertTrue(message4.causedSecurityLevelDegradation)
            XCTAssertTrue(message5.isExpired)
            XCTAssertTrue(message5.causedSecurityLevelDegradation)
            XCTAssertFalse(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .secureWithIgnored)
        }
    }

    func testItCancelsAllMessagesThatCausedDegradation() {
        var conversation: ZMConversation! = nil
        var message1: ZMOTRMessage! = nil
        var message2: ZMOTRMessage! = nil
        var message3: ZMOTRMessage! = nil

        self.syncMOC.performGroupedAndWait { _ in

            // GIVEN
            self.createSelfClient()
            conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group
            let user = self.insertUser(conversation: conversation, userIsTrusted: true, moc: self.syncMOC)
            conversation.securityLevel = .secure

            message1 = try! conversation.appendText(content: "foo 2") as! ZMOTRMessage
            Thread.sleep(forTimeInterval: 0.1) // cause system time to advance
            message2 = try! conversation.appendText(content: "foo 3") as! ZMOTRMessage
            Thread.sleep(forTimeInterval: 0.1) // cause system time to advance
            message3 = try! conversation.appendImage(from: self.verySmallJPEGData()) as! ZMOTRMessage

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "aabbccdd"
            client.user = user
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: Set([client]), causedBy: message2)
            self.syncMOC.saveOrRollback()
        }

        // WHEN
        let uiConversation = try! self.uiMOC.existingObject(with: conversation.objectID) as! ZMConversation
        uiConversation.acknowledgePrivacyWarning(withResendIntent: false)

        self.syncMOC.performGroupedAndWait { moc in
            moc.refreshAllObjects()

            // THEN
            XCTAssertTrue(message1.isExpired)
            XCTAssertFalse(message1.causedSecurityLevelDegradation)
            XCTAssertTrue(message2.isExpired)
            XCTAssertFalse(message2.causedSecurityLevelDegradation)
            XCTAssertEqual(message2.deliveryState, .failedToSend)
            XCTAssertTrue(message3.isExpired)
            XCTAssertFalse(message3.causedSecurityLevelDegradation)
            XCTAssertEqual(message3.deliveryState, .failedToSend)
            XCTAssertFalse(conversation.allUsersTrusted)
            XCTAssertEqual(conversation.securityLevel, .notSecure)
        }
    }

    func testItMarksConversationAsNotSecureAfterResendMessages() {
        var conversation: ZMConversation! = nil
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.securityLevel = .secureWithIgnored
            self.syncMOC.saveOrRollback()
        }

        // WHEN
        let uiConversation = try! self.uiMOC.existingObject(with: conversation.objectID) as! ZMConversation
        uiConversation.acknowledgePrivacyWarning(withResendIntent: true)
        self.uiMOC.saveOrRollback()

        self.syncMOC.performGroupedAndWait { _ in
            self.syncMOC.refreshAllObjects()

            // THEN
            XCTAssertEqual(conversation.securityLevel, .notSecure)
        }
    }

    func testItResendsAllMessagesThatCausedDegradation() {
        var conversation: ZMConversation! = nil
        var message1: ZMOTRMessage! = nil
        var message2: ZMOTRMessage! = nil
        var message3: ZMOTRMessage! = nil

        self.syncMOC.performGroupedAndWait { _ in

            // GIVEN
            self.createSelfClient()
            conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group
            let user = self.insertUser(conversation: conversation, userIsTrusted: true, moc: self.syncMOC)
            conversation.securityLevel = .secure

            message1 = try! conversation.appendText(content: "foo 2") as! ZMOTRMessage
            Thread.sleep(forTimeInterval: 0.1) // cause system time to advance
            message2 = try! conversation.appendText(content: "foo 3") as! ZMOTRMessage
            Thread.sleep(forTimeInterval: 0.1) // cause system time to advance
            message3 = try! conversation.appendImage(from: self.verySmallJPEGData()) as! ZMOTRMessage

            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "aabbccdd"
            client.user = user
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: Set([client]), causedBy: message2)
            self.syncMOC.saveOrRollback()

            XCTAssertTrue(message1.isExpired)
            XCTAssertTrue(message1.causedSecurityLevelDegradation)
            XCTAssertTrue(message2.isExpired)
            XCTAssertTrue(message2.causedSecurityLevelDegradation)
            XCTAssertTrue(message3.isExpired)
            XCTAssertTrue(message3.causedSecurityLevelDegradation)
        }

        // WHEN
        let uiConversation = try! self.uiMOC.existingObject(with: conversation.objectID) as! ZMConversation
        uiConversation.acknowledgePrivacyWarning(withResendIntent: true)

        self.syncMOC.performGroupedAndWait { _ in

            // THEN
            XCTAssertFalse(message1.isExpired)
            XCTAssertFalse(message1.causedSecurityLevelDegradation)
            XCTAssertFalse(message2.isExpired)
            XCTAssertFalse(message3.causedSecurityLevelDegradation)
            XCTAssertEqual(message2.deliveryState, .pending)
            XCTAssertFalse(message3.isExpired)
            XCTAssertFalse(message3.causedSecurityLevelDegradation)
            XCTAssertEqual(message3.deliveryState, .pending)
            XCTAssertFalse(conversation.allUsersTrusted)
            XCTAssertNotEqual(conversation.securityLevel, .secure)
        }
    }

    // MARK: - Hotfix

    func testThatItUpdatesFirstNewClientSystemMessage() {
        // given
        self.createSelfClient()
        self.uiMOC.refreshAllObjects()

        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        let selfClient = selfUser.selfClient()
        let systemMessageClients = Set(arrayLiteral: selfClient)
        XCTAssertNotNil(selfClient)

        let conv = ZMConversation.insertNewObject(in: self.uiMOC)
        conv.conversationType = .oneOnOne

        let systemMessage = ZMSystemMessage(nonce: UUID.create(), managedObjectContext: self.uiMOC)
        systemMessage.visibleInConversation = conv
        systemMessage.systemMessageType = .newClient
        systemMessage.sender = selfUser
        systemMessage.clients = systemMessageClients
        systemMessage.serverTimestamp = Date()

        // when
        conv.replaceNewClientMessageIfNeededWithNewDeviceMesssage()

        // then
        XCTAssertEqual(systemMessage.systemMessageType, .usingNewDevice)
    }

    // MARK: - Add/Remove participants

    func simulateAdding(users: Set<ZMUser>, conversation: ZMConversation, by actionUser: ZMUser) -> ZMSystemMessage {

        let userIDs = users.map { $0.remoteIdentifier.transportString() }
        let data = ["user_ids": userIDs]
        let payload = self.payloadForMessage(
            in: conversation,
            type: EventConversationMemberJoin,
            data: data,
            time: Date(),
            from: actionUser
        )
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

        var result: ZMSystemMessage! = nil
        self.performPretendingUiMocIsSyncMoc {
            users.forEach {
                conversation.addParticipantAndUpdateConversationState(user: $0, role: nil)
            }
            result = ZMSystemMessage.createOrUpdate(from: event, in: conversation.managedObjectContext!, prefetchResult: nil)
        }
        return result
    }

    func simulateRemoving(users: Set<ZMUser>, conversation: ZMConversation, by actionUser: ZMUser) -> ZMSystemMessage {
        let userIDs = users.map { $0.remoteIdentifier.transportString() }
        let data = ["user_ids": userIDs]
        let payload = self.payloadForMessage(
            in: conversation,
            type: EventConversationMemberLeave,
            data: data,
            time: Date(),
            from: actionUser
        )
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

        var result: ZMSystemMessage! = nil
        self.performPretendingUiMocIsSyncMoc {
            conversation.removeParticipantsAndUpdateConversationState(users: users, initiatingUser: actionUser)
            result = ZMSystemMessage.createOrUpdate(from: event, in: conversation.managedObjectContext!, prefetchResult: nil)
        }
        return result
    }

    func setupVerifiedConversation() -> ZMConversation {
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.remoteIdentifier = UUID()
        let selfClient = self.createSelfClient(onMOC: self.uiMOC)

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        conversation.remoteIdentifier = UUID()
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

        let verifiedUser = ZMUser.insertNewObject(in: self.uiMOC)
        verifiedUser.remoteIdentifier = UUID()
        let verifiedUserConnection = ZMConnection.insertNewSentConnection(to: verifiedUser)
        verifiedUserConnection.status = .accepted

        let verifiedUserClient = UserClient.insertNewObject(in: self.uiMOC)
        verifiedUserClient.user = verifiedUser

        conversation.addParticipantAndUpdateConversationState(user: verifiedUser, role: nil)

        selfClient.trustClients(Set([verifiedUserClient]))
        conversation.increaseSecurityLevelIfNeededAfterTrusting(clients: Set([verifiedUserClient]))
        return conversation
    }

    func setupUnverifiedUsers(count: Int) -> Set<ZMUser> {

        return Set((0..<count).map { _ in
            let unverifiedUser = ZMUser.insertNewObject(in: self.uiMOC)
            let unverifiedUserConnection = ZMConnection.insertNewSentConnection(to: unverifiedUser)
            unverifiedUserConnection.status = .accepted
            unverifiedUser.remoteIdentifier = UUID()
            return unverifiedUser
        })
    }

    func testThatItDoesNotInsertDegradedMessageWhenAddingVerifiedUsers() {
        // GIVEN
        let conversation = self.setupVerifiedConversation()
        let selfUser = ZMUser.selfUser(in: self.uiMOC)

        // WHEN
        let verifiedUser = ZMUser.insertNewObject(in: self.uiMOC)
        verifiedUser.remoteIdentifier = UUID()
        let verifiedUserConnection = ZMConnection.insertNewSentConnection(to: verifiedUser)
        verifiedUserConnection.status = .accepted

        let verifiedUserClient = UserClient.insertNewObject(in: self.uiMOC)
        verifiedUserClient.user = verifiedUser
        selfUser.selfClient()!.trustClient(verifiedUserClient)

        conversation.addParticipantAndUpdateConversationState(user: verifiedUser, role: nil)

        // THEN
        guard let lastMessage1 = conversation.lastMessage as? ZMSystemMessage else {
            return XCTFail()
        }

        XCTAssertEqual(lastMessage1.systemMessageType, .conversationIsSecure)

        // WHEN
        _ = self.simulateAdding(users: Set([verifiedUser]), conversation: conversation, by: verifiedUser)

        // THEN
        guard let lastMessage2 = conversation.lastMessage as? ZMSystemMessage else {
            return XCTFail()
        }
        XCTAssertEqual(lastMessage2.systemMessageType, .participantsAdded)

    }

    func testThatItDoesNotMoveExistingDegradedMessageWhenRemoteParticpantsAdd_OtherParticipants() {
        // GIVEN
        let conversation = self.setupVerifiedConversation()
        let selfUser = ZMUser.selfUser(in: self.uiMOC)

        // WHEN
        let unverifiedUsers = self.setupUnverifiedUsers(count: 1)
        conversation.addParticipantsAndUpdateConversationState(users: unverifiedUsers, role: nil)
        let otherUnverifiedUsers = self.setupUnverifiedUsers(count: 1)

        // THEN
        XCTAssertEqual(conversation.allMessages.count, 4)
        guard let lastMessage1 = conversation.lastMessage as? ZMSystemMessage else {
            return XCTFail()
        }
        XCTAssertEqual(lastMessage1.systemMessageType, .newClient)
        XCTAssertEqual(lastMessage1.addedUsers, unverifiedUsers)

        // WHEN
        _ = self.simulateAdding(users: otherUnverifiedUsers, conversation: conversation, by: selfUser)

        // THEN
        XCTAssertEqual(conversation.allMessages.count, 5)
        guard let lastMessage2 = conversation.lastMessage as? ZMSystemMessage else {
            return XCTFail()
        }
        XCTAssertEqual(lastMessage2.systemMessageType, .participantsAdded)
    }

    func testThatAddingABlockedUserThatAlreadyIsMemberOfTheConversationDoesNotDegradeTheConversation() {
        // This happens when we are blocking a user in a 1on1: We recieve a conversation update from the backend as a response to blocking the user, which then "readds" the user. Since the user is already part of the conversation it should not degrade the conversation.

        // given
        let conversation = self.setupVerifiedConversation()
        let participant = conversation.participantRoles.first!.user!
        XCTAssertEqual(conversation.securityLevel, .secure)
        participant.connection?.status = .blocked

        // when
        conversation.addParticipantAndUpdateConversationState(user: participant, role: nil)

        // then
        XCTAssertEqual(conversation.securityLevel, .secure)
    }

    func testThatSecurityLevelIsIncreased_WhenAddingSelfUserToAnExistingConversation() {
        // given
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        self.createSelfClient(onMOC: self.uiMOC)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        conversation.remoteIdentifier = UUID()

        // when
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

        // then
        XCTAssertEqual(conversation.securityLevel, .secure)
    }

}
