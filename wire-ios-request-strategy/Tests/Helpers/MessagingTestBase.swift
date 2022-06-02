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

import WireDataModel
import WireTesting
import WireCryptobox

class MessagingTestBase: ZMTBaseTest {

    var groupConversation: ZMConversation!
    fileprivate(set) var oneToOneConversation: ZMConversation!
    fileprivate(set) var selfClient: UserClient!
    fileprivate(set) var otherUser: ZMUser!
    fileprivate(set) var thirdUser: ZMUser!
    fileprivate(set) var otherClient: UserClient!
    fileprivate(set) var otherEncryptionContext: EncryptionContext!
    fileprivate(set) var coreDataStack: CoreDataStack!
    fileprivate(set) var accountIdentifier: UUID!

    let owningDomain = "example.com"

    var useInMemoryStore: Bool {
        true
    }

    var syncMOC: NSManagedObjectContext! {
        return self.coreDataStack.syncContext
    }

    var uiMOC: NSManagedObjectContext! {
        return self.coreDataStack.viewContext
    }

    var eventMOC: NSManagedObjectContext! {
        return self.coreDataStack.eventContext
    }

    override func setUp() {
        super.setUp()
        BackgroundActivityFactory.shared.activityManager = UIApplication.shared
        BackgroundActivityFactory.shared.resume()

        self.deleteAllOtherEncryptionContexts()
        self.deleteAllFilesInCache()
        self.accountIdentifier = UUID()
        self.coreDataStack = createCoreDataStack(userIdentifier: accountIdentifier,
                                                 inMemoryStore: useInMemoryStore)
        setupCaches(in: coreDataStack)
        setupTimers()

        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.zm_cryptKeyStore.deleteAndCreateNewBox()

            self.setupUsersAndClients()
            self.groupConversation = self.createGroupConversation(with: self.otherUser)
            self.oneToOneConversation = self.setupOneToOneConversation(with: self.otherUser)
            self.syncMOC.saveOrRollback()
        }
    }

    override func tearDown() {
        BackgroundActivityFactory.shared.activityManager = nil

        _ = self.waitForAllGroupsToBeEmpty(withTimeout: 10)

        self.syncMOC.performGroupedBlockAndWait {
            self.otherUser = nil
            self.otherClient = nil
            self.selfClient = nil
            self.groupConversation = nil
        }
        self.stopEphemeralMessageTimers()

        _ = self.waitForAllGroupsToBeEmpty(withTimeout: 10)

        deleteAllFilesInCache()
        deleteAllOtherEncryptionContexts()

        accountIdentifier = nil
        coreDataStack = nil

        super.tearDown()
    }
}

// MARK: - Messages 
extension MessagingTestBase {

    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    func decryptedUpdateEventFromOtherClient(text: String,
                                             conversation: ZMConversation? = nil,
                                             source: ZMUpdateEventSource = .pushNotification
        ) -> ZMUpdateEvent {

        let message = GenericMessage(content: Text(content: text))
        return self.decryptedUpdateEventFromOtherClient(message: message, conversation: conversation, source: source)
    }

    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    func decryptedUpdateEventFromOtherClient(message: GenericMessage,
                                             conversation: ZMConversation? = nil,
                                             source: ZMUpdateEventSource = .pushNotification
        ) -> ZMUpdateEvent {
        let cyphertext = self.encryptedMessageToSelf(message: message, from: self.otherClient)
        let innerPayload = ["recipient": self.selfClient.remoteIdentifier!,
                            "sender": self.otherClient.remoteIdentifier!,
                            "text": cyphertext.base64String()
        ]
        return self.decryptedUpdateEventFromOtherClient(innerPayload: innerPayload,
                                                        conversation: conversation,
                                                        source: source,
                                                        type: "conversation.otr-message-add"
        )
    }

    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    func decryptedAssetUpdateEventFromOtherClient(message: GenericMessage,
                                                  conversation: ZMConversation? = nil,
                                                  source: ZMUpdateEventSource = .pushNotification
        ) -> ZMUpdateEvent {
        let cyphertext = self.encryptedMessageToSelf(message: message, from: self.otherClient)
        let innerPayload = ["recipient": self.selfClient.remoteIdentifier!,
                            "sender": self.otherClient.remoteIdentifier!,
                            "id": UUID.create().transportString(),
                            "key": cyphertext.base64String()
        ]
        return self.decryptedUpdateEventFromOtherClient(innerPayload: innerPayload,
                                                        conversation: conversation,
                                                        source: source,
                                                        type: "conversation.otr-asset-add"
                            )
    }

    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    private func decryptedUpdateEventFromOtherClient(innerPayload: [String: Any],
                                                     conversation: ZMConversation?,
                                                     source: ZMUpdateEventSource,
                                                     type: String
        ) -> ZMUpdateEvent {
        let payload = [
            "type": type,
            "from": self.otherUser.remoteIdentifier!.transportString(),
            "data": innerPayload,
            "conversation": (conversation ?? self.groupConversation).remoteIdentifier!.transportString(),
            "time": Date().transportString()
            ] as [String: Any]
        let wrapper = [
            "id": UUID.create().transportString(),
            "payload": [payload]
            ] as [String: Any]

        let event = ZMUpdateEvent.eventsArray(from: wrapper as NSDictionary, source: source)!.first!

        var decryptedEvent: ZMUpdateEvent?
        self.selfClient.keysStore.encryptionContext.perform { session in
            decryptedEvent = session.decryptAndAddClient(event, in: self.syncMOC)
        }
        return decryptedEvent!
    }

