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

class ImageDownloadCacheTests: XCTestCase {

    var cache: URLCache!
    var session: MockURLSession!
    var imageDownloadCache: ImageDownloadCache!

    override func setUp() {
        super.setUp()
        cache = URLCache(memoryCapacity: 100 * 1024 * 1024, diskCapacity: 0, diskPath: nil)
        session = MockURLSession(cache: cache)
        imageDownloadCache = ImageDownloadCache(session: session)
    }

    override func tearDown() {
        cache.removeAllCachedResponses()
        cache = nil
        session = nil
        imageDownloadCache = nil
        super.tearDown()
    }

    func testThatItFetchesImageWithCacheHeader() {
        // GIVEN
        let imageURL = URL(string: "https://example.com/image.png")!
        let imageData = loadTestImageData()
        let httpResponse = makeSuccessResponseWithCache(for: imageURL)

        session.scheduleResponse(.success(imageData, httpResponse), for: imageURL)

        // WHEN

        var image: UIImage? = nil
        var error: Error? = nil
        let downloadExpectation = expectation(description: "The image is downloaded")

        imageDownloadCache.fetchImage(at: imageURL) { downloadedImage, downloadError in
            image = downloadedImage
            error = downloadError
            downloadExpectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNotNil(image)
        XCTAssertNil(error)

        let cachedResponse = cache.cachedResponse(for: URLRequest(url: imageURL))
        XCTAssertEqual(cachedResponse?.data, imageData)
    }

    func testThatItFetchesImageWithoutCacheHeader() {
        // GIVEN
        let imageURL = URL(string: "https://example.com/image.png")!
        let imageData = loadTestImageData()
        let httpResponse = makeSuccessResponseWithoutCache(for: imageURL)

        session.scheduleResponse(.success(imageData, httpResponse), for: imageURL)

        // WHEN

        var image: UIImage? = nil
        var error: Error? = nil
        let downloadExpectation = expectation(description: "The image is downloaded")

        imageDownloadCache.fetchImage(at: imageURL) { downloadedImage, downloadError in
            image = downloadedImage
            error = downloadError
            downloadExpectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNotNil(image)
        XCTAssertNil(error)

        let cachedResponse = cache.cachedResponse(for: URLRequest(url: imageURL))
        XCTAssertNil(cachedResponse)
    }

    func testThatItReturns404ErrorIfImageIsNotFound() {
        // GIVEN
        let imageURL = URL(string: "https://example.com/image.png")!
        let imageData = Data()
        let httpResponse = make404ResponseWithCache(for: imageURL)

        session.scheduleResponse(.success(imageData, httpResponse), for: imageURL)

        // WHEN

        var image: UIImage? = nil
        var error: Error? = nil
        let downloadExpectation = expectation(description: "The image is downloaded")

        imageDownloadCache.fetchImage(at: imageURL) { downloadedImage, downloadError in
            image = downloadedImage
            error = downloadError
            downloadExpectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNil(image)
        XCTAssertTrue((error as? ImageDownloadCacheError) == .invalidResponseCode(404))

        let cachedResponse = cache.cachedResponse(for: URLRequest(url: imageURL))
        XCTAssertNil(cachedResponse)
    }

    func testThatItForwardsSessionErrorToCompletionHandler() {
        // GIVEN
        let imageURL = URL(string: "https://example.com/image.png")!
        session.scheduleResponse(.error(MockURLSessionError.noNetwork), for: imageURL)

        // WHEN

        var image: UIImage? = nil
        var error: Error? = nil
        let downloadExpectation = expectation(description: "The image is downloaded")

        imageDownloadCache.fetchImage(at: imageURL) { downloadedImage, downloadError in
            image = downloadedImage
            error = downloadError
            downloadExpectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNil(image)
        XCTAssertTrue((error as? MockURLSessionError) == .noNetwork)

        let cachedResponse = cache.cachedResponse(for: URLRequest(url: imageURL))
        XCTAssertNil(cachedResponse)
    }

    // MARK: - Utilities

    private func loadTestImageData() -> Data {
        let url = Bundle(for: DecodeImageOperationTests.self).url(forResource: "identicon", withExtension: "png")!
        return try! Data(contentsOf: url)
    }

    private func loadTestFileData() -> Data {
        let url = Bundle(for: DecodeImageOperationTests.self).url(forResource: "0x0", withExtension: "pdf")!
        return try! Data(contentsOf: url)
    }

    private func makeSuccessResponseWithCache(for url: URL) -> HTTPURLResponse {
        return HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Cache-Control": "max-age=3600"])!
    }

    private func makeSuccessResponseWithoutCache(for url: URL) -> HTTPURLResponse {
        return HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
    }

    private func make404ResponseWithCache(for url: URL) -> HTTPURLResponse {
        return HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: ["Cache-Control": "max-age=3600"])!
    }

}
