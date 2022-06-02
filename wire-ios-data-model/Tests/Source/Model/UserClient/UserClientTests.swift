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

import XCTest
import WireUtilities
import WireCryptobox
@testable import WireDataModel

final class UserClientTests: ZMBaseManagedObjectTest {

    func clientWithTrustedClientCount(_ trustedCount: UInt, ignoredClientCount: UInt, missedClientCount: UInt) -> UserClient {
        let client = UserClient.insertNewObject(in: self.uiMOC)

        func userClientSetWithClientCount(_ count: UInt) -> Set<UserClient>? {
            guard count != 0 else { return nil }

            var clients = Set<UserClient>()
            for _ in 0..<count {
                clients.insert(UserClient.insertNewObject(in: uiMOC))
            }
            return clients
        }

        let trustedClient = userClientSetWithClientCount(trustedCount)
        let ignoredClient = userClientSetWithClientCount(ignoredClientCount)
        let missedClient = userClientSetWithClientCount(missedClientCount)

        if let trustedClient = trustedClient { client.trustedClients = trustedClient }
        if let ignoredClient = ignoredClient { client.ignoredClients = ignoredClient }
        client.missingClients = missedClient

        return client
    }

    func testThatItCanInitializeClient() {
        let client = UserClient.insertNewObject(in: self.uiMOC)
        XCTAssertEqual(client.type, .permanent, "Client type should be 'permanent'")
    }

    func testThatItReturnsTrackedKeys() {
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let trackedKeys = client.keysTrackedForLocalModifications()
        XCTAssertTrue(trackedKeys.contains(ZMUserClientMarkedToDeleteKey), "")
        XCTAssertTrue(trackedKeys.contains(ZMUserClientNumberOfKeysRemainingKey), "")
    }

    func testThatItSyncClientsWithNoRemoteIdentifier() {
        let unsyncedClient = UserClient.insertNewObject(in: self.uiMOC)
        let syncedClient = UserClient.insertNewObject(in: self.uiMOC)
        syncedClient.remoteIdentifier = "synced"

        XCTAssertTrue(UserClient.predicateForObjectsThatNeedToBeInsertedUpstream()!.evaluate(with: unsyncedClient))
        XCTAssertFalse(UserClient.predicateForObjectsThatNeedToBeInsertedUpstream()!.evaluate(with: syncedClient))
    }

    func testThatClientCanBeMarkedForDeletion() {
        let client = UserClient.insertNewObject(in: self.uiMOC)
        client.user = ZMUser.selfUser(in: self.uiMOC)

        XCTAssertFalse(client.markedToDelete)
        client.markForDeletion()

        XCTAssertTrue(client.markedToDelete)
        XCTAssertTrue(client.hasLocalModifications(forKey: ZMUserClientMarkedToDeleteKey))
    }

    func testThatItTracksCorrectKeys() {
        let expectedKeys = Set(arrayLiteral: ZMUserClientMarkedToDeleteKey,
                               ZMUserClientNumberOfKeysRemainingKey,
                               ZMUserClientMissingKey,
                               ZMUserClientNeedsToUpdateSignalingKeysKey,
                               ZMUserClientNeedsToUpdateCapabilitiesKey)

        let client = UserClient.insertNewObject(in: self.uiMOC)
        XCTAssertEqual(client.keysTrackedForLocalModifications(), expectedKeys)
    }

    func testThatTrustingClientsRemovesThemFromIgnoredClientList() {

        let client = clientWithTrustedClientCount(0, ignoredClientCount: 2, missedClientCount: 0)

        let ignoredClient = client.ignoredClients.first!

        client.trustClients(Set(arrayLiteral: ignoredClient))

        XCTAssertFalse(client.ignoredClients.contains(ignoredClient))
        XCTAssertTrue(client.trustedClients.contains(ignoredClient))
    }

    func testThatIgnoringClientsRemovesThemFromTrustedList() {

        let client = clientWithTrustedClientCount(2, ignoredClientCount: 1, missedClientCount: 0)

        let trustedClient = client.trustedClients.first!

        client.ignoreClients(Set(arrayLiteral: trustedClient))

        XCTAssertFalse(client.trustedClients.contains(trustedClient))
        XCTAssertTrue(client.ignoredClients.contains(trustedClient))
    }

