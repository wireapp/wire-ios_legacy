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
import WireLinkPreview
import WireDataModel
import WireRequestStrategy
import XCTest

// MARK: - Tests setup
class LinkPreviewAssetUploadRequestStrategyTests: MessagingTestBase {

    fileprivate var sut: LinkPreviewAssetUploadRequestStrategy!
    fileprivate var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online

        self.sut = LinkPreviewAssetUploadRequestStrategy(managedObjectContext: self.syncMOC, applicationStatus: mockApplicationStatus, linkPreviewPreprocessor: nil, previewImagePreprocessor: nil)
    }

    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        super.tearDown()
    }

    /// Creates a message that should generate request
    func createMessage(_ text: String, linkPreviewState: ZMLinkPreviewState = .waitingToBeProcessed, linkPreview: LinkMetadata, isEphemeral: Bool = false) -> ZMClientMessage {
        let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
        conversation.remoteIdentifier = UUID.create()
        if isEphemeral {
            conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
        }
        let message = try! conversation.appendText(content: text) as! ZMClientMessage
        message.linkPreviewState = linkPreviewState
        if isEphemeral {
            XCTAssertTrue(message.isEphemeral)
            let genericMessage = GenericMessage(content: Text(content: text, mentions: [], linkPreviews: [linkPreview]), nonce: message.nonce!, expiresAfterTimeInterval: 10)
            do {
                try message.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail("Error in adding data: \(error)")
            }
        } else {
            let genericMessage = GenericMessage(content: Text(content: text, mentions: [], linkPreviews: [linkPreview]), nonce: message.nonce!)
            do {
                try message.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail("Error in adding data: \(error)")
            }
        }
        self.syncMOC.saveOrRollback()

        return message
    }

    func createArticle() -> ArticleMetadata {
        let article = ArticleMetadata(
            originalURLString: "example.com/article",
            permanentURLString: "https://example.com/permament",
            resolvedURLString: "https://example.com/permament",
            offset: 0
        )
        article.title = "title"
        article.summary = "summary"
        article.imageData = [mediumJPEGData()]

        return article
    }

    /// Forces the strategy to process the message
    func process(_ strategy: LinkPreviewAssetUploadRequestStrategy, message: ZMClientMessage) {
        strategy.contextChangeTrackers.forEach {
            $0.objectsDidChange([message])
        }
    }

    func encryptLinkPreview(inMessage message: ZMClientMessage) -> (Data, Data) {
        let otrKey = "1".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let sha256 = "2".data(using: String.Encoding.utf8, allowLossyConversion: false)!

        var linkPreview = message.underlyingMessage!.linkPreviews.first!
        linkPreview.update(withOtrKey: otrKey, sha256: sha256, original: nil)
        let text = Text.with {
            $0.content = message.textMessageData!.messageText!
            $0.mentions = []
            $0.linkPreview = [linkPreview]
        }
        let genericMessage = GenericMessage(content: text, nonce: message.nonce!, expiresAfterTimeInterval: message.deletionTimeout)
        do {
            try message.setUnderlyingMessage(genericMessage)
        } catch {
            fatal("Failure adding genericMessage")
        }

        return (otrKey, sha256)
    }

    func completeRequest(_ message: ZMClientMessage, request: ZMTransportRequest?, assetId: String, token: String, domain: String) {
        let response = ZMTransportResponse(payload: ["key": assetId, "token": token, "domain": domain] as ZMTransportData, httpStatus: 201, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        _ = sut.updateUpdatedObject(message, requestUserInfo: nil, response: response, keysToParse: [ZMClientMessage.linkPreviewStateKey])
    }
}

// MARK: - Tests
extension LinkPreviewAssetUploadRequestStrategyTests {

