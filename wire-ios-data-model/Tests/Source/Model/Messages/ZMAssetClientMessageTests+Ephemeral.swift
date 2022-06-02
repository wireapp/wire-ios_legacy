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

class ZMAssetClientMessageTests_Ephemeral: BaseZMAssetClientMessageTests {

    override func setUp() {
        super.setUp()
        deletionTimer?.isTesting = true
        syncMOC.performGroupedBlockAndWait {
            self.obfuscationTimer?.isTesting = true
        }
    }

    override func tearDown() {
        syncMOC.performGroupedBlockAndWait {
            self.syncMOC.zm_teardownMessageObfuscationTimer()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        uiMOC.performGroupedBlockAndWait {
            self.uiMOC.zm_teardownMessageDeletionTimer()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        super.tearDown()
    }

    var obfuscationTimer: ZMMessageDestructionTimer? {
        return syncMOC.zm_messageObfuscationTimer
    }

    var deletionTimer: ZMMessageDestructionTimer? {
        return uiMOC.zm_messageDeletionTimer
    }

}

// MARK: Sending
extension ZMAssetClientMessageTests_Ephemeral {

    func testThatItInsertsAnEphemeralMessageForAssets() {
        // given
        conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
        let fileMetadata = createFileMetadata()

        // when
        let message = try! conversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage

        // then
        guard case .ephemeral? = message.underlyingMessage!.content else {
            return XCTFail()
        }
        XCTAssertTrue(message.underlyingMessage!.hasAsset)
        XCTAssertTrue(message.underlyingMessage!.ephemeral.hasAsset)
        XCTAssertEqual(message.underlyingMessage!.ephemeral.expireAfterMillis, Int64(10*1000))
    }

    func assetWithImage() -> WireProtos.Asset {
        let original = WireProtos.Asset.Original(withSize: 1000, mimeType: "image", name: "foo")
        let remoteData = WireProtos.Asset.RemoteData(withOTRKey: Data(), sha256: Data(), assetId: "id", assetToken: "token")
        let imageMetaData = WireProtos.Asset.ImageMetaData(width: 30, height: 40)
        let preview = WireProtos.Asset.Preview(size: 2000, mimeType: "video", remoteData: remoteData, imageMetadata: imageMetaData)
        let asset = WireProtos.Asset(original: original, preview: preview)
        return asset
    }

    func thumbnailEvent(for message: ZMAssetClientMessage) -> ZMUpdateEvent {
        let data = try? message.underlyingMessage?.serializedData().base64String()
        let payload: [String: Any] = [
            "id": UUID.create(),
            "conversation": conversation.remoteIdentifier!.transportString(),
            "from": selfUser.remoteIdentifier!.transportString(),
            "time": Date().transportString(),
            "data": [
                "id": "fooooo",
                "text": data ?? ""
            ],
            "type": "conversation.otr-message-add"
        ]
        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID())!
    }

    func testThatWhenUpdatingTheThumbnailAssetIDWeReplaceAnEphemeralMessageWithAnEphemeral() {
        // given
        conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
        let fileMetadata = createFileMetadata()

        // when
        let message = try! conversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage
        let event = thumbnailEvent(for: message)
        message.update(with: event, initialUpdate: true)

        // then
        guard case .ephemeral? = message.underlyingMessage!.content else {
            return XCTFail()
        }
        XCTAssertTrue(message.underlyingMessage!.ephemeral.hasAsset)
        XCTAssertEqual(message.underlyingMessage!.ephemeral.expireAfterMillis, Int64(10*1000))
    }

    func testThatItStartsTheTimerForMultipartMessagesWhenTheAssetIsUploaded() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
            let fileMetadata = self.createFileMetadata()
            let message = try! self.syncConversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage

            // when
            message.update(withPostPayload: [:], updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))