    func testThatTrustingClientsRemovesTheNeedToNotifyUser() {
        // Given
        let client = clientWithTrustedClientCount(0, ignoredClientCount: 1, missedClientCount: 0)
        let ignoredClient = client.ignoredClients.first!
        ignoredClient.needsToNotifyUser = true

        // When
        client.trustClient(ignoredClient)

        // Then
        XCTAssertFalse(ignoredClient.needsToNotifyUser)
    }

    func testThatItDeletesASession() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                preKeys = try! sessionsDirectory.generatePrekeys(0 ..< 2)
            })

            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            otherClient.user = ZMUser.insertNewObject(in: self.syncMOC)
            otherClient.user?.remoteIdentifier = UUID.create()

            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return
            }

            XCTAssertTrue(selfClient.establishSessionWithClient(otherClient, usingPreKey: preKey.prekey))
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)

            // when
            UserClient.deleteSession(for: otherClient.sessionIdentifier!, managedObjectContext: self.syncMOC)

            // then
            XCTAssertFalse(otherClient.hasSessionWithSelfClient)
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItDeletesASessionWhenDeletingAClient() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                preKeys = try! sessionsDirectory.generatePrekeys(0 ..< 2)
            })

            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser

            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return
            }

            XCTAssertTrue(selfClient.establishSessionWithClient(otherClient, usingPreKey: preKey.prekey))
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)
            let clientId = otherClient.sessionIdentifier!

            // when
            otherClient.deleteClientAndEndSession()

            // then
            selfClient.keysStore.encryptionContext.perform {
                XCTAssertFalse($0.hasSession(for: clientId))
            }
            XCTAssertFalse(otherClient.hasSessionWithSelfClient)
            XCTAssertTrue(otherClient.isZombieObject)
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItUpdatesConversationSecurityLevelWhenDeletingClient() {

        self.syncMOC.performGroupedBlockAndWait {
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            let otherClient1 = UserClient.insertNewObject(in: self.syncMOC)
            otherClient1.remoteIdentifier = UUID.create().transportString()

            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient1.user = otherUser
            let connection = ZMConnection.insertNewSentConnection(to: otherUser)
            connection.status = .accepted

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group

            conversation.addParticipantsAndUpdateConversationState(
                users: Set([otherUser, ZMUser.selfUser(in: self.syncMOC)]),
                role: nil)

            selfClient.trustClient(otherClient1)

            conversation.securityLevel = ZMConversationSecurityLevel.notSecure
            XCTAssertEqual(conversation.allMessages.count, 1)

            let otherClient2 = UserClient.insertNewObject(in: self.syncMOC)
            otherClient2.remoteIdentifier = UUID.create().transportString()
            otherClient2.user = otherUser

            selfClient.ignoreClient(otherClient2)

            // when
            otherClient2.deleteClientAndEndSession()
            self.syncMOC.saveOrRollback()

            // then
            XCTAssertTrue(otherClient2.isZombieObject)
            XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevel.secure)
            XCTAssertEqual(conversation.allMessages.count, 2)
            if let message = conversation.lastMessage as? ZMSystemMessage {
                XCTAssertEqual(message.systemMessageType, ZMSystemMessageType.conversationIsSecure)
                XCTAssertEqual(message.users, Set(arrayLiteral: otherUser))
            } else {
                XCTFail("Did not insert systemMessage")
            }
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatWhenDeletingClientItTriggersUserFetchForPossibleMemberLeave() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()

            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser

            let team = self.createTeam(in: self.syncMOC)
            _ = self.createMembership(in: self.syncMOC, user: otherUser, team: team)

            otherUser.needsToBeUpdatedFromBackend = false

            XCTAssertTrue(otherUser.isTeamMember)
            XCTAssertFalse(otherUser.needsToBeUpdatedFromBackend)

            // when
            otherClient.deleteClientAndEndSession()

            // then
            XCTAssertTrue(otherClient.isZombieObject)
            XCTAssertTrue(otherUser.clients.isEmpty)
            XCTAssertTrue(otherUser.needsToBeUpdatedFromBackend)
        }

        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItRefetchesMissingFingerprintForUserWithSession() {
        // given
        let otherClientId = UUID.create()

        self.syncMOC.performGroupedBlockAndWait {
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                preKeys = try! sessionsDirectory.generatePrekeys(0 ..< 2)
            })

            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = otherClientId.transportString()
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser

            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return }

            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                try! sessionsDirectory.createClientSession(otherClient.sessionIdentifier!, base64PreKeyString: preKey.prekey)
            })

            XCTAssertNil(otherClient.fingerprint)
            otherClient.managedObjectContext?.saveOrRollback()
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.syncMOC.performGroupedBlockAndWait {
            let fetchRequest = NSFetchRequest<UserClient>(entityName: UserClient.entityName())
            fetchRequest.predicate = NSPredicate(format: "%K == %@", "remoteIdentifier", otherClientId.transportString())
            fetchRequest.fetchLimit = 1
            // when
            do {
                let fetchedClient = try self.syncMOC.fetch(fetchRequest).first
                XCTAssertNotNil(fetchedClient)
                XCTAssertNotNil(fetchedClient!.fingerprint)
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testThatItSetsNeedsToNotifyOtherUserAboutSessionReset_WhenResettingSession() {
        var otherClient: UserClient!

        // given
        self.syncMOC.performGroupedBlockAndWait {
            _ = self.createSelfClient(onMOC: self.syncMOC)

            otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()

            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser

            let connection = ZMConnection.insertNewSentConnection(to: otherUser)
            connection.status = .accepted
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.syncMOC.performGroupedBlockAndWait {
            otherClient.resetSession()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(otherClient.needsToNotifyOtherUserAboutSessionReset)
        }
    }

    func testThatItAsksForMoreWhenRunningOutOfPrekeys() {

        self.syncMOC.performGroupedBlockAndWait {
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            selfClient.numberOfKeysRemaining = 1

            // when
            selfClient.decrementNumberOfRemainingKeys()

            // then
            XCTAssertTrue(selfClient.modifiedKeys!.contains(ZMUserClientNumberOfKeysRemainingKey))
        }
    }

    func testThatItDoesntAskForMoreWhenItStillHasPrekeys() {

        self.syncMOC.performGroupedBlockAndWait {
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            selfClient.numberOfKeysRemaining = 2

            // when
            selfClient.decrementNumberOfRemainingKeys()

            // then
            XCTAssertNil(selfClient.modifiedKeys)
        }
    }
}

extension UserClientTests {
    func testThatItStoresFailedToEstablishSessionInformation() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let client = UserClient.insertNewObject(in: self.syncMOC)

            // when & then
            XCTAssertFalse(client.failedToEstablishSession)

            // when
            client.failedToEstablishSession = true

            // then
            XCTAssertTrue(client.failedToEstablishSession)

            // when
            client.failedToEstablishSession = false

            // then
            XCTAssertFalse(client.failedToEstablishSession)
        }
    }
}

