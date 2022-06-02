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

import Foundation
@testable import WireDataModel

class BaseZMClientMessageTests: BaseZMMessageTests {

    var syncSelfUser: ZMUser!
    var syncUser1: ZMUser!
    var syncUser2: ZMUser!
    var syncUser3: ZMUser!

    var syncSelfClient1: UserClient!
    var syncSelfClient2: UserClient!
    var syncUser1Client1: UserClient!
    var syncUser1Client2: UserClient!
    var syncUser2Client1: UserClient!
    var syncUser2Client2: UserClient!
    var syncUser3Client1: UserClient!

    var syncConversation: ZMConversation!
    var syncExpectedRecipients: [String: [String]]!

    var user1: ZMUser!
    var user2: ZMUser!
    var user3: ZMUser!

    var selfClient1: UserClient!
    var selfClient2: UserClient!
    var user1Client1: UserClient!
    var user1Client2: UserClient!
    var user2Client1: UserClient!
    var user2Client2: UserClient!
    var user3Client1: UserClient!

    var conversation: ZMConversation!

    var expectedRecipients: [String: [String]]!

    override func setUp() {
        super.setUp()

        self.syncMOC.performGroupedBlockAndWait {
            self.syncSelfUser = ZMUser.selfUser(in: self.syncMOC)

            self.syncSelfClient1 = self.createSelfClient(onMOC: self.syncMOC)
            self.syncMOC.setPersistentStoreMetadata(self.syncSelfClient1.remoteIdentifier!, key: "PersistedClientId")

            self.syncSelfClient2 = self.createClient(for: self.syncSelfUser, createSessionWithSelfUser: true, onMOC: self.syncMOC)

            self.syncUser1 = ZMUser.insertNewObject(in: self.syncMOC)
            self.syncUser1Client1 = self.createClient(for: self.syncUser1, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            self.syncUser1Client2 = self.createClient(for: self.syncUser1, createSessionWithSelfUser: true, onMOC: self.syncMOC)

            self.syncUser2 = ZMUser.insertNewObject(in: self.syncMOC)
            self.syncUser2Client1 = self.createClient(for: self.syncUser2, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            self.syncUser2Client2 = self.createClient(for: self.syncUser2, createSessionWithSelfUser: false, onMOC: self.syncMOC)

            self.syncUser3 = ZMUser.insertNewObject(in: self.syncMOC)
            self.syncUser3Client1 = self.createClient(for: self.syncUser3, createSessionWithSelfUser: false, onMOC: self.syncMOC)

            self.syncConversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [self.syncUser1!, self.syncUser2!, self.syncUser3!])

            self.syncConversation.remoteIdentifier = UUID.create()

            self.expectedRecipients = [
                self.syncSelfUser.remoteIdentifier!.transportString(): [
                    self.syncSelfClient2.remoteIdentifier!
                ],
                self.syncUser1.remoteIdentifier!.transportString(): [
                    self.syncUser1Client1.remoteIdentifier!,
                    self.syncUser1Client2.remoteIdentifier!
                ],
                self.syncUser2.remoteIdentifier!.transportString(): [
                    self.syncUser2Client1.remoteIdentifier!
                ]
            ]

            self.syncMOC.saveOrRollback()
        }

        self.uiMOC.refreshAllObjects()

        self.selfUser = try! self.uiMOC.existingObject(with: self.syncSelfUser.objectID) as! ZMUser
        self.selfClient1 = try! self.uiMOC.existingObject(with: self.syncSelfClient1.objectID) as! UserClient
        self.uiMOC.setPersistentStoreMetadata(self.selfClient1.remoteIdentifier!, key: "PersistedClientId")

        self.selfClient2 = try! self.uiMOC.existingObject(with: self.syncSelfClient2.objectID) as! UserClient

        self.user1 = try! self.uiMOC.existingObject(with: self.syncUser1.objectID) as! ZMUser
        self.user1Client1 = try! self.uiMOC.existingObject(with: self.syncUser1Client1.objectID) as! UserClient
        self.user1Client2 = try! self.uiMOC.existingObject(with: self.syncUser1Client2.objectID) as! UserClient

        self.user2 = try! self.uiMOC.existingObject(with: self.syncUser2.objectID) as! ZMUser
        self.user2Client1 = try! self.uiMOC.existingObject(with: self.syncUser2Client1.objectID) as! UserClient
        self.user2Client2 = try! self.uiMOC.existingObject(with: self.syncUser2Client2.objectID) as! UserClient

        self.user3 = try! self.uiMOC.existingObject(with: self.syncUser3.objectID) as! ZMUser
        self.user3Client1 = try! self.uiMOC.existingObject(with: self.syncUser3Client1.objectID) as! UserClient

        self.conversation = try! self.uiMOC.existingObject(with: self.syncConversation.objectID) as! ZMConversation
        self.expectedRecipients = [
            self.selfUser.remoteIdentifier!.transportString(): [
                self.selfClient2.remoteIdentifier!
            ],
            self.user1.remoteIdentifier!.transportString(): [
                self.user1Client1.remoteIdentifier!,
                self.user1Client2.remoteIdentifier!
            ],
            self.user2.remoteIdentifier!.transportString(): [
                self.user2Client1.remoteIdentifier!
            ]
        ]
    }

    override func tearDown() {
        syncMOC.performGroupedBlockAndWait {
            self.syncMOC.setPersistentStoreMetadata(nil as String?, key: "PersistedClientId")
        }
        wipeCaches()
        self.syncSelfUser = nil
        self.syncUser1 = nil
        self.syncUser2 = nil
        self.syncUser3 = nil

        self.syncSelfClient1 = nil
        self.syncSelfClient2 = nil
        self.syncUser1Client1 = nil
        self.syncUser1Client2 = nil
        self.syncUser2Client1 = nil
        self.syncUser2Client2 = nil
        self.syncUser3Client1 = nil

        self.syncConversation = nil
        self.syncExpectedRecipients = nil

        self.user1 = nil
        self.user2 = nil
        self.user3 = nil

        self.selfClient1 = nil
        self.selfClient2 = nil
        self.user1Client1 = nil
        self.user1Client2 = nil
        self.user2Client1 = nil
        self.user2Client2 = nil
        self.user3Client1 = nil

        self.conversation = nil

        self.expectedRecipients = nil
        super.tearDown()
    }

    func assertRecipients(_ recipients: [Proteus_UserEntry], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(recipients.count, expectedRecipients.count, file: file, line: line)

        for recipientEntry in recipients {
            guard let uuid = UUID(data: recipientEntry.user.uuid) else {
                XCTFail("Missing user UUID", file: file, line: line)
                return
            }
            guard let expectedClientsIds: [String] = self.expectedRecipients[uuid.transportString()]?.sorted() else {
                XCTFail("Unexpected otr client in recipients", file: file, line: line)
                return
            }
            let clientIds = (recipientEntry.clients).map { String(format: "%llx", $0.client.client) }.sorted()
            XCTAssertEqual(clientIds, expectedClientsIds, file: file, line: line)
            let hasTexts = (recipientEntry.clients).map { $0.hasText }
            XCTAssertFalse(hasTexts.contains(false), file: file, line: line)

        }
    }

    func createUpdateEvent(_ nonce: UUID, conversationID: UUID, timestamp: Date = .init(), genericMessage: GenericMessage, senderID: UUID = .create(), senderClientID: String = UUID().transportString(), eventSource: ZMUpdateEventSource = .download) -> ZMUpdateEvent {
        let data = try? genericMessage.serializedData().base64String()
        return createUpdateEvent(nonce,
                                 conversationID: conversationID,
                                 timestamp: timestamp,
                                 genericMessageData: data ?? "",
                                 senderID: senderID,
                                 senderClientID: senderClientID,
                                 eventSource: eventSource)
    }

    private func createUpdateEvent(_ nonce: UUID, conversationID: UUID, timestamp: Date, genericMessageData: String, senderID: UUID, senderClientID: String, eventSource: ZMUpdateEventSource) -> ZMUpdateEvent {
        let payload: [String: Any] = [
            "conversation": conversationID.transportString(),
            "from": senderID.transportString(),
            "time": timestamp.transportString(),
            "data": [
                "text": genericMessageData,
                "sender": senderClientID
            ],
            "type": "conversation.otr-message-add"
        ]
        switch eventSource {
        case .download:
            return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nonce)!
        default:
            let streamPayload = ["payload": [payload],
                                 "id": UUID.create()] as [String: Any]
            let event = ZMUpdateEvent.eventsArray(from: streamPayload as ZMTransportData,
                                                  source: eventSource)!.first!
            XCTAssertNotNil(event)
            return event
        }
    }
}