            // then
            XCTAssertEqual(self.obfuscationTimer?.runningTimersCount, 1)
            XCTAssertEqual(self.obfuscationTimer?.isTimerRunning(for: message), true)
        }
    }

    func testThatItExtendsTheObfuscationTimer() {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!

        // given
        self.syncMOC.performGroupedBlockAndWait {
            // set timeout
            self.syncConversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)

            // send file
            let fileMetadata = self.createFileMetadata()
            message = try! self.syncConversation.appendFile(with: fileMetadata) as? ZMAssetClientMessage
            message.update(withPostPayload: [:], updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))

            // check a timer was started
            oldTimer = self.obfuscationTimer?.timer(for: message)
            XCTAssertNotNil(oldTimer)
        }

        // when timer extended by 5 seconds
        self.syncMOC.performGroupedBlockAndWait {
            message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 15))
        }

        // then a new timer was created
        self.syncMOC.performGroupedBlockAndWait {
            let newTimer = self.obfuscationTimer?.timer(for: message)
            XCTAssertNotEqual(oldTimer, newTimer)
        }
    }

    func testThatItDoesNotExtendTheObfuscationTimerWhenNewDateIsEarlier() {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!

        // given
        self.syncMOC.performGroupedBlockAndWait {
            // set timeout
            self.syncConversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)

            // send file
            let fileMetadata = self.createFileMetadata()
            message = try! self.syncConversation.appendFile(with: fileMetadata) as? ZMAssetClientMessage
            message.update(withPostPayload: [:], updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))

            // check a timer was started
            oldTimer = self.obfuscationTimer?.timer(for: message)
            XCTAssertNotNil(oldTimer)
        }

        // when timer "extended" 5 seconds earlier
        self.syncMOC.performGroupedBlockAndWait {
            message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 5))
        }

        // then no new timer created
        self.syncMOC.performGroupedBlockAndWait {
            let newTimer = self.obfuscationTimer?.timer(for: message)
            XCTAssertEqual(oldTimer, newTimer)
        }
    }
}

// MARK: Receiving

extension ZMAssetClientMessageTests_Ephemeral {