    func testThatItCreatesRequestForProcessedLinkPreview() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let article = self.createArticle()
            let message = self.createMessage(article.permanentURL!.absoluteString, linkPreviewState: .processed, linkPreview: article)
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: true, data: article.imageData.first!)

            self.syncMOC.saveOrRollback()
            self.process(self.sut, message: message)

            // WHEN
            let request = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertNotNil(request)
            XCTAssertEqual(request?.path, "/assets/v3")
            XCTAssertEqual(request?.method, ZMTransportRequestMethod.methodPOST)
        }
    }

    func testThatItDoesntCreateUnauthenticatedRequests() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let article = self.createArticle()
            let message = self.createMessage(article.permanentURL!.absoluteString, linkPreviewState: .processed, linkPreview: article)
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: true, data: article.imageData.first!)
            self.process(self.sut, message: message)
            self.mockApplicationStatus.mockSynchronizationState = .unauthenticated

            // WHEN
            let request = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertNil(request)
        }
    }

    func testThatItDoesntCreateRequestsForUnprocessedLinkPreview() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let article = self.createArticle()
            let message = self.createMessage(article.permanentURL!.absoluteString, linkPreviewState: .waitingToBeProcessed, linkPreview: article)
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: true, data: article.imageData.first!)
            self.process(self.sut, message: message)

            // WHEN
            let request = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertNil(request)
        }
    }

    func testThatItDoesntCreateRequestsForLinkPreviewStateDone() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let article = self.createArticle()
            let message = self.createMessage(article.permanentURL!.absoluteString, linkPreviewState: .done, linkPreview: article)
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: true, data: article.imageData.first!)
            self.process(self.sut, message: message)

            // WHEN
            let request = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertNil(request)
        }
    }

    func testThatItDoesNotCreateARequestIfThereIsNoImageInTheCache() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let article = self.createArticle()
            let message = self.createMessage(article.permanentURL!.absoluteString, linkPreviewState: .processed, linkPreview: article)
            self.process(self.sut, message: message)

            // WHEN & THEN
            XCTAssertNil(self.sut.nextRequest(for: .v0))
        }
    }

    func testThatItUpdatesMessageWithAssetKeyAndToken() {
        // GIVEN
        let assetId = "id123"
        let token = "qJ8JPFLsiYGx7fnrlL+7Yk9="
        let domain = UUID().uuidString
        var message: ZMClientMessage! = nil
        var otrKey: Data! = nil
        var sha256: Data! = nil

        syncMOC.performGroupedBlock {
            let article = self.createArticle()
            message = self.createMessage(article.permanentURL!.absoluteString, linkPreviewState: .processed, linkPreview: article)
            let keys = self.encryptLinkPreview(inMessage: message)
            otrKey = keys.0
            sha256 = keys.1

            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: true, data: article.imageData.first!)
            _ = self.encryptLinkPreview(inMessage: message)
            message.linkPreviewState = .waitingToBeProcessed
            self.syncMOC.saveOrRollback()

            self.process(self.sut, message: message)
            let request = self.sut.nextRequest(for: .v0)

            // WHEN
            self.completeRequest(message, request: request, assetId: assetId, token: token, domain: domain)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            let linkPreview = message.underlyingMessage!.linkPreviews.first!
            XCTAssertEqual(linkPreview.image.uploaded.otrKey, otrKey)
            XCTAssertEqual(linkPreview.image.uploaded.sha256, sha256)
            XCTAssertEqual(linkPreview.image.uploaded.assetID, assetId)
            XCTAssertEqual(linkPreview.image.uploaded.assetToken, token)
            XCTAssertEqual(linkPreview.image.uploaded.assetDomain, domain)
        }
    }

    func testThatItUpdatesTheLinkPreviewState() {
        // GIVEN
        var message: ZMClientMessage! = nil

        syncMOC.performGroupedBlock {
            let article = self.createArticle()
            message = self.createMessage(article.permanentURL!.absoluteString, linkPreviewState: .processed, linkPreview: article)
            _ = self.encryptLinkPreview(inMessage: message)
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: true, data: article.imageData.first!)
            message.linkPreviewState = .processed
            self.syncMOC.saveOrRollback()

            self.process(self.sut, message: message)
            let request = self.sut.nextRequest(for: .v0)

            let assetId = "id123"
            let token = "qJ8JPFLsiYGx7fnrlL+7Yk9="
            let domain = UUID().uuidString

            // WHEN
            self.completeRequest(message, request: request, assetId: assetId, token: token, domain: domain)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewState.uploaded)
        }
    }

}

extension LinkPreviewAssetUploadRequestStrategyTests {

    func testThatItUpdatesEphemeralMessageWithAssetKeyAndToken() {
        // GIVEN
        let assetId = "id123"
        let token = "qJ8JPFLsiYGx7fnrlL+7Yk9="
        let domain = UUID().uuidString
        var message: ZMClientMessage! = nil
        var otrKey: Data! = nil
        var sha256: Data! = nil

        syncMOC.performGroupedBlock {
            let article = self.createArticle()
            message = self.createMessage(article.permanentURL!.absoluteString, linkPreviewState: .processed, linkPreview: article, isEphemeral: true)
            let keys = self.encryptLinkPreview(inMessage: message)
            otrKey = keys.0
            sha256 = keys.1

            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: true, data: article.imageData.first!)
            _ = self.encryptLinkPreview(inMessage: message)
            message.linkPreviewState = .waitingToBeProcessed
            self.syncMOC.saveOrRollback()

            self.process(self.sut, message: message)
            let request = self.sut.nextRequest(for: .v0)

            XCTAssertTrue(message.isEphemeral)

            // WHEN
            self.completeRequest(message, request: request, assetId: assetId, token: token, domain: domain)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlock {
            // THEN
            XCTAssertTrue(message.isEphemeral)
            guard case .ephemeral? = message.underlyingMessage!.content else {
                return XCTFail("No ephemeral content found")
            }
            // The message is ephemeral and contains text
            XCTAssertTrue(message.underlyingMessage!.hasText)

            let linkPreview = message.underlyingMessage!.linkPreviews.first!
            XCTAssertEqual(linkPreview.image.uploaded.otrKey, otrKey)
            XCTAssertEqual(linkPreview.image.uploaded.sha256, sha256)
            XCTAssertEqual(linkPreview.image.uploaded.assetID, assetId)
            XCTAssertEqual(linkPreview.image.uploaded.assetToken, token)
            XCTAssertEqual(linkPreview.image.uploaded.assetDomain, domain)
        }
    }

}
