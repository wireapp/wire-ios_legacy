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

class PreviewDownloaderTests: XCTestCase {

    private let url = URL(string: "https://twitter.com/ericasadun/status/743868311843151872")!
    private var mockSession: MockURLSession! = nil
    private var mockDataTask: MockURLSessionDataTask! = nil
    private var sut: PreviewDownloader! = nil

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        mockDataTask = MockURLSessionDataTask()
        mockDataTask.mockOriginalRequest = URLRequest(url: url)
        mockSession.mockDataTask = mockDataTask
        sut = PreviewDownloader(resultsQueue: .main, parsingQueue: .main, urlSession: mockSession)
    }

    override func tearDown() {
        mockSession = nil
        mockDataTask = nil
        sut = nil
        super.tearDown()
    }

    func testThatItInvalidatesSessionAfterTearDown() {
        // given
        XCTAssertFalse(mockSession.invalidated)

        // when
        sut.tearDown()

        // then
        XCTAssertTrue(mockSession.invalidated)
    }

    func testThatItAsksTheSessionForADataTaskWhenOpenGraphDataIsRequested() {
        // given
        let completion: PreviewDownloader.DownloadCompletion = { _ in }

        // when
        sut.requestOpenGraphData(fromURL: url, completion: completion)

        // then
        XCTAssertEqual(mockSession.dataTaskWithURLCallCount, 1)
        XCTAssertEqual(mockSession.dataTaskWithURLParameters.first?.url, url)
        XCTAssertEqual(mockDataTask.resumeCallCount, 1)
        XCTAssertNotNil(sut.completionByURL[url])
    }

    func testThatItAppendsReceivedBytesToContainerForDataTask() {
        // given
        let taskID = 0
        let firstBytes = "First Part".data(using: String.Encoding.utf8)!
        let secondBytes = "Second Part".data(using: String.Encoding.utf8)!

        // when
        sut.processReceivedData(firstBytes, forTask: mockDataTask, withIdentifier: taskID)

        // then
        guard let container = sut.containerByTaskID[taskID] else { return XCTFail("container is nil") }
        XCTAssertEqual(container.bytes, firstBytes)

        // when
        sut.processReceivedData(secondBytes, forTask: mockDataTask, withIdentifier: taskID)

        // then
        var appended = firstBytes
        appended.append(secondBytes)
        XCTAssertEqual(container.bytes, appended)
    }

    func testThatItCancelsTheDataTaskAndCallsTheCompletionHandlerIfTheHeaderEnded() {
        // given
        let completionExpectation = expectation(description: "It should call the completion handler")
        var completionCallCount = 0
        let completion: PreviewDownloader.DownloadCompletion = { _ in
            completionCallCount += 1
            completionExpectation.fulfill()
        }
        let taskID = 0
        let firstBytes = " First Part\n ".data(using: String.Encoding.utf8)!
        let secondBytes = " </head> ".data(using: String.Encoding.utf8)!

        // when
        sut.requestOpenGraphData(fromURL: url, completion: completion)
        sut.processReceivedData(firstBytes, forTask: mockDataTask, withIdentifier: taskID)

        // then
        XCTAssertEqual(mockDataTask.cancelCallCount, 0)

        // when
        sut.processReceivedData(secondBytes, forTask: mockDataTask, withIdentifier: taskID)

        // then
        waitForExpectations(timeout: 0.2, handler: nil)
        XCTAssertEqual(mockDataTask.cancelCallCount, 1)
        XCTAssertEqual(completionCallCount, 1)
    }

    func testThatItCallsTheCompletionHandler_IfThereIsNoClosingHeadTag_AndTheDataTaskIsCompleted() {
        // given
        let completionExpectation = expectation(description: "It should call the completion handler")
        var completionCallCount = 0
        let completion: PreviewDownloader.DownloadCompletion = { _ in
            completionCallCount += 1
            completionExpectation.fulfill()
        }
        let taskID = 0
        let firstBytes = " First Part\n ".data(using: String.Encoding.utf8)!
        let secondBytes = " Second Part\n ".data(using: String.Encoding.utf8)!

        // when
        sut.requestOpenGraphData(fromURL: url, completion: completion)
        sut.processReceivedData(firstBytes, forTask: mockDataTask, withIdentifier: taskID)

        // then
        XCTAssertEqual(mockDataTask.cancelCallCount, 0)
        XCTAssertEqual(mockDataTask.state, .running)
        XCTAssertEqual(completionCallCount, 0)

        // when
        mockDataTask.state = .completed
        sut.processReceivedData(secondBytes, forTask: mockDataTask, withIdentifier: taskID)

        // then
        waitForExpectations(timeout: 0.2, handler: nil)
        XCTAssertEqual(mockDataTask.cancelCallCount, 0)
        XCTAssertEqual(completionCallCount, 1)
    }

    func testThatItRemovesTheCompletionBlockAndDataContainerOnCompletion_Unsuccessful() {
        // given
        let completionExpectation = expectation(description: "It should call the completion handler")
        let completion: PreviewDownloader.DownloadCompletion = { _ in completionExpectation.fulfill() }
        let taskID = 0
        let firstBytes = " </head> ".data(using: String.Encoding.utf8)!

        // when
        sut.requestOpenGraphData(fromURL: url, completion: completion)
        sut.processReceivedData(firstBytes, forTask: mockDataTask, withIdentifier: taskID)

        // then
        waitForExpectations(timeout: 0.2, handler: nil)
        XCTAssertEqual(mockDataTask.cancelCallCount, 1)
        XCTAssertNil(sut.completionByURL[url])
        XCTAssertNil(sut.containerByTaskID[taskID])
    }

    func testThatItCallsTheCompletionAndCleansUpIfItReceivesANetworkError() {
        // given
        let completionExpectation = expectation(description: "It should call the completion handler")
        let completion: PreviewDownloader.DownloadCompletion = { _ in completionExpectation.fulfill() }
        let firstBytes = " <head> ".data(using: String.Encoding.utf8)!
        let taskID = 0

        // when
        sut.requestOpenGraphData(fromURL: url, completion: completion)
        let error = NSError(domain: name, code: 0, userInfo: nil)
        sut.processReceivedData(firstBytes, forTask: mockDataTask, withIdentifier: taskID)
        sut.urlSession(mockSession, task: mockDataTask, didCompleteWithError: error)

        // then
        waitForExpectations(timeout: 0.2, handler: nil)
        XCTAssertEqual(mockDataTask.cancelCallCount, 0)
        XCTAssertNil(sut.completionByURL[url])
        XCTAssertNil(sut.containerByTaskID[taskID])
    }

    func testThatItDoesNotCallTheCompletionAndCleansUpIfItReceivesANilError() {
        // given
        let firstBytes = " <head> </head>".data(using: String.Encoding.utf8)!
        let completion: PreviewDownloader.DownloadCompletion = { _ in }
        let taskID = 0

        // when
        sut.requestOpenGraphData(fromURL: url, completion: completion)
        sut.processReceivedData(firstBytes, forTask: mockDataTask, withIdentifier: taskID)
        sut.urlSession(mockSession, task: mockDataTask, didCompleteWithError: nil)

        // then
        XCTAssertEqual(mockDataTask.cancelCallCount, 1)
        XCTAssertNotNil(sut.completionByURL[url])
        XCTAssertNotNil(sut.containerByTaskID[taskID])
    }

    func testThatItDoesntCallTheCompletionWhenRequestIsCancelled() {
        // given
        let error = NSError(domain: NSURLErrorDomain, code: URLError.cancelled.rawValue, userInfo: nil)

        // expect
        let completion: PreviewDownloader.DownloadCompletion = { _ in XCTFail("It should not call the completion handler") }

        // when
        sut.requestOpenGraphData(fromURL: url, completion: completion)
        sut.cancel(task: mockDataTask)
        sut.urlSession(mockSession, task: mockDataTask, didCompleteWithError: error)
    }

    func testThatItCallsTheCompletionHandlerWhenItDidNotReceiveParsableDataNilError() {
        // given
        let firstBytes = Data()
        let completion: PreviewDownloader.DownloadCompletion = { _ in }
        let taskID = 0

        // when
        sut.requestOpenGraphData(fromURL: url, completion: completion)
        sut.processReceivedData(firstBytes, forTask: mockDataTask, withIdentifier: taskID)
        sut.urlSession(mockSession, task: mockDataTask, didCompleteWithError: nil)

        // then
        XCTAssertEqual(mockDataTask.cancelCallCount, 0)
        XCTAssertNil(sut.completionByURL[url])
        XCTAssertNil(sut.containerByTaskID[taskID])
    }

    func testThatItOverridesTheContentTypeOfTheURLSessionUsedForParsing() {
        // given
        let completion: PreviewDownloader.DownloadCompletion = { _ in }

        // when
        sut.requestOpenGraphData(fromURL: url, completion: completion)

        // then
        let expected = "Wire LinkPreview Bot"
        XCTAssertEqual(mockSession.dataTaskWithURLCallCount, 1)
        let request = mockSession.dataTaskWithURLParameters.first
        let agent = request?.allHTTPHeaderFields?["User-Agent"]

        XCTAssertEqual(agent, expected)
        XCTAssertEqual(mockDataTask.resumeCallCount, 1)
        XCTAssertNotNil(sut.completionByURL[url])
    }

    func testThatItCallsTheCompletionHandlerAndCancelsTheRequestIfTheContentTypeOfTheResponseIfNotHTML() {
        assertThatItCallsTheDipositionHandler(.cancel, contentType: "something-other-than-html")
    }

    func testThatItCallsTheCompletionHandlerAndCancelsTheRequestIfTheStatusIsNotSuccessful() {
        assertThatItCallsTheDipositionHandler(.cancel, contentType: "text/html", statusCode: 404)
    }

    func testThatItCallsTheDispositionHandlerWithAllowAndDoesNotCallTheDownloadCompletionForContentTypeHTML() {
        assertThatItCallsTheDipositionHandler(.allow, contentType: "text/html")
    }

    func testThatItCallsTheDispositionHandlerWithAllowAndDoesNotCallTheDownloadCompletionForContentTypeHTMLWithCharset() {
        assertThatItCallsTheDipositionHandler(.allow, contentType: "text/html;charset=utf-8")
    }

    func testThatItCallsTheDispositionHandlerWithAllowAndDoesNotCallTheDownloadCompletionForContentTypeHTMLUppercase() {
        assertThatItCallsTheDipositionHandler(.allow, contentType: "TEXT/HTML")
    }

    func assertThatItCallsTheDipositionHandler(_ expected: URLSession.ResponseDisposition, contentType: String, statusCode: Int = 200, line: UInt = #line) {
        // given
        let downloadExpectation = expectation(description: "It should call the downloader completion handler")
        let sessionExpectation = expectation(description: "It should call the session completion handler")
        let completion: PreviewDownloader.DownloadCompletion = { _ in downloadExpectation.fulfill() }
        let originalRequest = URLRequest(url: URL(string: "www.example.com")!)
        sut.requestOpenGraphData(fromURL: url, completion: completion)
        sut.processReceivedData("bytes".data(using: .utf8)!, forTask: mockDataTask, withIdentifier: 0)

        // when
        let response = HTTPURLResponse(
            url: originalRequest.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": contentType]
        )

        var disposition: URLSession.ResponseDisposition?
        sut.urlSession(sut.session, dataTask: mockDataTask, didReceiveHTTPResponse: response!) {
            disposition = $0
            sessionExpectation.fulfill()
        }

        if expected == .allow {
            downloadExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.2, handler: nil)
        XCTAssertEqual(disposition, expected, line: line)

        if expected == .cancel {
            XCTAssertNil(sut.completionByURL[url], line: line)
            XCTAssertNil(sut.containerByTaskID[mockDataTask.taskIdentifier], line: line)
        } else {
            XCTAssertNotNil(sut.completionByURL[url], line: line)
            XCTAssertNotNil(sut.containerByTaskID[mockDataTask.taskIdentifier], line: line)
        }

    }

}