extension UserClientTests {

    func testThatSelfClientIsTrusted() {
        // given & when
        let selfClient = self.createSelfClient()

        // then
        XCTAssertTrue(selfClient.verified)
    }

    func testThatSelfClientIsStillVerifiedAfterIgnoring() {
        // given
        let selfClient = self.createSelfClient()

        // when
        selfClient.ignoreClient(selfClient)

        // then
        XCTAssertTrue(selfClient.verified)
    }

    func testThatUnknownClientIsNotVerified() {
        // given & when
        self.createSelfClient()

        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        otherClient.remoteIdentifier = NSString.createAlphanumerical()

        // then
        XCTAssertFalse(otherClient.verified)
    }

    func testThatItIsVerifiedWhenTrusted() {
        // given
        let selfClient = self.createSelfClient()

        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        otherClient.remoteIdentifier = NSString.createAlphanumerical()

        // when
        selfClient.trustClient(otherClient)

        // then
        XCTAssertTrue(otherClient.verified)
    }

    func testThatItIsNotVerifiedWhenIgnored() {
        // given
        let selfClient = createSelfClient()

        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        otherClient.remoteIdentifier = NSString.createAlphanumerical()

        // when
        selfClient.ignoreClient(otherClient)

        // then
        XCTAssertFalse(otherClient.verified)
    }
}

