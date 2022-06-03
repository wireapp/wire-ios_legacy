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

class LinkAttachmentDetectorTests: XCTestCase {

    var sut: LinkAttachmentDetector!
    var mockImageTask: MockURLSessionDataTask!
    var previewDownloader: MockPreviewDownloader!

    override func setUp() {
        super.setUp()
        mockImageTask = MockURLSessionDataTask()
        previewDownloader = MockPreviewDownloader()
        sut = LinkAttachmentDetector(
            previewDownloader: previewDownloader,
            workerQueue: .main
        )
    }

    override func tearDown() {
        mockImageTask = nil
        previewDownloader = nil
        sut = nil
        super.tearDown()
    }

    func testThatItCallsTeardownAfterDeallocating() {
        // given
        XCTAssertFalse(previewDownloader.tornDown)

        // when
        sut = nil

        // then
        XCTAssertTrue(previewDownloader.tornDown)
    }

    func testThatItCallsTheCompletionWithAnEmptyArrayWhenThereIsNoLinkInTheText() {
        // given
        let text = "This is a sample containing no link"
        let completionExpectation = expectation(description: "It calls the completion closure")

        // when
        var result = [LinkAttachment]()
        sut.downloadLinkAttachments(inText: text) {
            result = $0
            completionExpectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 0.2, handler: nil)
        XCTAssertEqual(previewDownloader.requestOpenGraphDataCallCount, 0)
        XCTAssertEqual(result, [])
    }

    func testThatItDoesNotRequestToDownloadTheOpenGraphDataWhenThereIsANonAttachmentLink() {
        // given
        let text = "This is a sample containing a link: www.example.com"

        // when
        sut.downloadLinkAttachments(inText: text) { _ in }

        // then
        XCTAssertEqual(previewDownloader.requestOpenGraphDataCallCount, 0)
        XCTAssertEqual(previewDownloader.requestOpenGraphDataURLs, [])
    }

    func testThatItReturnsAnEmptyArrayIfThePreviewDownloaderReturnsANilOpenGraphData() {
        // given
        let text = "This is a sample containing a link: youtube.com/watch?v=cggNqDAtJYU"
        let completionExpectation = expectation(description: "It calls the completion closure")

        // when
        var result = [LinkAttachment]()
        sut.downloadLinkAttachments(inText: text) {
            result = $0
            completionExpectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 0.2, handler: nil)
        XCTAssertEqual(previewDownloader.requestOpenGraphDataCallCount, 1)
        XCTAssertEqual(previewDownloader.requestOpenGraphDataURLs, [URL(string: "http://youtube.com/watch?v=cggNqDAtJYU")!])
        XCTAssertEqual(result, [])
    }

    func testThatItRequestsToDownloadTheImageDataWhenThereIsALinkAndThePreviewDownloaderReturnsOpenGraphData() {
        // given
        let text = "This is a sample containing a link: youtube.com/watch?v=cggNqDAtJYU"
        let completionExpectation = expectation(description: "It calls the completion closure")
        let openGraphData = OpenGraphMockDataProvider.youtubeData().expected!
        previewDownloader.mockOpenGraphData = openGraphData

        // when
        var result = [LinkAttachment]()
        sut.downloadLinkAttachments(inText: text) {
            result = $0
            completionExpectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 0.2, handler: nil)

        guard let attachment = result.first else { return XCTFail("Wrong preview type") }
        XCTAssertEqual(attachment.type, .youTubeVideo)
        XCTAssertEqual(attachment.thumbnails.first?.absoluteString, openGraphData.imageUrls.first)
        XCTAssertEqual(attachment.permalink.absoluteString, openGraphData.url)
        XCTAssertEqual(attachment.originalRange.location, 36)
    }

    func testThatItRequestsToDownloadOnlyTheFirstImageDataWhenThereIsALinkAndThePreviewDownloaderReturnsOpenGraphData() {
        // given
        let text = "This is a sample containing a link: youtube.com/watch?v=cggNqDAtJYU"
        let completionExpectation = expectation(description: "It calls the completion closure")
        let openGraphData = OpenGraphMockDataProvider.youtubeData().expected!
        previewDownloader.mockOpenGraphData = openGraphData

        // when
        var result = [LinkAttachment]()
        sut.downloadLinkAttachments(inText: text) {
            result = $0
            completionExpectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 0.2, handler: nil)

        guard let attachment = result.first else { return XCTFail("Wrong preview type") }
        XCTAssertEqual(attachment.type, .youTubeVideo)
        XCTAssertEqual(attachment.thumbnails.first?.absoluteString, openGraphData.imageUrls.first)
        XCTAssertEqual(attachment.permalink.absoluteString, openGraphData.url)
        XCTAssertEqual(attachment.originalRange.location, 36)
    }

    func testThatItCallsTheCompletionClosureOnTheResultsQueue_LinkInText_NoData() {
        let text = "This is a sample containing a link: youtube.com/watch?v=cggNqDAtJYU"
        assertThatItCallsTheCompletionClosure(withText: text)
    }

    func testThatItCallsTheCompletionClosureOnTheResultsQueue_LinkInText_Data() {
        let text = "This is a sample containing a link: youtube.com/watch?v=cggNqDAtJYU"
        previewDownloader.mockOpenGraphData = OpenGraphMockDataProvider.youtubeData().expected!
        assertThatItCallsTheCompletionClosure(withText: text)
    }

    func testThatItCallsTheCompletionClosureOnTheResultsQueue_NoLinkInText() {
        let text = "This is a sample not containing a link"
        assertThatItCallsTheCompletionClosure(withText: text)
    }

    func assertThatItCallsTheCompletionClosure(withText text: String, line: UInt = #line) {
        // given
        let queue = OperationQueue()
        sut = LinkAttachmentDetector(previewDownloader: previewDownloader, workerQueue: queue)
        let completionExpectation = expectation(description: "It calls the completion closure")

        // when
        sut.downloadLinkAttachments(inText: text) { _ in
            completionExpectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 0.2, handler: nil)
    }

}
