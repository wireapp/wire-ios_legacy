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
import WireDataModel
import XCTest
@testable import WireRequestStrategy

class LinkPreviewAssetDownloadRequestStrategyTests: MessagingTestBase {

    var sut: LinkPreviewAssetDownloadRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var oneToOneconversationOnSync: ZMConversation!

    var apiVersion: APIVersion! {
        didSet {
            APIVersion.current = apiVersion
        }
    }

    override func setUp() {
        super.setUp()
        self.syncMOC.performGroupedAndWait { syncMOC in
            self.mockApplicationStatus = MockApplicationStatus()
            self.mockApplicationStatus.mockSynchronizationState = .online
            self.oneToOneconversationOnSync = syncMOC.object(with: self.oneToOneConversation.objectID) as? ZMConversation

            self.sut = LinkPreviewAssetDownloadRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: self.mockApplicationStatus)
        }

        apiVersion = .v0
    }

    override func tearDown() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            self.sut = nil
            self.mockApplicationStatus = nil
            self.oneToOneconversationOnSync = nil
            syncMOC.zm_fileAssetCache.wipeCaches()
        }
        uiMOC.zm_fileAssetCache.wipeCaches()
        apiVersion = nil
        super.tearDown()
    }

    // MARK: - Helper

    fileprivate func createLinkPreview(_ assetID: String,
                                       _ assetDomain: String? = nil,
                                       article: Bool = true,
                                       otrKey: Data? = nil,
                                       sha256: Data? = nil) -> LinkPreview {
        let URL = "http://www.example.com"

        if article {
            let (otr, sha) = (otrKey ?? Data.randomEncryptionKey(), sha256 ?? Data.zmRandomSHA256Key())
            let remoteData = WireProtos.Asset.RemoteData.with {
                $0.assetID = assetID
                if let assetDomain = assetDomain {
                    $0.assetDomain = assetDomain
                }
                $0.otrKey = otr
                $0.sha256 = sha
            }
            let asset = WireProtos.Asset.with {
                $0.uploaded = remoteData
            }
            let linkPreview = LinkPreview.with {
                $0.url = URL
                $0.permanentURL = URL
                $0.urlOffset = 42
                $0.title = "Title"
                $0.summary = "Summary"
                $0.image = asset
            }
            return linkPreview
        } else {
            let linkPreview = LinkPreview.with {
                $0.url = URL
                $0.permanentURL = URL
                $0.urlOffset = 42
                $0.title = "Title"
                $0.tweet = WireProtos.Tweet.with {
                    $0.author = "Author"
                    $0.username = "UserName"
                }
            }

            return linkPreview
        }
    }

    fileprivate func fireSyncCompletedNotification() {
        // ManagedObjectContextObserver does not process all changes until the sync is done
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ZMApplicationDidEnterEventProcessingStateNotification"), object: nil, userInfo: nil)
    }
}

extension LinkPreviewAssetDownloadRequestStrategyTests {

    // MARK: - Request Generation

    func testThatItGeneratesAnExpectedV3RequestForAWhitelistedMessageWithNoImageInCache() {
        // GIVEN
        let assetID = UUID.create().transportString()
        let linkPreview = self.createLinkPreview(assetID)
        let nonce = UUID.create()
        var text = Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil)
        text.linkPreview.append(linkPreview)
        let genericMessage = GenericMessage(content: text, nonce: nonce)

