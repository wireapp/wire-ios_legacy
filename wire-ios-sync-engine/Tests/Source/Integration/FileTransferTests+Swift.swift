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

import XCTest
@testable import WireSyncEngine

class FileTransferTests_Swift: ConversationTestsBase {
    func remotelyInsertAssetOriginalAndUpdate(updateMessage: GenericMessage,
                                              insertBlock: @escaping (_ data: Data, _ conversation: MockConversation, _ from: MockUserClient, _ to: MockUserClient) -> Void,
                                              nonce: UUID) -> ZMAssetClientMessage? {
        return remotelyInsertAssetOriginalWithMimeType(mimeType: "text/plain", updateMessage: updateMessage, insertBlock: insertBlock, nonce: nonce, isEphemeral: false)
    }

    func remotelyInsertAssetOriginalWithMimeType(mimeType: String,
                                                 updateMessage: GenericMessage,
                                                 insertBlock: @escaping (_ data: Data, _ conversation: MockConversation, _ from: MockUserClient, _ to: MockUserClient) -> Void,
                                                 nonce: UUID,
                                                 isEphemeral: Bool) -> ZMAssetClientMessage? {

        // given
        let selfClient = self.selfUser.clients.anyObject() as! MockUserClient
        let senderClient = self.user1.clients.anyObject()  as! MockUserClient
        let mockConversation = self.selfToUser1Conversation

        XCTAssertNotNil(selfClient)
        XCTAssertNotNil(senderClient)

        let asset = WireProtos.Asset(original: WireProtos.Asset.Original(withSize: 256, mimeType: mimeType, name: "foo229"), preview: nil)
        let original = GenericMessage(content: asset, nonce: nonce, expiresAfterTimeInterval: isEphemeral ? 20 : 0)

        // when
        self.mockTransportSession.performRemoteChanges { (_) in
            mockConversation!.encryptAndInsertData(from: senderClient,
                                                   to: selfClient,
                                                   data: try! original.serializedData())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let conversation = self.conversation(for: self.selfToUser1Conversation)

        if !conversation!.lastMessage!.isKind(of: ZMAssetClientMessage.self) {
            XCTFail(String(format: "Unexpected message type, expected ZMAssetClientMessage : %@", (conversation!.lastMessage as! ZMMessage).self))
            return nil
        }

        let message = conversation?.lastMessage as! ZMAssetClientMessage as ZMAssetClientMessage
        XCTAssertEqual(message.size, 256)
        XCTAssertEqual(message.mimeType, mimeType)
        XCTAssertEqual(message.nonce, nonce)

        // perform update

        self.mockTransportSession.performRemoteChanges { (_) in
            let updateMessageData = MockUserClient.encrypted(data: try! updateMessage.serializedData(), from: senderClient, to: selfClient)
            insertBlock(updateMessageData, mockConversation!, senderClient, selfClient)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        return message
    }
}

// MARK: Asset V2 - Downloading

extension FileTransferTests_Swift {

    func testThatItSendsTheRequestToDownloadAFile_WhenItHasTheAssetID() {
        // given
        XCTAssertTrue(self.login())

        let nonce = UUID.create()
        let token = UUID.create()
        let assetID = UUID.create()
        let otrKey = Data.randomEncryptionKey()

        let assetData = Data.secureRandomData(length: 256)
        let encryptedAsset = assetData.zmEncryptPrefixingPlainTextIV(key: otrKey)
        let sha256 = encryptedAsset.zmSHA256Digest()

        let remoteData = WireProtos.Asset.RemoteData(withOTRKey: otrKey,
                                                     sha256: sha256,
                                                     assetId: assetID.transportString(),
                                                     assetToken: nil)
        let asset = WireProtos.Asset.with {
            $0.uploaded = remoteData
        }

        let uploaded = GenericMessage(content: asset, nonce: nonce)

        // when
        let message = self.remotelyInsertAssetOriginalAndUpdate(updateMessage: uploaded, insertBlock: { (data, conversation, from, to) in
            conversation.insertOTRMessage(from: from, to: to, data: data)
        }, nonce: nonce)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // creating the asset remotely
        self.mockTransportSession.performRemoteChanges { (session) in
            session.insertAsset(with: assetID, assetToken: token, assetData: encryptedAsset, contentType: "text/plain")
        }

        // then
        XCTAssertEqual(message?.downloadState, AssetDownloadState.remote)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.mockTransportSession.resetReceivedRequests()
        self.userSession?.perform {
            message?.requestFileDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message!.downloadState, AssetDownloadState.downloaded)
    }

    func testThatItSendsTheRequestToDownloadAFileWhenItHasTheAssetID_AndSetsTheStateTo_FailedDownload_AfterFailedDecryption() {
        // given
        XCTAssertTrue(self.login())

        let nonce = UUID.create()
        let assetID = UUID.create()
        let otrKey = Data.randomEncryptionKey()

        let assetData = Data.secureRandomData(length: 256)
        let encryptedAsset = assetData.zmEncryptPrefixingPlainTextIV(key: otrKey)
        let sha256 = encryptedAsset.zmSHA256Digest()

        let uploaded = GenericMessage(content: WireProtos.Asset(withUploadedOTRKey: otrKey, sha256: sha256), nonce: nonce)

        // when
        let message = self.remotelyInsertAssetOriginalAndUpdate(updateMessage: uploaded, insertBlock: { (data, conversation, from, to) in
            conversation.insertOTRAsset(from: from, to: to, metaData: data, imageData: assetData, assetId: assetID, isInline: false)
        }, nonce: nonce)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let conversation = self.conversation(for: self.selfToUser1Conversation)

        // creating a wrong asset (different hash, will fail to decrypt) remotely
        self.mockTransportSession.performRemoteChanges { (session) in
            session.createAsset(with: Data.secureRandomData(length: 128),
                                identifier: assetID.transportString(),
                                contentType: "text/plain",
                                forConversation: conversation!.remoteIdentifier!.transportString())
        }

        // We no longer process incoming V2 assets so we need to manually set some properties to simulate having received the asset
        self.userSession?.perform {
            message!.version = 2
            message!.assetId = assetID
            message!.updateTransferState(AssetTransferState.uploaded, synchronize: false)
        }

        // then
        XCTAssertEqual(message!.assetId, assetID) // We should have received an asset ID to be able to download the file
        XCTAssertEqual(message!.nonce, nonce)
        XCTAssertEqual(message!.transferState, AssetTransferState.uploaded)
        XCTAssertEqual(message!.downloadState, AssetDownloadState.remote)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.performIgnoringZMLogError {
            self.userSession?.perform {
                message?.requestFileDownload()
            }
            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        let lastRequest = self.mockTransportSession.receivedRequests().last! as ZMTransportRequest
        let expectedPath = String(format: "/conversations/%@/otr/assets/%@", conversation!.remoteIdentifier!.transportString(), message!.assetId!.transportString())
        XCTAssertEqual(lastRequest.path, expectedPath)
        XCTAssertEqual(message!.downloadState, AssetDownloadState.remote)
    }

    func testThatItSendsTheRequestToDownloadAFileWhenItHasTheAssetID_AndSetsTheStateTo_FailedDownload_AfterFailedDecryption_Ephemeral() {
        // given
        XCTAssertTrue(self.login())

        let nonce = UUID.create()
        let assetID = UUID.create()
        let otrKey = Data.randomEncryptionKey()

        let assetData = Data.secureRandomData(length: 256)
        let encryptedAsset = assetData.zmEncryptPrefixingPlainTextIV(key: otrKey)
        let sha256 = encryptedAsset.zmSHA256Digest()

        let uploaded = GenericMessage(content: WireProtos.Asset(withUploadedOTRKey: otrKey, sha256: sha256), nonce: nonce, expiresAfterTimeInterval: 30)

        // when
        let message = self.remotelyInsertAssetOriginalAndUpdate(updateMessage: uploaded, insertBlock: { (data, conversation, from, to) in
            conversation.insertOTRAsset(from: from, to: to, metaData: data, imageData: assetData, assetId: assetID, isInline: false)
        }, nonce: nonce)

        XCTAssertTrue(message!.isEphemeral)

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let conversation = self.conversation(for: self.selfToUser1Conversation)

        // creating a wrong asset (different hash, will fail to decrypt) remotely
        self.mockTransportSession.performRemoteChanges { (session) in
            session.createAsset(with: Data.secureRandomData(length: 128),
                                identifier: assetID.transportString(),
                                contentType: "text/plain",
                                forConversation: conversation!.remoteIdentifier!.transportString())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // We no longer process incoming V2 assets so we need to manually set some properties to simulate having received the asset
        self.userSession?.perform {
            message!.version = 2
            message!.assetId = assetID
            message!.updateTransferState(AssetTransferState.uploaded, synchronize: false)
        }

        // then
        XCTAssertEqual(message!.nonce, nonce)
        XCTAssertEqual(message!.transferState, AssetTransferState.uploaded)
        XCTAssertEqual(message!.downloadState, AssetDownloadState.remote)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        self.userSession?.perform {
            message?.requestFileDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let lastRequest = self.mockTransportSession.receivedRequests().last! as ZMTransportRequest
         let expectedPath = String(format: "/conversations/%@/otr/assets/%@", conversation!.remoteIdentifier!.transportString(), message!.assetId!.transportString())
        XCTAssertEqual(lastRequest.path, expectedPath)
        XCTAssertEqual(message!.downloadState, AssetDownloadState.remote)
        XCTAssertTrue(message!.isEphemeral)
    }
}

// MARK: Asset V3 - Receiving

extension FileTransferTests_Swift {

    func testThatAFileUpload_AssetOriginal_MessageIsReceivedWhenSentRemotely_Ephemeral() {
        // given
        XCTAssertTrue(self.login())

        self.establishSession(with: self.user1)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let nonce = UUID.create()
        let original = GenericMessage(content: WireProtos.Asset(imageSize: .zero, mimeType: "text/plain", size: 256), nonce: nonce, expiresAfterTimeInterval: 30)

        // when
        self.mockTransportSession.performRemoteChanges { (_) in
            self.selfToUser1Conversation.encryptAndInsertData(from: self.user1.clients.anyObject() as! MockUserClient,
                                                              to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                          data: try! original.serializedData())
               }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let conversation = self.conversation(for: self.selfToUser1Conversation)

        if !conversation!.lastMessage!.isKind(of: ZMAssetClientMessage.self) {
            return XCTFail(String(format: "Unexpected message type, expected ZMAssetClientMessage : %@", (conversation!.lastMessage as! ZMMessage).self))
        }

        let message = conversation?.lastMessage as! ZMAssetClientMessage
        XCTAssertTrue(message.isEphemeral)

        XCTAssertEqual(message.size, 256)
        XCTAssertEqual(message.mimeType, "text/plain")
        XCTAssertEqual(message.nonce, nonce)
        XCTAssertNil(message.assetId)
        XCTAssertEqual(message.transferState, AssetTransferState.uploading)
    }

    func testThatItDeletesAFileMessageWhenTheUploadIsCancelledRemotely_Ephemeral() {
        // given
        XCTAssertTrue(self.login())

        let nonce = UUID.create()
        let cancelled = GenericMessage(content: WireProtos.Asset(withNotUploaded: .cancelled), nonce: nonce, expiresAfterTimeInterval: 30)

        // when
        let message = self.remotelyInsertAssetOriginalAndUpdate(updateMessage: cancelled, insertBlock: { (data, conversation, from, to) in
            conversation.insertOTRMessage(from: from, to: to, data: data)
               }, nonce: nonce)

        // then
        XCTAssertTrue(message!.isZombieObject)
    }

    func testThatItUpdatesAFileMessageWhenTheUploadFailesRemotlely_Ephemeral() {
        // given
        XCTAssertTrue(self.login())

        let nonce = UUID.create()
        let failed = GenericMessage(content: WireProtos.Asset(withNotUploaded: .failed), nonce: nonce, expiresAfterTimeInterval: 30)

        // when
        let message = self.remotelyInsertAssetOriginalAndUpdate(updateMessage: failed, insertBlock: { (data, conversation, from, to) in
                   conversation.insertOTRMessage(from: from, to: to, data: data)
                      }, nonce: nonce)
        XCTAssertTrue(message!.isEphemeral)

        // then
        XCTAssertNil(message!.assetId)
        XCTAssertEqual(message!.transferState, AssetTransferState.uploadingFailed)
        XCTAssertTrue(message!.isEphemeral)
    }

    func testThatItReceivesAVideoFileMessageThumbnailSentRemotely_V3() {
        // given
        XCTAssertTrue(self.login())

        let nonce = UUID.create()
        let thumbnailAssetID = UUID.create()
        let thumbnailIDString = thumbnailAssetID.transportString()
        let otrKey = Data.randomEncryptionKey()
        let encryptedAsset = self.mediumJPEGData().zmEncryptPrefixingPlainTextIV(key: otrKey)
        let sha256 = encryptedAsset.zmSHA256Digest()

        let remote = WireProtos.Asset.RemoteData(withOTRKey: otrKey, sha256: sha256, assetId: thumbnailIDString, assetToken: nil)
        let image = WireProtos.Asset.ImageMetaData(width: 1024, height: 2048)
        let preview = WireProtos.Asset.Preview(size: 256,
                                               mimeType: "image/jpeg",
                                               remoteData: remote,
                                               imageMetadata: image)
        let asset = WireProtos.Asset(original: nil, preview: preview)
        let updateMessage = GenericMessage(content: asset, nonce: nonce)

        // when
        var observer: MessageChangeObserver?
        var conversation: ZMConversation?

        let insertBlock = { (data: Data, mockConversation: MockConversation, from: MockUserClient, to: MockUserClient) -> Void in
            mockConversation.insertOTRMessage(from: from, to: to, data: data)
            conversation = self.conversation(for: mockConversation)
            observer = MessageChangeObserver.init(message: conversation?.lastMessage as? ZMMessage)
        }
        let message = self.remotelyInsertAssetOriginalWithMimeType(mimeType: "video/mp4",
                                                                   updateMessage: updateMessage,
                                                                   insertBlock: insertBlock,
                                                                   nonce: nonce,
                                                                   isEphemeral: false)

        // Mock the asset/v3 request
        self.mockTransportSession.responseGeneratorBlock = { request in
            let expectedPath = "/assets/v3/\(thumbnailIDString)"
            if request.path == expectedPath {
                return ZMTransportResponse.init(imageData: encryptedAsset, httpStatus: 200, transportSessionError: nil, headers: nil, apiVersion: APIVersion.v0.rawValue)
            }
            return nil
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(message)
        XCTAssertNotNil(observer)
        XCTAssertNotNil(conversation)

        self.userSession?.perform {
            message?.fileMessageData?.requestImagePreviewDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertNotNil(message)
        let notifications = observer!.notifications
        XCTAssertEqual(notifications!.count, 2)
        let info = notifications?.lastObject as! MessageChangeInfo
        XCTAssertTrue(info.imageChanged)

        // then
        // We should have received an thumbnail asset ID to be able to download the thumbnail image
        XCTAssertEqual(message!.fileMessageData!.thumbnailAssetID, thumbnailIDString)
        XCTAssertEqual(message!.nonce, nonce)
        XCTAssertEqual(message!.transferState, AssetTransferState.uploading)
    }

    func testThatItReceivesAVideoFileMessageThumbnailSentRemotely_Ephemeral_V3() {
        // given
        XCTAssertTrue(self.login())

        let nonce = UUID.create()
        let thumbnailAssetID = UUID.create()
        let thumbnailIDString = thumbnailAssetID.transportString()
        let otrKey = Data.randomEncryptionKey()
        let encryptedAsset = self.mediumJPEGData().zmEncryptPrefixingPlainTextIV(key: otrKey)
        let sha256 = encryptedAsset.zmSHA256Digest()

        let remote = WireProtos.Asset.RemoteData(withOTRKey: otrKey, sha256: sha256, assetId: thumbnailIDString, assetToken: nil)
        let image = WireProtos.Asset.ImageMetaData(width: 1024, height: 2048)
        let preview = WireProtos.Asset.Preview(size: 256,
                                               mimeType: "image/jpeg",
                                               remoteData: remote,
                                               imageMetadata: image)
        let asset = WireProtos.Asset(original: nil, preview: preview)
        let updateMessage = GenericMessage(content: asset, nonce: nonce, expiresAfterTimeInterval: 20)

        // when
        var observer: MessageChangeObserver?
        var conversation: ZMConversation?

        let insertBlock = { (data: Data, mockConversation: MockConversation, from: MockUserClient, to: MockUserClient) -> Void in
            mockConversation.insertOTRMessage(from: from, to: to, data: data)
            conversation = self.conversation(for: mockConversation)
            observer = MessageChangeObserver.init(message: conversation?.lastMessage as? ZMMessage)
        }
        let message = self.remotelyInsertAssetOriginalWithMimeType(mimeType: "video/mp4",
                                                                   updateMessage: updateMessage,
                                                                   insertBlock: insertBlock,
                                                                   nonce: nonce,
                                                                   isEphemeral: true)

        XCTAssertTrue(message!.isEphemeral)

        self.mockTransportSession.responseGeneratorBlock = { request in
            let expectedPath = "/assets/v3/\(thumbnailIDString)"
            if request.path == expectedPath {
                return ZMTransportResponse.init(imageData: encryptedAsset, httpStatus: 200, transportSessionError: nil, headers: nil, apiVersion: APIVersion.v0.rawValue)
            }
            return nil
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(message)
        XCTAssertNotNil(observer)
        XCTAssertNotNil(conversation)

        self.userSession?.perform {
            message?.fileMessageData?.requestImagePreviewDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertNotNil(message)
        let notifications = observer!.notifications
        XCTAssertEqual(notifications!.count, 2)
        let info = notifications?.lastObject as! MessageChangeInfo
        XCTAssertTrue(info.imageChanged)

        // then
        // We should have received an thumbnail asset ID to be able to download the thumbnail image
        XCTAssertEqual(message!.fileMessageData!.thumbnailAssetID, thumbnailIDString)
        XCTAssertEqual(message!.nonce, nonce)
        XCTAssertEqual(message!.transferState, AssetTransferState.uploading)
        XCTAssertTrue(message!.isEphemeral)

    }

    func testThatAFileUpload_AssetUploaded_MessageIsReceivedAndUpdatesTheOriginalMessageWhenSentRemotely_V3() {
        // given
        XCTAssertTrue(self.login())

        let nonce = UUID.create()
        let assetID = UUID.create()
        let otrKey = Data.randomEncryptionKey()
        let sha256 = Data.zmRandomSHA256Key()

        var uploaded = GenericMessage(content: WireProtos.Asset(withUploadedOTRKey: otrKey, sha256: sha256), nonce: nonce)
        uploaded.updateUploaded(assetId: assetID.transportString(), token: nil, domain: nil)

        // when
        let message = self.remotelyInsertAssetOriginalAndUpdate(updateMessage: uploaded, insertBlock: { (data, conversation, from, to) in
                   conversation.insertOTRMessage(from: from, to: to, data: data)
                      }, nonce: nonce)

        // then
        XCTAssertNil(message!.assetId) // We do not store the asset ID in the DB for v3 assets
        XCTAssertEqual(message!.underlyingMessage!.assetData!.uploaded.assetID, assetID.transportString())
        XCTAssertEqual(message!.version, 3)
        XCTAssertEqual(message!.nonce, nonce)
        XCTAssertEqual(message!.transferState, AssetTransferState.uploaded)
    }
}

// MARK: Downloading

extension FileTransferTests_Swift {

    func testThatItSendsTheRequestToDownloadAFileWhenItHasTheAssetID_AndSetsTheStateTo_Downloaded_AfterSuccesfullDecryption_V3() {
        // given
        XCTAssertTrue(self.login())

        let nonce = UUID.create()
        let assetID = UUID.create()
        let otrKey = Data.randomEncryptionKey()

        let assetData = Data.secureRandomData(length: 256)
        let encryptedAsset = assetData.zmEncryptPrefixingPlainTextIV(key: otrKey)
        let sha256 = encryptedAsset.zmSHA256Digest()

        var uploaded = GenericMessage(content: WireProtos.Asset(withUploadedOTRKey: otrKey, sha256: sha256), nonce: nonce)
        uploaded.updateUploaded(assetId: assetID.transportString(), token: nil, domain: nil)

        // when
        let message = self.remotelyInsertAssetOriginalAndUpdate(updateMessage: uploaded, insertBlock: { (data, conversation, from, to) in
        conversation.insertOTRMessage(from: from, to: to, data: data)
           }, nonce: nonce)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let conversation = self.conversation(for: self.selfToUser1Conversation)

        // then
        XCTAssertNotNil(message)
        XCTAssertNil(message!.assetId) // We do not store the asset ID in the DB for v3 assets
        XCTAssertEqual(message!.nonce, nonce)
        XCTAssertEqual(message!.transferState, AssetTransferState.uploaded)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        // Mock the asset/v3 request
        self.mockTransportSession.responseGeneratorBlock = { request in
            let expectedPath = "/assets/v3/\(assetID.transportString())"
            if request.path == expectedPath {
                return ZMTransportResponse.init(imageData: encryptedAsset, httpStatus: 200, transportSessionError: nil, headers: nil, apiVersion: APIVersion.v0.rawValue)
            }
            return nil
        }

        // when we request the file download
        self.mockTransportSession.resetReceivedRequests()
        self.userSession?.perform {
            message?.requestFileDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let lastRequest = self.mockTransportSession.receivedRequests().last! as ZMTransportRequest
        let expectedPath = "/assets/v3/\(assetID.transportString())"
        XCTAssertEqual(lastRequest.path, expectedPath)
        XCTAssertEqual(message!.transferState, AssetTransferState.uploaded)

    }

    func testThatItSendsTheRequestToDownloadAFileWhenItHasTheAssetID_AndSetsTheStateTo_FailedDownload_AfterFailedDecryption_V3() {
        // given
        XCTAssertTrue(self.login())

        let nonce = UUID.create()
        let assetID = UUID.create()
        let otrKey = Data.randomEncryptionKey()

        let assetData = Data.secureRandomData(length: 256)
        let encryptedAsset = assetData.zmEncryptPrefixingPlainTextIV(key: otrKey)
        let sha256 = encryptedAsset.zmSHA256Digest()

        var uploaded = GenericMessage(content: WireProtos.Asset(withUploadedOTRKey: otrKey, sha256: sha256), nonce: nonce)
        uploaded.updateUploaded(assetId: assetID.transportString(), token: nil, domain: nil)

        // when
        let message = self.remotelyInsertAssetOriginalAndUpdate(updateMessage: uploaded, insertBlock: { (data, conversation, from, to) in
               conversation.insertOTRMessage(from: from, to: to, data: data)
                  }, nonce: nonce)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let conversation = self.conversation(for: self.selfToUser1Conversation)

        // then
        XCTAssertNotNil(message)
        XCTAssertNil(message!.assetId) // We do not store the asset ID in the DB for v3 assets
        XCTAssertEqual(message!.nonce, nonce)
        XCTAssertEqual(message!.transferState, AssetTransferState.uploaded)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        // Mock the asset/v3 request
        self.mockTransportSession.responseGeneratorBlock = { request in
            let expectedPath = "/assets/v3/\(assetID.transportString())"
            if request.path == expectedPath {
                let wrongData = Data.secureRandomData(length: 128)
                return ZMTransportResponse.init(imageData: wrongData, httpStatus: 200, transportSessionError: nil, headers: nil, apiVersion: APIVersion.v0.rawValue)
            }
            return nil
        }

        // We log an error when we fail to decrypt the received data
        self.performIgnoringZMLogError {
            self.userSession?.perform {
                message?.requestFileDownload()
            }
            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        let lastRequest = self.mockTransportSession.receivedRequests().last! as ZMTransportRequest
        let expectedPath = "/assets/v3/\(assetID.transportString())"
        XCTAssertEqual(lastRequest.path, expectedPath)
        XCTAssertEqual(message!.downloadState, AssetDownloadState.remote)
    }
}
