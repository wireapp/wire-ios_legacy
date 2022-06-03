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

final class IntegrationTests: XCTestCase {

    func testThatItParsesSampleDataTwitter() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Twitter", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.twitterData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleDataTwitterWithImages() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 4, type: "article", siteNameString: "Twitter", userGeneratedImage: true, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.twitterDataWithImages()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleDataTheVerge() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "The Verge", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.vergeData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleDataWashington() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Washington Post", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.washingtonPostData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func disabled_testThatItParsesSampleDataYouTube() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "video.other", siteNameString: "YouTube", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.youtubeData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleDataGuardian() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "the Guardian", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.guardianData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    /// TODO: check why on CI got result:
    /// XCTAssertEqual failed: ("false") is not equal to ("true") - Should have description
    /// XCTAssertEqual failed: ("Optional("website")") is not equal to ("Optional("instapp:photo")") - Type should be instapp:photo, found:website
    /// XCTAssertEqual failed: ("nil") is not equal to ("Optional("Instagram")") - Site name should be Instagram, found: nil
    func testThatItParsesSampleDataInstagram() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "instapp:photo", siteNameString: "Instagram", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.instagramData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleDataVimeo() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "video.other", siteNameString: "Vimeo", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.vimeoData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleDataFoursquare() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 4, type: "playfoursquare:venue", siteNameString: "Foursquare", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: true)
        let mockData = OpenGraphMockDataProvider.foursquareData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleDataMedium() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Medium", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.mediumData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    // TODO: failed with Xcode 13.1
    func disable_testThatItParsesSampleDataWire() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "website", siteNameString: nil, userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.wireData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleDataPolygon() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Polygon", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.polygonData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    let uft16ExpectedString = "Apple\u{A0}Music"

    func disabled_testThatItParsesSampleDataiTunes() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "music.album", siteNameString: uft16ExpectedString, userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.iTunesData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func disabled_testThatItParsesSampleDataiTunesWithoutTitle() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "music.album", siteNameString: uft16ExpectedString, userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.iTunesDataWithoutTitle()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleDataYahooSports() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: nil, userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.yahooSports()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleSoundCloudTrackData() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "music.song", siteNameString: "SoundCloud", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.soundCloudTrack()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleSoundCloudSetData() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "music.playlist", siteNameString: "SoundCloud", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.soundCloudPlaylist()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    /// TODO: check why CI got `XCTAssertNil failed: "<OpenGraphData> nil: https://instagram.com/404:`
    func testThatItDoesNotParse404Links() {
        let mockSite = OpenGraphMockData(head: "", expected: nil, urlString: "https://instagram.com/404", urlVersion: nil)
        assertThatItCanParseSampleData(mockSite, expected: nil)
    }

    struct OpenGraphDataExpectation {
        let numberOfImages: Int
        let type: String?
        let siteNameString: String?
        let userGeneratedImage: Bool
        let hasDescription: Bool
        let hasFoursquareMetaData: Bool
    }

    private func assertThatItCanParseSampleData(_ mockData: OpenGraphMockData,
                                                expected: OpenGraphDataExpectation?,
                                                line: UInt = #line) {

        // given
        let completionExpectation = expectation(description: "It should parse the data")
        let sut = PreviewDownloader(resultsQueue: .main, parsingQueue: .main)

        // when

        var resolvedURL: URL

        if let version = mockData.urlVersion {
            resolvedURL = URL(string: "http://web.archive.org/web/\(version)/\(mockData.urlString)")!
        } else {
            resolvedURL = URL(string: mockData.urlString)!
        }

        var result: OpenGraphData?
        sut.requestOpenGraphData(fromURL: resolvedURL) { data in
            result = data
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 60, handler: nil)

        if expected == nil {
            return XCTAssertNil(result, "Expected no OpenGraph data from \(mockData.urlString)", line: line)
        }

        let expected = expected!

        guard let data = result else {
            return XCTFail("Could not extract open graph data from \(mockData.urlString)", line: line)
        }

        // then
        XCTAssertEqual(data.content != nil, expected.hasDescription, expected.hasDescription ? "Should have description" : "Should not have description", line: line)
        XCTAssertEqual(data.foursquareMetaData != nil, expected.hasFoursquareMetaData, expected.hasFoursquareMetaData ? "Should have Foursquare metadata" : "Should not have Foursquare metadata", line: line)
        XCTAssertEqual(data.type, expected.type, "Type should be \(expected.type ?? "nil"), found:\(data.type)", line: line)

        XCTAssertEqual(data.siteNameString, expected.siteNameString, "Site name should be \(expected.siteNameString ?? "nil"), found: \(data.siteNameString ?? "nil")", line: line)
        XCTAssertEqual(data.userGeneratedImage, expected.userGeneratedImage, "User generated image should match", line: line)
        XCTAssertTrue(data.imageUrls.count == expected.numberOfImages, "Should have \(expected.numberOfImages) images, found:\(data.imageUrls.count)", line: line)
    }

}