        self.syncMOC.performGroupedAndWait { syncMOC in
            let message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        self.syncMOC.performGroupedAndWait { _ in
            // THEN
            guard let request = self.sut.nextRequest(for: self.apiVersion) else { XCTFail("No request generated"); return }
            XCTAssertEqual(request.path, "/assets/v3/\(assetID)")
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodGET)
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatItGeneratesAnExpectedV3RequestForAWhitelistedEphemeralMessageWithNoImageInCache() {
        let assetID = UUID.create().transportString()

        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let linkPreview = self.createLinkPreview(assetID)
            let nonce = UUID.create()
            var text = Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil)
            text.linkPreview.append(linkPreview)
            let genericMessage = GenericMessage(content: text, nonce: nonce, expiresAfterTimeInterval: 20)
            let message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        self.syncMOC.performGroupedAndWait { _ in
            // THEN
            guard let request = self.sut.nextRequest(for: self.apiVersion) else { XCTFail("No request generated"); return }
            XCTAssertEqual(request.path, "/assets/v3/\(assetID)")
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodGET)
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatItGeneratesAnExpectedV4RequestForAWhitelistedMessageWithNoImageInCache() {
        // GIVEN
        apiVersion = .v1
        let assetID = UUID.create().transportString()
        let assetDomain = UUID().create().transportString()
        let linkPreview = self.createLinkPreview(assetID, assetDomain)
        let nonce = UUID.create()
        var text = Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil)
        text.linkPreview.append(linkPreview)
        let genericMessage = GenericMessage(content: text, nonce: nonce)

        self.syncMOC.performGroupedAndWait { syncMOC in
            let message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        self.syncMOC.performGroupedAndWait { _ in
            // THEN
            guard let request = self.sut.nextRequest(for: self.apiVersion) else { XCTFail("No request generated"); return }
            XCTAssertEqual(request.path, "/v1/assets/v4/\(assetDomain)/\(assetID)")
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodGET)
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatItGeneratesAnExpectedV4RequestForAWhitelistedEphemeralMessageWithNoImageInCache() {
        apiVersion = .v1
        let assetID = UUID.create().transportString()
        let assetDomain = UUID().create().transportString()
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let linkPreview = self.createLinkPreview(assetID, assetDomain)
            let nonce = UUID.create()
            var text = Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil)
            text.linkPreview.append(linkPreview)
            let genericMessage = GenericMessage(content: text, nonce: nonce, expiresAfterTimeInterval: 20)

            let message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        self.syncMOC.performGroupedAndWait { _ in
            // THEN
            guard let request = self.sut.nextRequest(for: self.apiVersion) else { XCTFail("No request generated"); return }
            XCTAssertEqual(request.path, "/v1/assets/v4/\(assetDomain)/\(assetID)")
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodGET)
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatItDoesNotGenerateARequestForAMessageWithoutALinkPreview() {
        let message = syncMOC.performGroupedAndWait { _ -> ZMMessage in
            let genericMessage = GenericMessage(content: Text(content: self.name))
            return try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
        }

        syncMOC.performGroupedBlockAndWait {
            _ = try? self.syncMOC.obtainPermanentIDs(for: [message])
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // WHEN
        syncMOC.performGroupedBlockAndWait {
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedAndWait { _ in
            // THEN
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatItDoesNotGenerateARequestForAMessageWithImageInCache() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let assetID = UUID.create().transportString()
            let linkPreview = self.createLinkPreview(assetID)
            let nonce = UUID.create()
            var text = Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil)
            text.linkPreview.append(linkPreview)
            let genericMessage = GenericMessage(content: text, nonce: nonce)
            let message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])
            syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: false, data: .secureRandomData(length: 256))

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        self.syncMOC.performGroupedAndWait { _ in
            // THEN
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatItDoesNotGenerateARequestForAMessageWithoutArticleLinkPreview() {
        let assetID = UUID.create().transportString()
        let linkPreview = self.createLinkPreview(assetID, article: false)
        let nonce = UUID.create()
        var text = Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil)
        text.linkPreview.append(linkPreview)
        let genericMessage = GenericMessage(content: text, nonce: nonce)
        var message: ZMMessage!

        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])
            syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: false, data: .secureRandomData(length: 256))

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        self.syncMOC.performGroupedAndWait { _ in
            // THEN
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    // MARK: - Response Handling

    func testThatItDecryptsTheImageDataInTheRequestResponseAndDeletesTheEncryptedVersion() {

        let assetID = UUID.create().transportString()
        let data = Data.secureRandomData(length: 256)
        let otrKey = Data.randomEncryptionKey()
        let encrypted = data.zmEncryptPrefixingPlainTextIV(key: otrKey)
        let linkPreview = createLinkPreview(assetID, otrKey: otrKey, sha256: encrypted.zmSHA256Digest())
        let nonce = UUID.create()

        var text = Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil)
        text.linkPreview.append(linkPreview)
        let genericMessage = GenericMessage(content: text, nonce: nonce)

        var message: ZMMessage!

        self.syncMOC.performGroupedAndWait { syncMOC in

            message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        self.syncMOC.performGroupedAndWait { _ in
            // THEN
            guard let request = self.sut.nextRequest(for: self.apiVersion) else { XCTFail("No request generated"); return }
            let response = ZMTransportResponse(imageData: encrypted, httpStatus: 200, transportSessionError: nil, headers: nil, apiVersion: self.apiVersion.rawValue)

            // WHEN
            request.complete(with: response)
        }
        self.syncMOC.performGroupedAndWait { syncMOC in
            // THEN
            let actual = syncMOC.zm_fileAssetCache.assetData(message, format: .medium, encrypted: false)
            XCTAssertNotNil(actual)
            XCTAssertEqual(actual, data)
            XCTAssertNil(syncMOC.zm_fileAssetCache.assetData(message, format: .medium, encrypted: true))
        }
    }

    func testThatItDoesNotDecyptTheImageDataInTheRequestResponseWhenTheResponseIsNotSuccessful() {
        let assetID = UUID.create().transportString()
        let linkPreview = createLinkPreview(assetID)
        let nonce = UUID.create()
        var text = Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil)
        text.linkPreview.append(linkPreview)
        let genericMessage = GenericMessage(content: text, nonce: nonce)
        var message: ZMMessage!
        self.syncMOC.performGroupedAndWait { syncMOC in

            message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }

        self.syncMOC.performGroupedAndWait { _ in
            // THEN
            guard let request = self.sut.nextRequest(for: self.apiVersion) else { XCTFail("No request generated"); return }
            let response = ZMTransportResponse(imageData: .secureRandomData(length: 256), httpStatus: 400, transportSessionError: nil, headers: nil, apiVersion: self.apiVersion.rawValue)
            // WHEN
            request.complete(with: response)
        }
        self.syncMOC.performGroupedAndWait { syncMOC in
            // THEN
            XCTAssertNil(syncMOC.zm_fileAssetCache.assetData(message, format: .medium, encrypted: false))
            XCTAssertNil(syncMOC.zm_fileAssetCache.assetData(message, format: .medium, encrypted: true))
        }
    }
}
