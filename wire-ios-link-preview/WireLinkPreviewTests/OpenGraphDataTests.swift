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
@testable import WireLinkPreview

class OpenGraphDataTests: XCTestCase {

    func testThatItCreatesAValidOpenGraphDataFromPropertyMapping() {
        // given
        let title = "title"
        let url = "www.example.com/url"
        let type = "article"
        let mapping: [OpenGraphPropertyType: String] = [.title: title, .type: type, .description: name, .url: url]
        let images = ["www.example.com/image"]

        // when
        guard let sut = OpenGraphData(propertyMapping: mapping, resolvedURL: URL(string: url)!, images: images) else { return XCTFail("SUT is nil") }

        // then
        XCTAssertEqual(sut.title, title)
        XCTAssertEqual(sut.type, type)
        XCTAssertEqual(sut.content, name)
        XCTAssertEqual(sut.url, url)
        XCTAssertEqual(sut.imageUrls.first, images.first)
        XCTAssertNil(sut.siteNameString)
        XCTAssertEqual(sut.siteName, OpenGraphSiteName.other)
        XCTAssertFalse(sut.userGeneratedImage)
    }

    func testThatItSetsTheTypeToWebsiteIfThereIsNoTypeInTheMapping() {
        // given
        let title = "title"
        let url = "www.example.com/url"
        let mapping: [OpenGraphPropertyType: String] = [.title: title, .description: name, .url: url]
        let images = ["www.example.com/image"]

        // when
        let sut = OpenGraphData(propertyMapping: mapping, resolvedURL: URL(string: url)!, images: images)

        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut?.type, "website")
    }

    func testThatItReturnsNilWhenRequiredPropertiesAreMissing() {
        // given
        let title = "title"
        let mapping: [OpenGraphPropertyType: String] = [.title: title, .description: name]
        let images = ["www.example.com/image"]

        // when
        let sut = OpenGraphData(propertyMapping: mapping, resolvedURL: URL(string: "www.example.com/image")!, images: images)

        // then
        XCTAssertNil(sut)
    }

    func testThatItSetsTheCorrectSiteName() {
        [OpenGraphSiteName.twitter, .youtube, .vimeo, .instagram, .foursquare].forEach { siteName in
            asserThatItSetsTheCorrectSiteName(siteName.rawValue, expected: siteName)
            asserThatItSetsTheCorrectSiteName(siteName.rawValue.capitalized, expected: siteName)
        }
    }

    func testThatItCreatesTheCorrectLinkPreview_Twitter() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.twitterData(), expectedClass: TwitterStatusMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_TwitterWithImages() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.twitterDataWithImages(), expectedClass: TwitterStatusMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_TheVerge() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.vergeData(), expectedClass: ArticleMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_Foursqaure() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.foursquareData(), expectedClass: ArticleMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_Nytimes() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.nytimesData(), expectedClass: ArticleMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_Guardian() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.guardianData(), expectedClass: ArticleMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_Youtube() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.youtubeData())
    }

    func testThatItCreatesTheCorrectLinkPreview_Vimeo() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.vimeoData())
    }

    func testThatItCreatesTheCorrectLinkPreview_Instagram() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.instagramData(), expectedClass: ArticleMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_WashingtonPost() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.washingtonPostData(), expectedClass: ArticleMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_Medium() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.mediumData(), expectedClass: ArticleMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_Polygon() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.polygonData(), expectedClass: ArticleMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_iTunes() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.iTunesData(), expectedClass: ArticleMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_iTunesWithoutTitle() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.iTunesDataWithoutTitle(), expectedClass: ArticleMetadata.self)
    }

    func testThatItCreatesTheCorrectLinkPreview_YahooSports() {
        assertLinkPreviewMapping(ofOpenGraphData: OpenGraphMockDataProvider.yahooSports(), expectedClass: ArticleMetadata.self)
    }

    func testThatItUsesTheGivenOriginalURLAndCharacterOffsetWhenCreatingALinkPreview() {
        // given
        let data = OpenGraphMockDataProvider.foursquareData().expected
        let originalURLString = "www.example.com"

        // when
        let preview = data?.linkPreview(originalURLString, offset: 42)

        // then
        XCTAssertEqual(preview?.characterOffsetInText, 42)
        XCTAssertEqual(preview?.originalURLString, originalURLString)
        XCTAssertNotEqual(preview?.permanentURL?.absoluteString, originalURLString)
    }

    // MARK: - Helper

    func asserThatItSetsTheCorrectSiteName(_ siteNameString: String, expected: OpenGraphSiteName, line: UInt = #line) {
        // given
        let title = "title"
        let url = "www.example.com/url"
        let type = "article"
        let mapping: [OpenGraphPropertyType: String] = [.title: title, .type: type, .siteName: siteNameString, .url: url]
        let images = ["www.example.com/image"]

        // when
        guard let sut = OpenGraphData(propertyMapping: mapping, resolvedURL: URL(string: url)!, images: images) else { return XCTFail(line: line) }

        XCTAssertEqual(sut.siteName, expected, line: line)
        XCTAssertEqual(sut.siteNameString, siteNameString, line: line)
    }

    func assertLinkPreviewMapping(ofOpenGraphData openGraphData: OpenGraphMockData, expectedClass: AnyClass = LinkMetadata.self, expectedFailure: Bool = false, line: UInt = #line) {
        if let linkPreview = openGraphData.expected?.linkPreview(openGraphData.urlString, offset: 12) {
            XCTAssertFalse(expectedFailure, line: line)
            XCTAssertTrue(linkPreview.isKind(of: expectedClass), "Wrong class", line: line)
        } else {
            XCTAssertTrue(expectedFailure, "No link preview present", line: line)
        }
    }

}