// MARK: SignalingStore

extension UserClientTests {

    func testThatItDeletesExistingSignalingKeys() {

        // given
        let selfClient = createSelfClient()
        selfClient.apsVerificationKey =  Data()
        selfClient.apsDecryptionKey = Data()

        XCTAssertNotNil(selfClient.apsVerificationKey)
        XCTAssertNotNil(selfClient.apsDecryptionKey)

        // when
        UserClient.resetSignalingKeysInContext(self.uiMOC)

        // then
        XCTAssertNil(selfClient.apsVerificationKey)
        XCTAssertNil(selfClient.apsDecryptionKey)
    }

    func testThatItSetsKeysNeedingToBeSynced() {

        // given
        let selfClient = createSelfClient()

        // when
        UserClient.resetSignalingKeysInContext(self.uiMOC)

        // then
        XCTAssertTrue(selfClient.needsToUploadSignalingKeys)
        XCTAssertTrue(selfClient.keysThatHaveLocalModifications.contains(ZMUserClientNeedsToUpdateSignalingKeysKey))
    }

}

// MARK: Capabilities

extension UserClientTests {

    func testThatItSetsKeysNeedingToBeSynced_Capabilities() {
        // given
        let selfClient = createSelfClient()

        // when
        UserClient.triggerSelfClientCapabilityUpdate(self.uiMOC)

        // then
        XCTAssertTrue(selfClient.needsToUpdateCapabilities)
        XCTAssertTrue(selfClient.keysThatHaveLocalModifications.contains(ZMUserClientNeedsToUpdateCapabilitiesKey))
    }

}

// MARK: fetchFingerprintOrPrekeys

extension UserClientTests {

    func testThatItSetsTheUserWhenInsertingANewSelfUserClient() {
        // given
        _ = createSelfClient()
        let newClientPayload: [String: AnyObject] = ["id": UUID().transportString() as AnyObject,
                                                       "type": "permanent" as AnyObject,
                                                       "time": Date().transportString() as AnyObject]
        // when
        var newClient: UserClient!
        self.performPretendingUiMocIsSyncMoc {
            newClient = UserClient.createOrUpdateSelfUserClient(newClientPayload, context: self.uiMOC)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        XCTAssertNotNil(newClient)
        XCTAssertNotNil(newClient.user)
        XCTAssertEqual(newClient.user, ZMUser.selfUser(in: uiMOC))
        XCTAssertNotNil(newClient.sessionIdentifier)
    }

    func testThatItSetsTheUserWhenInsertingANewSelfUserClient_NoExistingSelfClient() {
        // given
        let newClientPayload: [String: AnyObject] = ["id": UUID().transportString() as AnyObject,
                                                       "type": "permanent" as AnyObject,
                                                       "time": Date().transportString() as AnyObject]
        // when
        var newClient: UserClient!
        self.performPretendingUiMocIsSyncMoc {
            newClient = UserClient.createOrUpdateSelfUserClient(newClientPayload, context: self.uiMOC)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        XCTAssertNotNil(newClient)
        XCTAssertNotNil(newClient.user)
        XCTAssertEqual(newClient.user, ZMUser.selfUser(in: uiMOC))
        XCTAssertNil(newClient.sessionIdentifier)
    }

    func testThatItSetsNeedsSessionMigration_WhenInsertingANewSelfUserClientAndDomainIsNil() {
        // given
        _ = createSelfClient()
        let newClientPayload: [String: AnyObject] = ["id": UUID().transportString() as AnyObject,
                                                       "type": "permanent" as AnyObject,
                                                       "time": Date().transportString() as AnyObject]
        // when
        var newClient: UserClient!
        self.performPretendingUiMocIsSyncMoc {
            newClient = UserClient.createOrUpdateSelfUserClient(newClientPayload, context: self.uiMOC)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        XCTAssertTrue(newClient.needsSessionMigration)
    }

    func testThatItSetsNeedsSessionMigration_WhenInsertingANewSelfUserClientAndDomainIsSet() {
        // given
        _ = createSelfClient()
        ZMUser.selfUser(in: uiMOC).domain = "example.com"

        let newClientPayload: [String: AnyObject] = ["id": UUID().transportString() as AnyObject,
                                                       "type": "permanent" as AnyObject,
                                                       "time": Date().transportString() as AnyObject]
        // when
        var newClient: UserClient!
        self.performPretendingUiMocIsSyncMoc {
            newClient = UserClient.createOrUpdateSelfUserClient(newClientPayload, context: self.uiMOC)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        XCTAssertFalse(newClient.needsSessionMigration)
    }

    func testThatItDoNothingWhenHasAFingerprint() {
        // GIVEN
        let fingerprint = Data(base64Encoded: "cmVhZGluZyB0ZXN0cyBpcyBjb29s")

        let client = UserClient.insertNewObject(in: self.uiMOC)
        client.fingerprint = fingerprint

        self.uiMOC.saveOrRollback()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))

        // WHEN
        client.fetchFingerprintOrPrekeys()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))

        // THEN
        XCTAssertTrue(client.keysThatHaveLocalModifications.isEmpty)
        XCTAssertEqual(client.fingerprint, fingerprint)
    }

