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
import WireDataModel
import WireLinkPreview

class LinkPreview_ProtobufTests: XCTestCase {

    func testThatItCreatesAValidArticle_OldStyleProtos() {
        // given
        let protos = LinkPreview.with {
            $0.url = "www.example.com/original"
            $0.permanentURL = "www.example.com/permanent"
            $0.urlOffset = 42
            $0.title = "title"
            $0.summary = "summary"
            $0.article = Article.with {
                $0.title = "title"
                $0.summary = "summary"
                $0.permanentURL = "www.example.com/permanent"
            }
        }

        // when
        let preview = ArticleMetadata(protocolBuffer: protos)

        // then
        XCTAssertEqual(preview.permanentURL?.absoluteString, "www.example.com/permanent")
        XCTAssertEqual(preview.originalURLString, "www.example.com/original")
        XCTAssertEqual(preview.characterOffsetInText, 42)
    }

    func testThatItCreatesAValidArticle_NewStyleProtos() {
        // given
        let protos = LinkPreview.with {
            $0.url = "www.example.com/original"
            $0.permanentURL = "www.example.com/permanent"
            $0.urlOffset = 42
            $0.title = "title"
            $0.summary = "summary"
        }

        // when
        let preview = ArticleMetadata(protocolBuffer: protos)

        // then
        XCTAssertEqual(preview.permanentURL?.absoluteString, "www.example.com/permanent")
        XCTAssertEqual(preview.originalURLString, "www.example.com/original")
        XCTAssertEqual(preview.characterOffsetInText, 42)
    }

    func testThatItCreatesAValidArticleWithTweet_NewStyle() {
        // given
        let protos = LinkPreview.with {
            $0.url = "www.example.com/original"
            $0.permanentURL = "www.example.com/permanent"
            $0.urlOffset = 42
            $0.title = "title"
            $0.tweet = Tweet.with {
                $0.author = "author"
                $0.username = "username"
            }
        }

        // when
        let preview = TwitterStatusMetadata(protocolBuffer: protos)

        // then
        XCTAssertEqual(preview.permanentURL?.absoluteString, "www.example.com/permanent")
        XCTAssertEqual(preview.originalURLString, "www.example.com/original")
        XCTAssertEqual(preview.characterOffsetInText, 42)
    }

}
