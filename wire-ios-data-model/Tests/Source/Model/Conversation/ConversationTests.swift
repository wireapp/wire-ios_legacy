//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class ConversationTests: ZMConversationTestsBase {

    @discardableResult
    private func insertMockGroupConversation(userDefinedName: String) -> ZMConversation {
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.userDefinedName = userDefinedName
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        uiMOC.saveOrRollback()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        return conversation
    }

    func testThatItFindsConversationByUserDefinedNameDiacriticsWithSymbol() {
        // given
        let conversation = insertMockGroupConversation(userDefinedName: "Sömëbodÿ")

        // when

        let request = ZMConversation.sortedFetchRequest(with: ZMConversation.predicate(forSearchQuery: "@Sømebôdy", selfUser: selfUser))
        let result = uiMOC.executeFetchRequestOrAssert(request)

        // then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first as? ZMConversation, conversation)
    }

    func testThatItFindsConversationByUserDefinedNameDiacritics() {
        // given
        let conversation = insertMockGroupConversation(userDefinedName: "Sömëbodÿ")

        // when

        let request = ZMConversation.sortedFetchRequest(with: ZMConversation.predicate(forSearchQuery: "Sømebôdy", selfUser: selfUser))
        let result = uiMOC.executeFetchRequestOrAssert(request)

        // then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first as? ZMConversation, conversation)
    }

    func testThatItFindsConversationByUserDefinedNameWithPunctuationCharacter() {
        // given
        let conversation = insertMockGroupConversation(userDefinedName: "[Feature] [9:30]")

        // when

        let request = ZMConversation.sortedFetchRequest(with: ZMConversation.predicate(forSearchQuery: "9:3", selfUser: selfUser))
        let result = uiMOC.executeFetchRequestOrAssert(request)

        // then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first as? ZMConversation, conversation)
    }

    func testThatItFindsConversationWithQueryStringWithTrailingSpace() {
        // given
        let conversation = insertMockGroupConversation(userDefinedName: "Sömëbodÿ")

        // when

        let request = ZMConversation.sortedFetchRequest(with: ZMConversation.predicate(forSearchQuery: "Sømebôdy ", selfUser: selfUser))
        let result = uiMOC.executeFetchRequestOrAssert(request)

        // then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first as? ZMConversation, conversation)
    }

    func testThatItFindsConversationWithQueryStringWithWords() {
        // given
        let conversation = insertMockGroupConversation(userDefinedName: "Sömëbodÿ to")

        // when

        let request = ZMConversation.sortedFetchRequest(with: ZMConversation.predicate(forSearchQuery: "Sømebôdy to", selfUser: selfUser))
        let result = uiMOC.executeFetchRequestOrAssert(request)

        // then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first as? ZMConversation, conversation)
    }
}

// MARK: - LastEditableMessage

extension ConversationTests {
    func testThatItReturnsNilIfLastMessageIsEditedTextAndNotSentBySelfUser() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let sender = ZMUser.insertNewObject(in: self.uiMOC)
        sender.remoteIdentifier = UUID.create()

        // when
        let message = try! conversation.appendText(content: "Test Message") as! ZMMessage
        message.sender = sender
        message.markAsSent()

        let genericMessage = GenericMessage(content: MessageEdit(replacingMessageID: message.nonce!, text: Text(content: "Edited Test Message", mentions: [], linkPreviews: [], replyingTo: nil)), nonce: UUID.create())
        let genericMessageData = try? genericMessage.serializedData()
        let payload: NSDictionary = [
            "conversation": conversation.remoteIdentifier?.transportString(),
            "from": message.sender?.remoteIdentifier.transportString(),
            "time": Date().transportString(),
            "data": [
                "text": genericMessageData?.base64String()
            ],
            "type": "conversation.otr-message-add"
        ]
        let updateEvent = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: UUID.create())

        var newMessage: ZMClientMessage?
        self.performPretendingUiMocIsSyncMoc {
            newMessage = ZMClientMessage.createOrUpdate(from: updateEvent!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNil(conversation.lastEditableMessage)
        XCTAssertNotNil(newMessage)
    }
}

// MARK: - SelfConversationSync