    func testThatItLoadsFingerprintForSelfClient() {

        // GIVEN
        var selfClient: UserClient!
        var newFingerprint: Data?

        self.syncMOC.performGroupedBlockAndWait {

            selfClient = self.createSelfClient(onMOC: self.syncMOC)
            selfClient.fingerprint = .none

            self.syncMOC.zm_cryptKeyStore.encryptionContext.perform { (sessionsDirectory) in
                newFingerprint = sessionsDirectory.localFingerprint
            }

            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            selfClient.fetchFingerprintOrPrekeys()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(selfClient.keysThatHaveLocalModifications.isEmpty)
            XCTAssertEqual(selfClient.fingerprint!, newFingerprint)
        }
    }

    func testThatItLoadsFingerprintForExistingSession() {
        var client: UserClient!

        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            var preKeys : [(id: UInt16, prekey: String)] = []

            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                preKeys = try! sessionsDirectory.generatePrekeys(0 ..< 2)
            })

            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return }

            client = UserClient.insertNewObject(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            client.user = otherUser
            client.remoteIdentifier = "badf00d"

            self.syncMOC.zm_cryptKeyStore.encryptionContext.perform { (sessionsDirectory) in
                try! sessionsDirectory.createClientSession(client.sessionIdentifier!, base64PreKeyString: preKey.prekey)
            }

            // WHEN
            client.fetchFingerprintOrPrekeys()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(client.keysThatHaveLocalModifications.isEmpty)
            XCTAssertNotEqual(client.fingerprint!.count, 0)
        }
    }

    func testThatItMarksMissingWhenNoSession() {
        var client: UserClient!
        var selfClient: UserClient!

        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            selfClient = self.createSelfClient(onMOC: self.syncMOC)
            client = UserClient.insertNewObject(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            client.user = otherUser
            client.remoteIdentifier = "badf00d"

            self.syncMOC.saveOrRollback()

            // WHEN
            client.fetchFingerprintOrPrekeys()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(selfClient.hasLocalModifications(forKey: ZMUserClientMissingKey))
            XCTAssertEqual(client.fingerprint, .none)
        }
    }

    func testThatItCreatesUserClientIfNeeded() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            // WHEN
            let client = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // THEN
            XCTAssertNotNil(client)
            XCTAssertEqual(client?.remoteIdentifier, "badf00d")
            XCTAssertEqual(client?.user, otherUser)
        }
    }

    func testThatItSetsNeedsToMigrateSession_WhenCreatingUserClientAndDomainIsNil() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            // WHEN
            let client = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // THEN
            XCTAssertEqual(client?.needsSessionMigration, true)
        }
    }

    func testThatItSetsNeedsToMigrateSession_WhenCreatingUserClientAndDomainIsSet() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherUser.domain = "example.com"
            // WHEN
            let client = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // THEN
            XCTAssertEqual(client?.needsSessionMigration, false)
        }
    }

    func testThatItFetchesUserClientWithoutSave() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            // WHEN
            let client1 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)
            let client2 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // THEN
            XCTAssertNotNil(client1)
            XCTAssertNotNil(client2)

            XCTAssertEqual(client1, client2)
        }
    }

    func testThatItFetchesUserClient_OtherMOC() {
        var clientSync: UserClient?
        let userUI = ZMUser.insertNewObject(in: self.uiMOC)
        userUI.remoteIdentifier = UUID.create()

        self.uiMOC.saveOrRollback()

        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let userSync = try! self.syncMOC.existingObject(with: userUI.objectID) as! ZMUser
            // WHEN
            clientSync = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: userSync, createIfNeeded: true)
            clientSync?.label = "test"
            // THEN
            XCTAssertNotNil(clientSync)
            self.syncMOC.saveOrRollback()
        }

        // WHEN
        let clientUI: UserClient? = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: userUI, createIfNeeded: false)

        // THEN
        XCTAssertNotNil(clientUI)
        XCTAssertEqual(clientUI?.remoteIdentifier, "badf00d")
        XCTAssertEqual(clientUI?.label, "test")
    }

    func testThatItFetchesUserClientWithSave() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            // WHEN
            let client1 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // AND THEN
            self.syncMOC.saveOrRollback()

            // WHEN
            let client2 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // THEN
            XCTAssertNotNil(client1)
            XCTAssertNotNil(client2)

            XCTAssertEqual(client1, client2)
        }
    }
}