    /// Extract the outgoing message wrapper (non-encrypted) protobuf
    func outgoingMessageWrapper(from request: ZMTransportRequest,
                                file: StaticString = #file,
                                line: UInt = #line) -> Proteus_NewOtrMessage? {
        guard let data = request.binaryData else {
            XCTFail("No binary data", file: file, line: line)
            return nil
        }
        return try? Proteus_NewOtrMessage(serializedData: data)
    }

    /// Extract encrypted payload from a request
    func outgoingEncryptedMessage(from request: ZMTransportRequest,
                                  for client: UserClient,
                                  line: UInt = #line,
                                  file: StaticString = #file
        ) -> GenericMessage? {

        guard let data = request.binaryData, let protobuf = try? Proteus_NewOtrMessage(serializedData: data) else {
            XCTFail("No binary data", file: file, line: line)
            return nil
        }

        let userEntries = protobuf.recipients.compactMap { $0 }
        guard let userEntry = userEntries.first(where: { $0.user == client.user?.userId }) else {
            XCTFail("User not found", file: file, line: line)
            return nil
        }
        // find client
        guard let clientEntry = userEntry.clients.first(where: { $0.client == client.clientId }) else {
            XCTFail("Client not found", file: file, line: line)
            return nil
        }

        // text content
        guard let plaintext = self.decryptMessageFromSelf(cypherText: clientEntry.text, to: self.otherClient) else {
            XCTFail("failed to decrypt", file: file, line: line)
            return nil
        }

        let receivedMessage = try? GenericMessage.init(serializedData: plaintext)
        return receivedMessage
    }
}

// MARK: - Internal data provisioning
extension MessagingTestBase {

    func setupOneToOneConversation(with user: ZMUser) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
        conversation.domain = owningDomain
        conversation.conversationType = .oneOnOne
        conversation.remoteIdentifier = UUID.create()
        conversation.connection = ZMConnection.insertNewObject(in: self.syncMOC)
        conversation.connection?.to = user
        conversation.connection?.status = .accepted
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        self.syncMOC.saveOrRollback()
        return conversation
    }

    /// Creates a user and a client
    func createUser(alsoCreateClient: Bool = false) -> ZMUser {
        let user = ZMUser.insertNewObject(in: self.syncMOC)
        user.remoteIdentifier = UUID.create()
        user.domain = owningDomain
        if alsoCreateClient {
            _ = self.createClient(user: user)
        }
        return user
    }

    /// Creates a new client for a user
    func createClient(user: ZMUser) -> UserClient {
        let client = UserClient.insertNewObject(in: self.syncMOC)
        client.remoteIdentifier = UUID.create().transportString()
        client.user = user
        self.syncMOC.saveOrRollback()
        return client
    }

    /// Creates a group conversation with a user
    func createGroupConversation(with user: ZMUser) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.conversationType = .group
        conversation.domain = owningDomain
        conversation.remoteIdentifier = UUID.create()
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: syncMOC), role: nil)
        conversation.needsToBeUpdatedFromBackend = false
        return conversation
    }

    /// Creates an encryption context in a temp folder and creates keys
    fileprivate func setupUsersAndClients() {

        self.otherUser = self.createUser(alsoCreateClient: true)
        self.otherClient = self.otherUser.clients.first!
        self.thirdUser = self.createUser(alsoCreateClient: true)
        self.selfClient = self.createSelfClient()

        self.syncMOC.saveOrRollback()

        self.establishSessionFromSelf(to: self.otherClient)
    }

    /// Creates self client and user
    fileprivate func createSelfClient() -> UserClient {
        let user = ZMUser.selfUser(in: self.syncMOC)
        user.remoteIdentifier = UUID.create()
        user.domain = owningDomain

        let selfClient = UserClient.insertNewObject(in: self.syncMOC)
        selfClient.remoteIdentifier = "baddeed"
        selfClient.user = user

        self.syncMOC.setPersistentStoreMetadata(selfClient.remoteIdentifier!, key: "PersistedClientId")
        selfClient.type = .permanent
        self.syncMOC.saveOrRollback()
        return selfClient
    }
}

