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
@testable import Wire

class YouTubeServiceTests: XCTestCase {

    var videoURL: URL!
    var requester: MockProxiedURLRequester!

    var service: YouTubeService!

    override func setUp() {
        super.setUp()
        videoURL = URL(string: "https://youtube.com/watch?v=tzod7hyX03I")!
        requester = MockProxiedURLRequester()
        service = YouTubeService(requester: requester)
    }

    override func tearDown() {
        requester = nil
        videoURL = nil
        service = nil
        super.tearDown()
    }

    // MARK: - ID Extraction

    func testThatItExtractsID_LongURL() {
        // given
        let url = URL(string: "https://youtube.com/watch?v=txXwg712zw4")!

        // when
        let id = service.videoID(for: url)

        // then
        XCTAssertEqual(id, "txXwg712zw4")
    }

    func testThatItExtractsID_LongMobileURL() {
        // given
        let url = URL(string: "https://m.youtube.com/watch?v=txXwg712zw4")!

        // when
        let id = service.videoID(for: url)

        // then
        XCTAssertEqual(id, "txXwg712zw4")
    }

    
    func testThatItExtractsID_ShortURL() {
        // given
        let url = URL(string: "https://youtu.be/tzod7hyX03I")!

        // when
        let id = service.videoID(for: url)

        // then
        XCTAssertEqual(id, "tzod7hyX03I")
    }

    // MARK: - JSON Validation

    func testThatItFailsValidation_ErrorProvided() {
        // given
        let data: Data? = nil
        let response: URLResponse? = nil
        let error = NSError(domain: NSCocoaErrorDomain, code: 1, userInfo: nil)

        // then
        XCTAssertThrowsError(try service.validateJSONResponse(data, response, error)) {
            let thrownError = $0 as NSError
            XCTAssertEqual(thrownError.domain, error.domain)
            XCTAssertEqual(thrownError.code, error.code)
        }
    }

    func testThatItFailsValidation_InvalidResponseType() {
        // given
        let data: Data? = nil
        let response: URLResponse? = URLResponse(url: videoURL, mimeType: "application/json", expectedContentLength: 0, textEncodingName: "utf-8")
        let error: NSError? = nil

        // then
        XCTAssertThrowsError(try service.validateJSONResponse(data, response, error)) {
            XCTAssertTrue($0 as? YouTubeServiceError == .invalidResponse)
        }
    }

    func testThatItFailsValidation_ErrorCode() {
        // given
        let data: Data? = nil
        let response: URLResponse? = HTTPURLResponse(url: videoURL, statusCode: 404, httpVersion: "1.1", headerFields: nil)
        let error: NSError? = nil

        // then
        XCTAssertThrowsError(try service.validateJSONResponse(data, response, error)) {
            XCTAssertTrue($0 as? YouTubeServiceError == .invalidResponse)
        }
    }

    func testThatItFailsValidation_NoData() {
        // given
        let data: Data? = nil
        let response: URLResponse? = HTTPURLResponse(url: videoURL, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        let error: NSError? = nil

        // then
        XCTAssertThrowsError(try service.validateJSONResponse(data, response, error)) {
            XCTAssertTrue($0 as? YouTubeServiceError == .noData)
        }
    }

    func testThatItSuccessfullyValidatesJSONResponse() throws {
        // given
        let data: Data? = Data.init(base64Encoded: "NIdL7rjtLZFOSIyjUnIOlQ==")
        let response: URLResponse? = HTTPURLResponse(url: videoURL, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        let error: NSError? = nil

        // when
        let validData = try self.service.validateJSONResponse(data, response, error)

        // then
        XCTAssertEqual(validData.base64EncodedString(), "NIdL7rjtLZFOSIyjUnIOlQ==")
    }

    // MARK: - JSON Decoding

    func testThatItDecodesMediaPreview() throws {
        // given
        let response = mockYouTubeResponse("valid_video")

        // when
        let mediaPreview = try service.makeVideoMediaPreview(from: response)

        // then
        XCTAssertEqual(mediaPreview.title, "NFL | Super Bowl LI Halftime Show")

        let expectedThumbnails: Set<MediaThumbnail> = [
            thumbnail("https://i.ytimg.com/vi/txXwg712zw4/default.jpg", width: 120, height: 90),
            thumbnail("https://i.ytimg.com/vi/txXwg712zw4/mqdefault.jpg", width: 320, height: 180),
            thumbnail("https://i.ytimg.com/vi/txXwg712zw4/hqdefault.jpg", width: 480, height: 360)
        ]

        XCTAssertEqual(Set(mediaPreview.thumbnails), expectedThumbnails)
    }

    func testThatItDecodesCorrectMediaPreview_MultipleItems() throws {
        // given
        let response = mockYouTubeResponse("multiple_videos")

        // when
        let mediaPreview = try service.makeVideoMediaPreview(from: response)

        // then
        XCTAssertEqual(mediaPreview.title, "NFL | Super Bowl LI Halftime Show")

        let expectedThumbnails: Set<MediaThumbnail> = [
            thumbnail("https://i.ytimg.com/vi/txXwg712zw4/default.jpg", width: 120, height: 90)
        ]

        XCTAssertEqual(Set(mediaPreview.thumbnails), expectedThumbnails)
    }

    func testThatItFailsDecoding_MissingItems() throws {
        // given
        let response = mockYouTubeResponse("no_items")

        // then
        XCTAssertThrowsError(try service.makeVideoMediaPreview(from: response)) {
            XCTAssertTrue($0 is DecodingError)
        }
    }

    func testThatItFailsDecoding_MissingSnippet() throws {
        // given
        let response = mockYouTubeResponse("no_snippet")

        // then
        XCTAssertThrowsError(try service.makeVideoMediaPreview(from: response)) {
            XCTAssertTrue($0 as? YouTubeServiceError == .invalidResponse)
        }
    }

    // MARK: - Resources

    private func mockYouTubeResponse(_ name: String) -> Data {
        let fileURL = Bundle(for: YouTubeServiceTests.self).url(forResource: "yt_response_\(name)", withExtension: "json")!
        return try! Data(contentsOf: fileURL)
    }

    private func thumbnail(_ path: String, width: Int, height: Int) -> MediaThumbnail {
        return MediaThumbnail(url: URL(string: path)!, size: CGSize(width: width, height: height))
    }

}