// MARK: - Update from payload

extension UserClientTests {

    func testThatItUpdatesDeviceClassFromPayload() {
        // given
        let allCases: [DeviceClass] = [.desktop, .phone, .tablet, .legalHold]
        let client = UserClient.insertNewObject(in: uiMOC)
        client.user = createUser(in: uiMOC)

        for deviceClass in allCases {
            // when
            client.update(with: ["class": deviceClass.rawValue])

            // then
            XCTAssertEqual(client.deviceClass, deviceClass)
        }
    }

    func testThatItSelfClientsAreNotUpdatedFromPayload() {
        // given
        let deviceClass = DeviceClass.desktop
        let selfClient = createSelfClient()

        // when
        selfClient.update(with: ["class": deviceClass.rawValue])

        // then
        XCTAssertNotEqual(selfClient.deviceClass, deviceClass)
    }

    func testThatItResetsNeedsToBeUpdatedFromBackend() {
        // given
        let client = UserClient.insertNewObject(in: uiMOC)
        client.user = createUser(in: uiMOC)
        client.needsToBeUpdatedFromBackend = true

        // when
        client.update(with: [:])

        // then
        XCTAssertFalse(client.needsToBeUpdatedFromBackend)
    }

}

// MARK: - Session Identifier

extension UserClientTests {

    func testThatItReturnsCorrectSessionIdentifier_WhenSessionNeedsMigration() {
        // given
        let user = createUser(in: uiMOC)

        let client = UserClient.insertNewObject(in: uiMOC)
        let clientID = UUID().uuidString
        client.remoteIdentifier = clientID
        client.user = user
        client.needsSessionMigration = true

        let userID = client.user!.remoteIdentifier.uuidString
        let expectedSessionIdentifier = EncryptionSessionIdentifier(userId: userID,
                                                                    clientId: clientID)

        // when
        let sessionIdentifier = client.sessionIdentifier

        // then
        XCTAssertEqual(sessionIdentifier, expectedSessionIdentifier)
    }