    func testThatItStartsATimerForImageAssetMessagesIfTheMessageIsAMessageOfTheOtherUser() throws {
        // given
        conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()

        let fileMetadata = self.createFileMetadata()
        let message = try! conversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage
        message.sender = sender
        try message.setUnderlyingMessage(GenericMessage(content: WireProtos.Asset(withUploadedOTRKey: Data(), sha256: Data()), nonce: message.nonce!))
        XCTAssertTrue(message.underlyingMessage!.assetData!.hasUploaded)

        // when
        XCTAssertTrue(message.startSelfDestructionIfNeeded())

        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 1)
        XCTAssertEqual(self.deletionTimer?.isTimerRunning(for: message), true)
    }

    func testThatItStartsATimerIfTheMessageIsAMessageOfTheOtherUser() throws {
        // given
        conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()

        let nonce = UUID()
        let message = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        message.sender = sender
        message.visibleInConversation = conversation

        let imageData = verySmallJPEGData()
        let assetMessage = GenericMessage(content: WireProtos.Asset(imageSize: .zero, mimeType: "", size: UInt64(imageData.count)), nonce: nonce, expiresAfter: .tenSeconds)
        try message.setUnderlyingMessage(assetMessage)

        let uploaded = GenericMessage(content: WireProtos.Asset(withUploadedOTRKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key()), nonce: message.nonce!, expiresAfter: conversation.activeMessageDestructionTimeoutValue)
        try message.setUnderlyingMessage(uploaded)

        // when
        XCTAssertTrue(message.startSelfDestructionIfNeeded())

        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 1)
        XCTAssertEqual(self.deletionTimer?.isTimerRunning(for: message), true)
    }

    func appendPreviewImageMessage() -> ZMAssetClientMessage {
        let imageData = verySmallJPEGData()
        let message = ZMAssetClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        conversation.append(message)

        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size: imageSize, length: UInt(imageData.count), mimeType: "image/jpeg")
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(),
                                              macKey: Data.zmRandomSHA256Key(),
                                              mac: Data.zmRandomSHA256Key())

        let imageMessage = GenericMessage(content: ImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: .preview))

        do {
            try message.setUnderlyingMessage(imageMessage)
        } catch {
            XCTFail()
        }

        return message
    }

    func testThatItDoesNotStartsATimerIfTheMessageIsAMessageOfTheOtherUser_NoMediumImage() {
        // given
        conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()

        let message = appendPreviewImageMessage()
        message.sender = sender

        // when
        XCTAssertFalse(message.startSelfDestructionIfNeeded())

        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 0)
        XCTAssertEqual(self.deletionTimer?.isTimerRunning(for: message), false)
    }

    func testThatItDoesNotStartATimerIfTheMessageIsAMessageOfTheOtherUser_NotUploadedYet() {
        // given
        conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()

        let fileMetadata = self.createFileMetadata()
        let message = try! conversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage
        message.sender = sender
        XCTAssertFalse(message.underlyingMessage!.assetData!.hasUploaded)

        // when
        XCTAssertFalse(message.startSelfDestructionIfNeeded())

        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 0)
        XCTAssertEqual(self.deletionTimer?.isTimerRunning(for: message), false)
    }

    func testThatItStartsATimerIfTheMessageIsAMessageOfTheOtherUser_UploadCancelled() throws {
        // given
        conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()

        let fileMetadata = self.createFileMetadata()
        let message = try! conversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage
        message.sender = sender
        try message.setUnderlyingMessage(GenericMessage(content: WireProtos.Asset(withNotUploaded: .cancelled), nonce: message.nonce!))
        XCTAssertTrue(message.underlyingMessage!.assetData!.hasNotUploaded)

        // when
        XCTAssertTrue(message.startSelfDestructionIfNeeded())

        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 1)
        XCTAssertEqual(self.deletionTimer?.isTimerRunning(for: message), true)
    }

    func testThatItDoesNotStartATimerForAMessageOfTheSelfuser() throws {
        // given
        conversation.setMessageDestructionTimeoutValue(.custom(0.1), for: .selfUser)
        let fileMetadata = self.createFileMetadata()
        let message = try! conversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage
        try message.setUnderlyingMessage(GenericMessage(content: WireProtos.Asset(withUploadedOTRKey: Data(), sha256: Data()), nonce: message.nonce!))
        XCTAssertTrue(message.underlyingMessage!.assetData!.hasUploaded)

        // when
        XCTAssertFalse(message.startDestructionIfNeeded())

        // then
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 0)
    }

    func testThatItCreatesADeleteForAllMessageWhenTheTimerFires() throws {
        // given
        conversation.setMessageDestructionTimeoutValue(.custom(0.1), for: .selfUser)

        let fileMetadata = self.createFileMetadata()
        let message = try! conversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage
        conversation.conversationType = .oneOnOne
        message.sender = ZMUser.insertNewObject(in: uiMOC)
        message.sender?.remoteIdentifier = UUID.create()
        try message.setUnderlyingMessage(GenericMessage(content: WireProtos.Asset(withUploadedOTRKey: Data(), sha256: Data()), nonce: message.nonce!))
        XCTAssertTrue(message.underlyingMessage!.assetData!.hasUploaded)

        // when
        XCTAssertTrue(message.startDestructionIfNeeded())
        XCTAssertEqual(self.deletionTimer?.runningTimersCount, 1)

        spinMainQueue(withTimeout: 0.5)

        // then
        guard let deleteMessage = conversation.hiddenMessages.first(where: { $0 is ZMClientMessage }) as? ZMClientMessage else { return XCTFail()}

        guard let genericMessage = deleteMessage.underlyingMessage,
            case .deleted? = genericMessage.content else {
                return XCTFail()
        }

        XCTAssertNotEqual(deleteMessage, message)
        XCTAssertNotNil(message.sender)
        XCTAssertNil(message.underlyingMessage)
        XCTAssertEqual(message.dataSet.count, 0)
        XCTAssertNil(message.destructionDate)
    }

    func testThatItExtendsTheDeletionTimer() throws {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!

        // given
        self.conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)

        // send file
        let fileMetadata = self.createFileMetadata()
        message = try! self.conversation.appendFile(with: fileMetadata) as? ZMAssetClientMessage
        message.sender = ZMUser.insertNewObject(in: self.uiMOC)
        message.sender?.remoteIdentifier = UUID.create()

        try message.setUnderlyingMessage(GenericMessage(content: WireProtos.Asset(withUploadedOTRKey: Data(), sha256: Data()), nonce: message.nonce!))
        XCTAssertTrue(message.underlyingMessage!.assetData!.hasUploaded)

        // check a timer was started
        XCTAssertTrue(message.startDestructionIfNeeded())
        oldTimer = self.deletionTimer?.timer(for: message)
        XCTAssertNotNil(oldTimer)

        // when timer extended by 5 seconds
        message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 15))

        // force a wait so timer map is updated
        _ = wait(withTimeout: 0.5, verificationBlock: { return false })

        // then a new timer was created
        let newTimer = self.deletionTimer?.timer(for: message)
        XCTAssertNotEqual(oldTimer, newTimer)
    }

    func testThatItDoesNotExtendTheDeletionTimerWhenNewDateIsEarlier() throws {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!

        // given
        self.conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)

        // send file
        let fileMetadata = self.createFileMetadata()
        message = try! self.conversation.appendFile(with: fileMetadata) as? ZMAssetClientMessage
        message.sender = ZMUser.insertNewObject(in: self.uiMOC)
        message.sender?.remoteIdentifier = UUID.create()

        try message.setUnderlyingMessage(GenericMessage(content: WireProtos.Asset(withUploadedOTRKey: Data(), sha256: Data()), nonce: message.nonce!))
        XCTAssertTrue(message.underlyingMessage!.assetData!.hasUploaded)

        // check a timer was started
        XCTAssertTrue(message.startDestructionIfNeeded())
        oldTimer = self.deletionTimer?.timer(for: message)
        XCTAssertNotNil(oldTimer)

        // when timer "extended" by 5 seconds earlier
        message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 5))

        // force a wait so timer map is updated
        _ = wait(withTimeout: 0.5, verificationBlock: { return false })

        // then a new timer was created
        let newTimer = self.deletionTimer?.timer(for: message)
        XCTAssertEqual(oldTimer, newTimer)
    }
}
