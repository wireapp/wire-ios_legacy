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
import WireImages
@testable import WireDataModel

class ZMConversationMessagesTests: ZMConversationTestsBase {

    func testThatWeCanInsertATextMessage() {

        self.syncMOC.performGroupedBlockAndWait {

            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID()

            // when
            let messageText = "foo"
            let message = try! conversation.appendText(content: messageText) as! ZMMessage

            // then
            XCTAssertEqual(message.textMessageData?.messageText, messageText)
            XCTAssertEqual(message.conversation, conversation)
            XCTAssertEqual(conversation.lastMessage as! ZMMessage, message)
            XCTAssertEqual(selfUser, message.sender)
        }
    }

    func testThatItUpdatesTheLastModificationDateWhenInsertingMessagesIntoAnEmptyConversation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.lastModifiedDate = Date(timeIntervalSinceNow: -90000)

        // when
        guard let msg = try? conversation.appendText(content: "Foo") as? ZMMessage else {
            XCTFail()
            return
        }

        // then
        XCTAssertNotNil(msg.serverTimestamp)
        XCTAssertEqual(conversation.lastModifiedDate, msg.serverTimestamp)
    }

    func testThatItUpdatesTheLastModificationDateWhenInsertingMessages() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        guard let msg1 = try? conversation.appendText(content: "Foo") as? ZMMessage else {
            XCTFail()
            return
        }
        msg1.serverTimestamp = Date(timeIntervalSinceNow: -90000)
        conversation.lastModifiedDate = msg1.serverTimestamp

        // when
        guard let msg2 = try? conversation.appendImage(from: self.verySmallJPEGData()) as? ZMAssetClientMessage else {
            XCTFail()
            return
        }

        // then
        XCTAssertNotNil(msg2.serverTimestamp)
        XCTAssertEqual(conversation.lastModifiedDate, msg2.serverTimestamp)
    }

    func testThatItDoesNotUpdateTheLastModifiedDateForRenameAndLeaveSystemMessages() {
        let types = [
            ZMSystemMessageType.teamMemberLeave,
            ZMSystemMessageType.conversationNameChanged,
            ZMSystemMessageType.messageTimerUpdate
        ]

        for type in types {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            let lastModified = Date(timeIntervalSince1970: 10)
            conversation.lastModifiedDate = lastModified

            let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
            systemMessage.systemMessageType = type
            systemMessage.serverTimestamp = lastModified.addingTimeInterval(100)

            // when
            conversation.append(systemMessage)

            // then
            XCTAssertEqual(conversation.lastModifiedDate, lastModified)
        }
    }

    func testThatItIsSafeToPassInAMutableStringWhenCreatingATextMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        let originalText = "foo"
        var messageText = originalText
        let message = try! conversation.appendText(content: messageText)

        // then
        messageText.append("1234")
        XCTAssertEqual(message.textMessageData?.messageText, originalText)
    }

    func testThatWeCanInsertAnImageMessageFromAFileURL() {
        // given
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        let imageFileURL = self.fileURL(forResource: "1900x1500", extension: "jpg")!
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        let message = try! conversation.appendImage(at: imageFileURL) as! ZMAssetClientMessage

        // then
        XCTAssertNotNil(message)
        XCTAssertNotNil(message.nonce)
        XCTAssertTrue(message.imageMessageData!.originalSize.equalTo(CGSize(width: 1900, height: 1500)))
        XCTAssertEqual(message.conversation, conversation)
        XCTAssertEqual(conversation.lastMessage as! ZMMessage, message)
        XCTAssertNotNil(message.nonce)

        let expectedData = try! (try! Data(contentsOf: imageFileURL)).wr_removingImageMetadata()
        XCTAssertNotNil(expectedData)
        XCTAssertEqual(message.imageMessageData?.imageData, expectedData)
        XCTAssertEqual(selfUser, message.sender)
    }

    func testThatNoMessageIsInsertedWhenTheImageFileURLIsPointingToSomethingThatIsNotAnImage() {
        // given
        let imageFileURL = self.fileURL(forResource: "1900x1500", extension: "jpg")!
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        let message = try! conversation.appendImage(at: imageFileURL) as! ZMAssetClientMessage

        // then
        XCTAssertNotNil(message)
        XCTAssertNotNil(message.nonce)
        XCTAssertTrue(message.imageMessageData!.originalSize.equalTo(CGSize(width: 1900, height: 1500)))
        XCTAssertEqual(message.conversation, conversation)
        XCTAssertEqual(conversation.lastMessage as! ZMMessage, message)
        XCTAssertNotNil(message.nonce)

        let expectedData = try! (try! Data(contentsOf: imageFileURL)).wr_removingImageMetadata()
        XCTAssertNotNil(expectedData)
        XCTAssertEqual(message.imageMessageData?.imageData, expectedData)
    }

    func testThatNoMessageIsInsertedWhenTheImageFileURLIsNotAFileURL() {
        // given
        let imageURL = URL(string: "http://www.placehold.it/350x150")!
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        let start = self.uiMOC.insertedObjects

        // when
        var message: Any?
        self.performIgnoringZMLogError {
            message = try? conversation.appendImage(at: imageURL)
        }

        // then
        XCTAssertNil(message)
        XCTAssertEqual(start, self.uiMOC.insertedObjects)
    }

    func testThatNoMessageIsInsertedWhenTheImageFileURLIsNotPointingToAFile() {
        // given
        let textFileURL = self.fileURL(forResource: "Lorem Ipsum", extension: "txt")!
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        let start = self.uiMOC.insertedObjects

        // when
        var message: Any?
        self.performIgnoringZMLogError {
            message = try? conversation.appendImage(at: textFileURL)
        }

        // then
        XCTAssertNil(message)
        XCTAssertEqual(start, self.uiMOC.insertedObjects)
    }

    // TODO: check why fail on XCode11
    func disable_testThatWeCanInsertAnImageMessageFromImageData() {
        // given
        let imageData = try! self.data(forResource: "1900x1500", extension: "jpg").wr_removingImageMetadata()
        XCTAssertNotNil(imageData)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        guard let message = try? conversation.appendImage(from: imageData) as? ZMAssetClientMessage else {
            XCTFail()
            return
        }

        // then
        XCTAssertNotNil(message)
        XCTAssertNotNil(message.nonce)
        XCTAssertTrue(message.imageMessageData!.originalSize.equalTo(CGSize(width: 1900, height: 1500)))
        XCTAssertEqual(message.conversation, conversation)
        XCTAssertEqual(conversation.lastMessage as! ZMMessage, message)
        XCTAssertNotNil(message.nonce)
        XCTAssertEqual(message.imageMessageData?.imageData?.count, imageData.count)
    }

    // TODO: check why fail on XCode11
    func disable_testThatItIsSafeToPassInMutableDataWhenCreatingAnImageMessage() {
        // given
        let originalImageData = try! self.data(forResource: "1900x1500", extension: "jpg").wr_removingImageMetadata()
        var imageData = originalImageData
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        guard let message = try? conversation.appendImage(from: imageData) as? ZMAssetClientMessage else {
            XCTFail()
            return
        }

        // then
        imageData.append(contentsOf: [1, 2])
        XCTAssertEqual(message.imageMessageData?.imageData?.count, originalImageData.count)
    }

    func testThatNoMessageIsInsertedWhenTheImageDataIsNotAnImage() {
        // given
        let textData = self.data(forResource: "Lorem Ipsum", extension: "txt")!
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        let start = self.uiMOC.insertedObjects

        // when
        var message: ZMConversationMessage?
        self.performIgnoringZMLogError {
            message = try? conversation.appendImage(from: textData)
        }

        // then
        XCTAssertNil(message)
        XCTAssertEqual(start, self.uiMOC.insertedObjects)
    }

    func testThatLastReadUpdatesInSelfConversationDontExpire() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID()
            conversation.lastReadServerTimeStamp = Date()

            // when
            guard let message = try? ZMConversation.updateSelfConversation(withLastReadOf: conversation) else {
                XCTFail()
                return
            }

            // then
            XCTAssertNil(message.expirationDate)
        }
    }

    func testThatWeCanInsertAFileMessage() {
        // given
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileURL = URL(fileURLWithPath: documents).appendingPathComponent("secret_file.txt")
        let data = Data.randomEncryptionKey()
        let size = data.count
        try! data.write(to: fileURL)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        let fileMetaData = ZMFileMetadata(fileURL: fileURL)
        let fileMessage = try! conversation.appendFile(with: fileMetaData) as! ZMAssetClientMessage

        // then
        XCTAssertEqual(conversation.lastMessage as! ZMMessage, fileMessage)

        XCTAssertNotNil(fileMessage)
        XCTAssertNotNil(fileMessage.nonce)
        XCTAssertNotNil(fileMessage.fileMessageData)
        XCTAssertNotNil(fileMessage.underlyingMessage)
        XCTAssertNil(fileMessage.assetId)
        XCTAssertFalse(fileMessage.delivered)
        XCTAssertTrue(fileMessage.hasDownloadedFile)
        XCTAssertEqual(fileMessage.size, UInt64(size))
        XCTAssertEqual(fileMessage.progress, 0)
        XCTAssertEqual(fileMessage.filename, "secret_file.txt")
        XCTAssertEqual(fileMessage.mimeType, "text/plain")
        XCTAssertFalse(fileMessage.fileMessageData!.isVideo)
        XCTAssertFalse(fileMessage.fileMessageData!.isAudio)
    }

    func testThatWeCanNotInsertAFileMessage_WhenFileSharingIsDisabled() {
        // given
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileURL = URL(fileURLWithPath: documents).appendingPathComponent("secret_file.txt")
        let data = Data.randomEncryptionKey()
        try! data.write(to: fileURL)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        let fileSharingFeature = Feature.fetch(name: .fileSharing, context: uiMOC)
        fileSharingFeature?.status = .disabled
        let fileMetaData = ZMFileMetadata(fileURL: fileURL)

        do {
            _ = try conversation.appendFile(with: fileMetaData) as! ZMAssetClientMessage
        } catch let error as NSError {
            // then
            XCTAssertEqual(error as! ZMConversation.AppendMessageError, .fileSharingIsRestricted)
        }
     }

    func testThatWeCanInsertATextMessageWithImageQuote() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        let imageMessage = try? conversation.appendImage(from: verySmallJPEGData())

        // when
        let textMessage = try? conversation.appendText(content: "Hello World", replyingTo: imageMessage)

        // then
        XCTAssertNotNil(textMessage?.textMessageData?.quoteMessage)
        XCTAssertEqual(textMessage?.textMessageData?.quoteMessage?.nonce, imageMessage?.nonce)

    }

    func testThatWeCanInsertAPassFileMessage() {
        // given
        let filename = "ticket.pkpass"
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileURL = URL(fileURLWithPath: documents).appendingPathComponent(filename)
        let data = Data.randomEncryptionKey()
        let size = data.count
        try! data.write(to: fileURL)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        let fileMetaData = ZMFileMetadata(fileURL: fileURL)
        let fileMessage = try! conversation.appendFile(with: fileMetaData) as! ZMAssetClientMessage

        // then
        XCTAssertEqual(conversation.lastMessage as! ZMMessage, fileMessage)

        XCTAssertNotNil(fileMessage)
        XCTAssertNotNil(fileMessage.nonce)
        XCTAssertNotNil(fileMessage.fileMessageData)
        XCTAssertNotNil(fileMessage.underlyingMessage)
        XCTAssertNil(fileMessage.assetId)
        XCTAssertFalse(fileMessage.delivered)
        XCTAssertTrue(fileMessage.hasDownloadedFile)
        XCTAssertEqual(fileMessage.size, UInt64(size))
        XCTAssertEqual(fileMessage.progress, 0)
        XCTAssertEqual(fileMessage.filename, filename)
        XCTAssertEqual(fileMessage.mimeType, "application/vnd.apple.pkpass")
        XCTAssertFalse(fileMessage.fileMessageData!.isVideo)
        XCTAssertFalse(fileMessage.fileMessageData!.isAudio)
        XCTAssert(fileMessage.fileMessageData!.isPass)
    }

    func locationData() -> LocationData {
        let latitude = Float(48.53775)
        let longitude = Float(9.041169)
        let zoomLevel = Int32(16)
        let name = "天津市 နေပြည်တော် Test"
        let locationData = LocationData(latitude: latitude,
                                        longitude: longitude,
                                        name: name,
                                        zoomLevel: zoomLevel)

        return locationData
    }

    func testThatWeCanInsertALocationMessage() {
        // given
        let latitude = Float(48.53775)
        let longitude = Float(9.041169)
        let zoomLevel = Int32(16)
        let name = "天津市 နေပြည်တော် Test"
        let locationData = self.locationData()

        // when
        self.syncMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID()

            guard let message = try? conversation.appendLocation(with: locationData) as? ZMMessage else {
                XCTFail()
                return
            }

            XCTAssertEqual(conversation.lastMessage as! ZMMessage, message)

            guard let locationMessageData = message.locationMessageData else {
                XCTFail()
                return
            }
            XCTAssertEqual(locationMessageData.longitude, longitude)
            XCTAssertEqual(locationMessageData.latitude, latitude)
            XCTAssertEqual(locationMessageData.zoomLevel, zoomLevel)
            XCTAssertEqual(locationMessageData.name, name)
        }
    }

    func testThatLocationMessageHasNoImage() throws {
        // given
        let locationData = self.locationData()

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.setMessageDestructionTimeoutValue(.fiveMinutes, for: .selfUser)
        conversation.remoteIdentifier = UUID()
        // when
        let message = try conversation.appendLocation(with: locationData) as! ZMClientMessage

        // then
        XCTAssertNil(message.underlyingMessage?.imageAssetData)
        XCTAssertNotNil(message.underlyingMessage?.locationData)
        XCTAssertNotNil(message.expirationDate)
    }

    func testThatWeCanInsertAVideoMessage() {
        // given
        let fileName = "video.mp4"
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileURL = URL(fileURLWithPath: documents).appendingPathComponent(fileName)
        let videoData = Data.secureRandomData(length: 500)
        let thumbnailData = Data.secureRandomData(length: 250)
        let duration = 12333
        let dimensions = CGSize(width: 1900, height: 800)
        try! videoData.write(to: fileURL)

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        let videoMetadata = ZMVideoMetadata(fileURL: fileURL,
                                            duration: TimeInterval(duration),
                                            dimensions: dimensions,
                                            thumbnail: thumbnailData)

        guard let fileMessage = try? conversation.appendFile(with: videoMetadata) as? ZMAssetClientMessage else {
            XCTFail()
            return
        }

        // then
        XCTAssertEqual(conversation.lastMessage as! ZMMessage, fileMessage)

        XCTAssertNotNil(fileMessage)
        XCTAssertNotNil(fileMessage.nonce)
        XCTAssertNotNil(fileMessage.fileMessageData)
        XCTAssertNotNil(fileMessage.underlyingMessage)
        XCTAssertNil(fileMessage.assetId)
        XCTAssertFalse(fileMessage.delivered)
        XCTAssertTrue(fileMessage.hasDownloadedFile)
        XCTAssertEqual(fileMessage.size, UInt64(videoData.count))
        XCTAssertEqual(fileMessage.progress, 0)
        XCTAssertEqual(fileMessage.filename, fileName)
        XCTAssertEqual(fileMessage.mimeType, "video/mp4")
        guard let fileMessageData = fileMessage.fileMessageData else {
            XCTFail()
            return
        }
        XCTAssertTrue(fileMessageData.isVideo)
        XCTAssertFalse(fileMessageData.isAudio)
        XCTAssertEqual(fileMessageData.durationMilliseconds, UInt64(duration * 1000))
        XCTAssertEqual(fileMessageData.videoDimensions.height, dimensions.height)
        XCTAssertEqual(fileMessageData.videoDimensions.width, dimensions.width)
    }

    func testThatWeCanInsertAnAudioMessage() {

        // given
        let fileName = "audio.m4a"
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileURL = URL(fileURLWithPath: documents).appendingPathComponent(fileName)
        let videoData = Data.secureRandomData(length: 500)
        let thumbnailData = Data.secureRandomData(length: 250)
        let duration = 12333
        try! videoData.write(to: fileURL)

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // when
        let audioMetadata = ZMAudioMetadata(fileURL: fileURL,
                                            duration: TimeInterval(duration),
                                            normalizedLoudness: [],
                                            thumbnail: thumbnailData)

        let fileMessage = try! conversation.appendFile(with: audioMetadata) as! ZMAssetClientMessage

        // then
        XCTAssertEqual(conversation.lastMessage as! ZMMessage, fileMessage)

        XCTAssertNotNil(fileMessage)
        XCTAssertNotNil(fileMessage.nonce)
        XCTAssertNotNil(fileMessage.fileMessageData)
        XCTAssertNotNil(fileMessage.underlyingMessage)
        XCTAssertNil(fileMessage.assetId)
        XCTAssertFalse(fileMessage.delivered)
        XCTAssertTrue(fileMessage.hasDownloadedFile)
        XCTAssertEqual(fileMessage.size, UInt64(videoData.count))
        XCTAssertEqual(fileMessage.progress, 0)
        XCTAssertEqual(fileMessage.filename, fileName)
        XCTAssertEqual(fileMessage.mimeType, "audio/x-m4a")
        guard let fileMessageData = fileMessage.fileMessageData else {
            XCTFail()
            return
        }
        XCTAssertFalse(fileMessageData.isVideo)
        XCTAssertTrue(fileMessageData.isAudio)
    }

    func testThatItDoesNotFetchMessageWhenMissing() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        // WHEN
        let lastMessage = conversation.lastMessageSent(by: selfUser)

        // THEN
        XCTAssertEqual(lastMessage, nil)
    }

    func testThatItFetchesMessageForUser() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        let message = try! conversation.appendText(content: "Test Message") as! ZMMessage

        // WHEN
        let lastMessage = conversation.lastMessageSent(by: selfUser)

        // THEN
        XCTAssertEqual(lastMessage, message)
    }

    func testThatItFetchesLastMessageForUser() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        _ = try! conversation.appendText(content: "Test Message") as! ZMMessage
        let message2 = try! conversation.appendText(content: "Test Message 2") as! ZMMessage

        // WHEN
        let lastMessage = conversation.lastMessageSent(by: selfUser)

        // THEN
        XCTAssertEqual(lastMessage, message2)
    }

    func testThatItIgnoreMessagesFromOtherUsers() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()

        let message1 = try! conversation.appendText(content: "Test Message") as! ZMMessage
        message1.sender = self.createUser()

        self.uiMOC.processPendingChanges()

        // WHEN
        let lastMessage = conversation.lastMessageSent(by: selfUser)

        // THEN
        XCTAssertEqual(lastMessage, nil)
    }

    func testThatWeCanInsertAButtonActionMessage() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID()
        let buttonId = UUID().transportString()
        let messageId = UUID()

        // WHEN
        let message = try? conversation.appendButtonAction(havingId: buttonId, referenceMessageId: messageId)

        // THEN
        let expectedMessage = conversation.hiddenMessages.first
        XCTAssertEqual(message, expectedMessage)
        XCTAssertEqual(message?.underlyingMessage?.buttonAction.buttonID, buttonId)
        XCTAssertEqual(message?.underlyingMessage?.buttonAction.referenceMessageID, messageId.transportString())
    }
}