    func testThatItReturnsCorrectSessionIdentifier_WhenSessionDoesNotNeedMigration() {
        // given
        let domain = UUID().uuidString
        let user = createUser(in: uiMOC)
        user.domain = domain

        let client = UserClient.insertNewObject(in: uiMOC)
        let clientID = UUID().uuidString
        client.remoteIdentifier = clientID
        client.user = user
        client.needsSessionMigration = false

        let userID = client.user!.remoteIdentifier.uuidString
        let expectedSessionIdentifier = EncryptionSessionIdentifier(domain: domain,
                                                                    userId: userID,
                                                                    clientId: clientID)

        // when
        let sessionIdentifier = client.sessionIdentifier

        // then
        XCTAssertEqual(sessionIdentifier, expectedSessionIdentifier)
    }

    func testThatItMigratesSessionIdentifierFromV2ToV3_WhenUserDomainIsAvailable() {
        syncMOC.performGroupedBlockAndWait { [self] in
            // given
            let selfClient = createSelfClient(onMOC: syncMOC)

            let otherClient = UserClient.insertNewObject(in: syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            let otherUser = ZMUser.insertNewObject(in: syncMOC)
            let otherUserID = UUID().create()
            otherUser.remoteIdentifier = otherUserID
            otherClient.user = otherUser
            otherClient.needsSessionMigration = true

            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform { sessionsDirectory in
                preKeys = try! sessionsDirectory.generatePrekeys(0 ..< 2)
            }

            guard let preKey = preKeys.first else {
                XCTFail("could not generate prekeys")
                return
            }

            let userID = otherUserID.uuidString
            let clientID = otherClient.remoteIdentifier!
            let otherUserDomain = UUID().uuidString

            let v2SessionIdentifier = EncryptionSessionIdentifier(userId: userID,
                                                                  clientId: clientID)
            let v3SessionIdentifier = EncryptionSessionIdentifier(domain: otherUserDomain,
                                                                  userId: userID,
                                                                  clientId: clientID)

            XCTAssertTrue(selfClient.establishSessionWithClient(otherClient, usingPreKey: preKey.prekey))
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)

            selfClient.keysStore.encryptionContext.perform { sessionsDirectory in
                XCTAssertTrue(sessionsDirectory.hasSession(for: v2SessionIdentifier))
                XCTAssertFalse(sessionsDirectory.hasSession(for: v3SessionIdentifier))
            }

            otherUser.domain = otherUserDomain

            selfClient.keysStore.encryptionContext.perform { sessionsDirectory in
                // when
                otherClient.migrateSessionIdentifierFromV2IfNeeded(sessionDirectory: sessionsDirectory)

                // then
                XCTAssertFalse(sessionsDirectory.hasSession(for: v2SessionIdentifier))
                XCTAssertTrue(sessionsDirectory.hasSession(for: v3SessionIdentifier))
            }
        }

    }

    func testThatItDoesNotMigrateSessionIdentifierFromV2ToV3_WhenUserDomainIsUnavailable() {
        self.syncMOC.performGroupedBlockAndWait { [self] in
            // given
            let selfClient = createSelfClient(onMOC: syncMOC)

            let otherClient = UserClient.insertNewObject(in: syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            let otherUser = ZMUser.insertNewObject(in: syncMOC)
            let otherUserID = UUID().create()
            otherUser.remoteIdentifier = otherUserID
            otherClient.user = otherUser
            otherClient.needsSessionMigration = true

            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform { sessionsDirectory in
                preKeys = try! sessionsDirectory.generatePrekeys(0 ..< 2)
            }

            guard let preKey = preKeys.first else {
                XCTFail("could not generate prekeys")
                return
            }

            let userID = otherUserID.uuidString
            let clientID = otherClient.remoteIdentifier!

            let v2SessionIdentifier = EncryptionSessionIdentifier(userId: userID,
                                                                  clientId: clientID)

            XCTAssertTrue(selfClient.establishSessionWithClient(otherClient, usingPreKey: preKey.prekey))
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)

            otherClient.keysStore.encryptionContext.perform { sessionsDirectory in
                XCTAssertTrue(sessionsDirectory.hasSession(for: v2SessionIdentifier))

                // when
                otherClient.migrateSessionIdentifierFromV2IfNeeded(sessionDirectory: sessionsDirectory)

                // then
                XCTAssertTrue(sessionsDirectory.hasSession(for: v2SessionIdentifier))
            }
        }
    }
}
