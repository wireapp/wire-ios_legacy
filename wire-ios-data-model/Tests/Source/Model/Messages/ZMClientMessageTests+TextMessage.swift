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
import WireLinkPreview

@testable import WireDataModel

class ZMClientMessageTests_TextMessage: BaseZMMessageTests {

    override func tearDown() {
        super.tearDown()
        wipeCaches()
    }

    func testThatItHasImageReturnsTrueWhenLinkPreviewWillContainAnImage() {
        // given
        let nonce = UUID()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        let article = ArticleMetadata(
            originalURLString: "www.example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "summary"

        var linkPreview = LinkPreview(articleMetadata: article)
        linkPreview.update(withOtrKey: Data(), sha256: Data(), original: nil)
        let text = Text.with {
            $0.content = "sample text"
            $0.linkPreview = [linkPreview]
        }
        do {
            try clientMessage.setUnderlyingMessage(GenericMessage(content: text, nonce: nonce))
        } catch {
            XCTFail()
        }
        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage

        // then
        XCTAssertTrue(willHaveAnImage)
    }

    func testThatItHasImageReturnsFalseWhenLinkPreviewDoesntContainAnImage() {

        // given
        let nonce = UUID()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        let article = ArticleMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "summary"
        let text = Text.with {
            $0.content = "sample text"
            $0.linkPreview = [LinkPreview(articleMetadata: article)]
        }
        do {
            try clientMessage.setUnderlyingMessage(GenericMessage(content: text, nonce: nonce))
        } catch {
            XCTFail()
        }

        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage

        // then
        XCTAssertFalse(willHaveAnImage)
    }

    func testThatItHasImageReturnsTrueWhenLinkPreviewWillContainAnImage_TwitterStatus() {
        // given
        let nonce = UUID.create()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        let preview = TwitterStatusMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )

        preview.author = "Author"
        preview.message = name

        var updated = LinkPreview(twitterMetadata: preview)
        updated.update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key(), original: nil)
        let text = Text.with {
            $0.content = "Text"
            $0.linkPreview = [updated]
        }
        do {
            try clientMessage.setUnderlyingMessage(GenericMessage(content: text, nonce: nonce))
        } catch {
            XCTFail()
        }
        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage

        // then
        XCTAssertTrue(willHaveAnImage)
    }

    func testThatItHasImageReturnsFalseWhenLinkPreviewDoesntContainAnImage_TwitterStatus() {
        // given
        let nonce = UUID.create()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        let preview = TwitterStatusMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )

        preview.author = "Author"
        preview.message = name
        let text = Text.with {
            $0.content = "Text"
            $0.linkPreview = [LinkPreview(twitterMetadata: preview)]
        }
        do {
            try clientMessage.setUnderlyingMessage(GenericMessage(content: text, nonce: nonce))
        } catch {
            XCTFail()
        }

        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage

        // then
        XCTAssertFalse(willHaveAnImage)
    }

    func testThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalledAndItHasAAssetID() {
        // given
        let preview = TwitterStatusMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )

        preview.author = "Author"
        preview.message = name

        // then
        assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(preview)
    }

    func testThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalledAndItHasAAssetID_Article() {
        // given
        let preview = ArticleMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )

        preview.title = "title"
        preview.summary = "summary"

        // then
        assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(preview)
    }

    func assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(_ preview: LinkMetadata, line: UInt = #line) {

        // given
        let nonce = UUID.create()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        var updated = LinkPreview(preview)
        updated.update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key(), original: nil)
        updated.update(withAssetKey: "id", assetToken: nil, assetDomain: nil)
        let text = Text.with {
            $0.content = "Text"
            $0.linkPreview = [updated]
        }
        do {
            try clientMessage.setUnderlyingMessage(GenericMessage(content: text, nonce: nonce))
        } catch {
            XCTFail()
        }
        try! uiMOC.obtainPermanentIDs(for: [clientMessage])

        // when
        let expectation = self.expectation(description: "Notified")
        let token: Any? = NotificationInContext.addObserver(name: ZMClientMessage.linkPreviewImageDownloadNotification,
                                          context: self.uiMOC.notificationContext,
                                          object: clientMessage.objectID) { _ in
            expectation.fulfill()
        }

        clientMessage.textMessageData?.requestLinkPreviewImageDownload()

        // then
        withExtendedLifetime(token) { () -> Void in
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.2), line: line)
        }
    }

}