extension ConversationTests {
    func testThatItUpdatesTheConversationWhenItReceivesALastReadMessage() {
        // given
        var updatedConversation: ZMConversation?
        let oldLastRead = Date()
        let newLastRead = oldLastRead.addingTimeInterval(100)

        self.syncMOC.performGroupedAndWait {_ in
            let selfUserID = ZMUser.selfUser(in: self.syncMOC).remoteIdentifier
            XCTAssertNotNil(selfUserID)

            updatedConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            updatedConversation?.remoteIdentifier = UUID.create()
            updatedConversation?.lastReadServerTimeStamp = oldLastRead

            let message = GenericMessage(content: LastRead(conversationID: updatedConversation!.remoteIdentifier!, lastReadTimestamp: newLastRead), nonce: UUID.create())
            let contentData = try? message.serializedData()
            let data = contentData?.base64EncodedString()

            let payload: NSDictionary = [
                "conversation": selfUserID?.transportString(),
                "time": newLastRead.transportString(),
                "data": data,
                "from": selfUserID?.transportString(),
                "type": "conversation.client-message-add"
            ]
            let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)

            // when
            ZMClientMessage.createOrUpdate(from: event!, in: self.syncMOC, prefetchResult: nil)
        }
        self.syncMOC.performGroupedAndWait {_ in
            // then
            XCTAssertEqual(updatedConversation!.lastReadServerTimeStamp!.timeIntervalSince1970, newLastRead.timeIntervalSince1970, accuracy: 1.5)
        }
    }

    func testThatItRemovesTheMessageWhenItReceivesAHidingMessage() {
        // given
        self.syncMOC.performGroupedAndWait {_ in

            // given
            let messageID = UUID.create()
            let selfUserID = ZMUser.selfUser(in: self.syncMOC).remoteIdentifier
            XCTAssertNotNil(selfUserID)

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            try! conversation.appendText(content: "Le fromage c'est delicieux", mentions: [], fetchLinkPreview: true, nonce: messageID)

            let message = GenericMessage(content: MessageHide(conversationId: conversation.remoteIdentifier!, messageId: messageID), nonce: UUID.create())
            let contentData = try? message.serializedData()
            let data = contentData?.base64EncodedString()

            let payload: NSDictionary = [
                "conversation": selfUserID?.transportString(),
                "time": Date().transportString(),
                "data": data,
                "from": selfUserID?.transportString(),
                "type": "conversation.client-message-add"
            ]

            let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)

            // when
            ZMClientMessage.createOrUpdate(from: event!, in: self.syncMOC, prefetchResult: nil)
            self.syncMOC.saveOrRollback()

            // then
            let fetchedMessage = ZMMessage.fetch(withNonce: messageID, for: conversation, in: self.syncMOC)
            XCTAssertNil(fetchedMessage)
        }
    }

    func testThatItRemovesImageAssetsWhenItReceivesADeletionMessage() {
        // given
        self.syncMOC.performGroupedAndWait {_ in

            // given
            let messageID = UUID.create()
            let selfUserID = ZMUser.selfUser(in: self.syncMOC).remoteIdentifier
            let imageData = Data.secureRandomData(length: 100)
            XCTAssertNotNil(selfUserID)

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            let message = try! conversation.appendImage(from: self.verySmallJPEGData(), nonce: messageID)

            // store asset data
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: ZMImageFormat.original, encrypted: false, data: imageData)
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: ZMImageFormat.preview, encrypted: false, data: imageData)
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: ZMImageFormat.medium, encrypted: false, data: imageData)
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: ZMImageFormat.preview, encrypted: true, data: imageData)
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: ZMImageFormat.medium, encrypted: true, data: imageData)

            // delete
            let deleteMessage = GenericMessage(content: MessageHide(conversationId: conversation.remoteIdentifier!, messageId: messageID), nonce: UUID.create())
            let contentData = try? deleteMessage.serializedData()
            let data = contentData?.base64EncodedString()

            let payload: NSDictionary = [
                "conversation": selfUserID?.transportString(),
                "time": Date().transportString(),
                "data": data,
                "from": selfUserID?.transportString(),
                "type": "conversation.client-message-add"
            ]
            let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)

            // when
            ZMClientMessage.createOrUpdate(from: event!, in: self.syncMOC, prefetchResult: nil)
            self.syncMOC.saveOrRollback()

            // then

            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(message, format: ZMImageFormat.original, encrypted: false))
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(message, format: ZMImageFormat.preview, encrypted: false))
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(message, format: ZMImageFormat.medium, encrypted: false))
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(message, format: ZMImageFormat.preview, encrypted: true))
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(message, format: ZMImageFormat.medium, encrypted: true))
        }
    }

    func testThatItRemovesFileAssetsWhenItReceivesADeletionMessage() {
        // given
        self.syncMOC.performGroupedAndWait {_ in

            // given
            let messageID = UUID.create()
            let selfUserID = ZMUser.selfUser(in: self.syncMOC).remoteIdentifier
            let fileData = Data.secureRandomData(length: 100)
            let fileName = "foo.bar"

            let documentsURL = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let fileURL = URL(fileURLWithPath: documentsURL).appendingPathComponent(fileName)
            do {
                try fileData.write(to: fileURL)
            } catch {
                XCTFail()
            }

            XCTAssertNotNil(selfUserID)

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()

            let fileMetadata = ZMFileMetadata.init(fileURL: fileURL, thumbnail: nil)
            let message = try! conversation.appendFile(with: fileMetadata, nonce: messageID)

            // store asset data
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, encrypted: false, data: fileData)
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, encrypted: true, data: fileData)

            // delete
            let deleteMessage = GenericMessage(content: MessageHide(conversationId: conversation.remoteIdentifier!, messageId: messageID), nonce: UUID.create())
            let contentData = try? deleteMessage.serializedData()
            let data = contentData?.base64EncodedString()

            let payload: NSDictionary = [
                "conversation": selfUserID?.transportString(),
                "time": Date().transportString(),
                "data": data,
                "from": selfUserID?.transportString(),
                "type": "conversation.client-message-add"
            ]

            let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)

            // when
            ZMClientMessage.createOrUpdate(from: event!, in: self.syncMOC, prefetchResult: nil)
            self.syncMOC.saveOrRollback()

            // re-create message with same nonce to access the cache
            let lookupMessage = try! conversation.appendText(content: "123")

            // then

            XCTAssertNil(self.syncMOC.zm_fileAssetCache .assetData(lookupMessage, encrypted: false))
            XCTAssertNil(self.syncMOC.zm_fileAssetCache .assetData(lookupMessage, encrypted: true))
        }
    }

    func testThatItDoesNotRemovesANonExistingMessageWhenItReceivesADeletionMessage() {
        self.syncMOC.performGroupedAndWait {_ in

            // given
            let selfUserID = ZMUser.selfUser(in: self.syncMOC).remoteIdentifier
            XCTAssertNotNil(selfUserID)

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()

            try! conversation.appendText(content: "Le fromage c'est delicieux", mentions: [], fetchLinkPreview: true, nonce: UUID.create())
            let previusMessagesCount = conversation.allMessages.count

            let message = GenericMessage(content: MessageHide(conversationId: conversation.remoteIdentifier!, messageId: UUID.create()), nonce: UUID.create())
            let contentData = try? message.serializedData()
            let data = contentData?.base64EncodedString()

            let payload: NSDictionary = [
                "conversation": selfUserID?.transportString(),
                "time": Date().transportString(),
                "data": data,
                "from": selfUserID?.transportString(),
                "type": "conversation.client-message-add"
            ]

            let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)

            // when
            ZMClientMessage.createOrUpdate(from: event!, in: self.syncMOC, prefetchResult: nil)
            self.syncMOC.saveOrRollback()

            // then
            XCTAssertEqual(previusMessagesCount, conversation.allMessages.count)
        }
    }

    func testThatItDoesNotRemovesAMessageWhenItReceivesADeletionMessageNotFromSelfUser() {
        // given
        self.syncMOC.performGroupedAndWait {_ in

            // given
            let messageID = UUID.create()
            let selfUserID = ZMUser.selfUser(in: self.syncMOC).remoteIdentifier
            XCTAssertNotNil(selfUserID)

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()

            try! conversation.appendText(content: "Le fromage c'est delicieux", mentions: [], fetchLinkPreview: true, nonce: messageID)
            let previusMessagesCount = conversation.allMessages.count

            let message = GenericMessage(content: MessageHide(conversationId: conversation.remoteIdentifier!, messageId: UUID.create()), nonce: UUID.create())
            let contentData = try? message.serializedData()
            let data = contentData?.base64EncodedString()

            let payload: NSDictionary = [
                "conversation": selfUserID?.transportString(),
                "time": Date().transportString(),
                "data": data,
                "from": selfUserID?.transportString(),
                "type": "conversation.client-message-add"
            ]

            let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)

            // when
            ZMClientMessage.createOrUpdate(from: event!, in: self.syncMOC, prefetchResult: nil)
            self.syncMOC.saveOrRollback()

            // then
            XCTAssertEqual(previusMessagesCount, conversation.allMessages.count)
        }
    }

    func testThatItDoesNotRemovesAMessageWhenItReceivesADeletionMessageNotInTheSelfConversation() {
        // given
        self.syncMOC.performGroupedAndWait {_ in

            // given
            let messageID = UUID.create()
            let selfUserID = ZMUser.selfUser(in: self.syncMOC).remoteIdentifier
            XCTAssertNotNil(selfUserID)

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()

            try! conversation.appendText(content: "Le fromage c'est delicieux", mentions: [], fetchLinkPreview: true, nonce: messageID)
            let previusMessagesCount = conversation.allMessages.count

            let message = GenericMessage(content: MessageHide(conversationId: conversation.remoteIdentifier!, messageId: UUID.create()), nonce: UUID.create())
            let contentData = try? message.serializedData()
            let data = contentData?.base64EncodedString()

            let payload: NSDictionary = [
                "conversation": UUID.create().transportString(),
                "time": Date().transportString(),
                "data": data,
                "from": selfUserID?.transportString(),
                "type": "conversation.client-message-add"
            ]

            let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)

            // when
            ZMClientMessage.createOrUpdate(from: event!, in: self.syncMOC, prefetchResult: nil)
            self.syncMOC.saveOrRollback()

            // then
            XCTAssertEqual(previusMessagesCount, conversation.allMessages.count)
        }
    }
}