// MARK: - Internal helpers
extension MessagingTestBase {

    func setupTimers() {
        syncMOC.performGroupedAndWait {
            $0.zm_createMessageObfuscationTimer()
        }
        uiMOC.zm_createMessageDeletionTimer()
    }

    func stopEphemeralMessageTimers() {
        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.zm_teardownMessageObfuscationTimer()
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.uiMOC.performGroupedBlockAndWait {
            self.uiMOC.zm_teardownMessageDeletionTimer()
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}

// MARK: - Contexts
extension MessagingTestBase {

    override var allDispatchGroups: [ZMSDispatchGroup] {
        return super.allDispatchGroups + [self.syncMOC?.dispatchGroup, self.uiMOC?.dispatchGroup].compactMap { $0 }
    }

    func performPretendingUiMocIsSyncMoc(block: () -> Void) {
        uiMOC.resetContextType()
        uiMOC.markAsSyncContext()
        block()
        uiMOC.resetContextType()
        uiMOC.markAsUIContext()
    }
}

// MARK: - Cache cleaning
extension MessagingTestBase {

    private var cacheFolder: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    fileprivate func deleteAllFilesInCache() {
        let files = try? FileManager.default.contentsOfDirectory(at: self.cacheFolder, includingPropertiesForKeys: [URLResourceKey.nameKey])
        files?.forEach {
            try! FileManager.default.removeItem(at: $0)
        }
    }
}

// MARK: - Payload for message
extension MessagingTestBase {
    public func payloadForMessage(in conversation: ZMConversation?,
                                  type: String,
                                  data: NSDictionary) -> NSMutableDictionary? {
        return payloadForMessage(in: conversation!, type: type, data: data, time: nil)
    }

    public func payloadForMessage(in conversation: ZMConversation,
                                  type: String,
                                  data: NSDictionary,
                                  time: Date?) -> NSMutableDictionary? {
        //      {
        //         "conversation" : "8500be67-3d7c-4af0-82a6-ef2afe266b18",
        //         "data" : {
        //            "content" : "test test",
        //            "nonce" : "c61a75f3-285b-2495-d0f6-6f0e17f0c73a"
        //         },
        //         "from" : "39562cc3-717d-4395-979c-5387ae17f5c3",
        //         "id" : "11.800122000a4ab4f0",
        //         "time" : "2014-06-22T19:57:50.948Z",
        //         "type" : "conversation.message-add"
        //      }
        let user = ZMUser.insertNewObject(in: conversation.managedObjectContext!)
        user.remoteIdentifier = UUID.create()

        return payloadForMessage(in: conversation, type: type, data: data, time: time, from: user)
    }

    public func payloadForMessage(in conversation: ZMConversation,
                                  type: String,
                                  data: NSDictionary,
                                  time: Date?,
                                  from: ZMUser) -> NSMutableDictionary? {

        return ["conversation": conversation.remoteIdentifier?.transportString() ?? "",
                "data": data,
                "from": from.remoteIdentifier.transportString(),
                "time": time?.transportString() ?? "",
                "type": type
        ]
    }

}
