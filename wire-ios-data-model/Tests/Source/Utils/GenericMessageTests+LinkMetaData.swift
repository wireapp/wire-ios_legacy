//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireTesting
@testable import WireDataModel

class GenericMessageTests_LinkMetaData: BaseZMMessageTests {

    func testThatItCreatesAValidLinkPreview_ArticleMetadata() {
        // given
        let article = ArticleMetadata(
            originalURLString: "www.example.com/original",
            permanentURLString: "www.example.com/permanent",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )
        article.title = "title"
        article.summary = "summary"

        // when
        let linkPreview = LinkPreview(articleMetadata: article)

        // then
        XCTAssertEqual(linkPreview.title, "title")
        XCTAssertEqual(linkPreview.summary, "summary")
        XCTAssertEqual(linkPreview.permanentURL, "www.example.com/permanent")
        XCTAssertEqual(linkPreview.url, "www.example.com/original")
        XCTAssertEqual(linkPreview.urlOffset, 42)
    }

    func testThatItCreatesAValidLinkPreview_TwitterStatusMetadata() {
        // given
        let twitterStatus = TwitterStatusMetadata(
            originalURLString: "www.example.com/original",
            permanentURLString: "www.example.com/permanent",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )
        twitterStatus.message = "message"
        twitterStatus.author = "author"
        twitterStatus.username = "username"

        // when
        let linkPreview = LinkPreview(twitterMetadata: twitterStatus)

        // then
        XCTAssertEqual(linkPreview.title, "message")
        XCTAssertEqual(linkPreview.permanentURL, "www.example.com/permanent")
        XCTAssertEqual(linkPreview.url, "www.example.com/original")
        XCTAssertEqual(linkPreview.urlOffset, 42)
        XCTAssertEqual(linkPreview.tweet.author, "author")
        XCTAssertEqual(linkPreview.tweet.username, "username")
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
        let text = Text(content: "Text", mentions: [], linkPreviews: [preview], replyingTo: nil)
        let genericMessage = GenericMessage(content: text, nonce: nonce, expiresAfter: nil)
        do {
            try clientMessage.setUnderlyingMessage(genericMessage)
        } catch {
            XCTFail()
        }

        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage

        // then
        XCTAssertFalse(willHaveAnImage)
    }

    func testThatItHasImageReturnsFalseWhenLinkPreviewDoesntContainAnImage_Article() {

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

        let text = Text(content: "sample text", mentions: [], linkPreviews: [article], replyingTo: nil)
        let genericMessage = GenericMessage(content: text, nonce: nonce, expiresAfter: nil)
        do {
            try clientMessage.setUnderlyingMessage(genericMessage)
        } catch {
            XCTFail()
        }

        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage

        // then
        XCTAssertFalse(willHaveAnImage)
    }
}
