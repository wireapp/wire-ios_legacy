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
@testable import WireRequestStrategy
import XCTest
import WireDataModel

class ImageV2DownloadRequestStrategyTests: MessagingTestBase {

    fileprivate var applicationStatus: MockApplicationStatus!

    fileprivate var sut: ImageV2DownloadRequestStrategy!

    override func setUp() {
        super.setUp()
        applicationStatus = MockApplicationStatus()
        applicationStatus.mockSynchronizationState = .online
        sut = ImageV2DownloadRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: applicationStatus)
    }

    override func tearDown() {
        super.tearDown()
        applicationStatus = nil
        sut = nil
    }

    // MARK: Helpers

    func createV2ImageMessage(withAssetId assetId: UUID?) -> (ZMAssetClientMessage, Data) {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()

        let sender = ZMUser.insertNewObject(in: syncMOC)
        sender.remoteIdentifier = UUID.create()

        let message = ZMAssetClientMessage(nonce: UUID(), managedObjectContext: syncMOC)
        let imageData = verySmallJPEGData() // message.imageAssetStorage.originalImageData()
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size: imageSize, length: UInt(imageData.count), mimeType: "image/jpeg")
        let key = Data.randomEncryptionKey()
        let encryptedData = imageData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        let keys = ZMImageAssetEncryptionKeys(otrKey: key, sha256: sha)

        do {
            try message.setUnderlyingMessage(GenericMessage(content: ImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: .medium), nonce: message.nonce!))
            try message.setUnderlyingMessage(GenericMessage(content: ImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: .preview), nonce: message.nonce!))
        } catch {
            XCTFail("Could not set generic message")
        }

        message.version = 2
        message.assetId = assetId
        message.sender = sender
        conversation.append(message)
        syncMOC.saveOrRollback()

        return (message, encryptedData)
    }

    func createFileMessage() -> ZMAssetClientMessage {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()

        let nonce = UUID.create()
        let fileURL = Bundle(for: ImageV2DownloadRequestStrategyTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!
        let metadata = ZMFileMetadata(fileURL: fileURL)
        let message = try! conversation.appendFile(with: metadata, nonce: nonce) as! ZMAssetClientMessage

        syncMOC.saveOrRollback()

        return message
    }

    func requestToDownloadAsset(withMessage message: ZMAssetClientMessage) -> ZMTransportRequest {
        // remove image data or it won't be downloaded
        syncMOC.zm_fileAssetCache.deleteAssetData(message, format: .original, encrypted: false)
        message.imageMessageData?.requestFileDownload()
        return sut.nextRequest(for: .v0)!
    }

    // MARK: - Request Generation

    func testRequestToDownloadAssetIsCreated() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlock {
            message = self.createV2ImageMessage(withAssetId: UUID()).0

            // remove image data or it won't be downloaded
            self.syncMOC.zm_fileAssetCache.deleteAssetData(message, format: .original, encrypted: false)
            message.imageMessageData?.requestFileDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // WHEN
            let request = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertEqual(request?.path, "/conversations/\(message.conversation!.remoteIdentifier!.transportString())/otr/assets/\(message.assetId!.transportString())")
        }
    }

    func testRequestToDownloadAssetIsNotCreated_WhenAssetIdIsNotAvailable() {
        // GIVEN
        self.syncMOC.performGroupedBlock {
            let (message, _) = self.createV2ImageMessage(withAssetId: nil)

            // remove image data or it won't be downloaded
            self.syncMOC.zm_fileAssetCache.deleteAssetData(message, format: .original, encrypted: false)
            message.imageMessageData?.requestFileDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // WHEN
            let request = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertNil(request)
        }
    }

    func testRequestToDownloadFileAssetIsNotCreated_BeforeRequestingDownloaded() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let (message, _) = self.createV2ImageMessage(withAssetId: nil)

            // remove image data or it won't be downloaded
            self.syncMOC.zm_fileAssetCache.deleteAssetData(message, format: .original, encrypted: false)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // WHEN
            let request = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertNil(request)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testRequestToDownloadFileAssetIsNotCreated_WhenAlreadyDownloaded() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let (message, _) = self.createV2ImageMessage(withAssetId: nil)
            message.imageMessageData?.requestFileDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // WHEN
            let request = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertNil(request)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: - Response Handling

    func testThatMessageIsDeleted_WhenResponseSaysItDoesntExistOnBackend() {
        let (nonce, conversation) = syncMOC.performGroupedAndWait { _ -> (UUID, ZMConversation) in
            // GIVEN
            let (message, _) = self.createV2ImageMessage(withAssetId: UUID.create())
            let nonceAndConversation = (message.nonce!, message.conversation!)

            // WHEN
            let response = ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            self.sut.delete(message, with: response, downstreamSync: nil)

            // THEN
            XCTAssert(message.isDeleted)
            return nonceAndConversation
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait { moc in
            // GIVEN
            moc.processPendingChanges() // Make sure the deletion has been processed
            let message = ZMMessage.fetch(withNonce: nonce, for: conversation, in: moc, prefetchResult: nil)

            // THEN
            XCTAssertNil(message)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatMessageIsStored_OnSuccessResponse() {
        // GIVEN
        var message: ZMAssetClientMessage!
        var encryptedData: Data!
        self.syncMOC.performGroupedBlock {
            let messageAndEncryptedData = self.createV2ImageMessage(withAssetId: UUID())
            message = messageAndEncryptedData.0
            encryptedData = messageAndEncryptedData.1

            // remove image data or it won't be downloaded
            self.syncMOC.zm_fileAssetCache.deleteAssetData(message, format: .original, encrypted: false)
            message.imageMessageData?.requestFileDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlock {
            // WHEN
            let request = self.sut.nextRequest(for: .v0)
            request?.complete(with: ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: nil, headers: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertTrue(message.hasDownloadedFile)
        }
    }

}
