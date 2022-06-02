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
import WireSyncEngine

class ProxiedRequestStrategyTests: MessagingTest {

    fileprivate var sut: ProxiedRequestStrategy!
    fileprivate var requestsStatus: ProxiedRequestsStatus!
    fileprivate var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()
        self.requestsStatus = ProxiedRequestsStatus(requestCancellation: MockRequestCancellation())
        self.mockApplicationStatus = MockApplicationStatus()
        self.mockApplicationStatus.mockSynchronizationState = .online
        self.sut = ProxiedRequestStrategy(withManagedObjectContext: self.uiMOC, applicationStatus: self.mockApplicationStatus, requestsStatus: self.requestsStatus)
    }

    override func tearDown() {
        self.sut = nil
        self.requestsStatus = nil
        super.tearDown()
    }

    func testThatItGeneratesNoRequestsIfTheStatusIsEmpty() {
        XCTAssertNil(self.sut.nextRequest(for: .v0))
    }

    func testThatItGeneratesAGiphyRequest() {

        // given
        requestsStatus.add(request: ProxyRequest(type: .giphy, path: "/foo/bar", method: .methodGET, callback: { (_, _, _) -> Void in return}))

        // when
        let request: ZMTransportRequest? = self.sut.nextRequest(for: .v0)

        // then
        if let request = request {
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodGET)
            XCTAssertEqual(request.path, "/proxy/giphy/foo/bar")
            XCTAssertTrue(request.needsAuthentication)
        } else {
            XCTFail("Empty request")
        }
    }

    func testThatItGeneratesASoundcloudRequest() {

        // given
        requestsStatus.add(request: ProxyRequest(type: .soundcloud, path: "/foo/bar", method: .methodGET, callback: { (_, _, _) -> Void in return}))

        // when
        let request: ZMTransportRequest? = self.sut.nextRequest(for: .v0)

        // then
        if let request = request {
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodGET)
            XCTAssertEqual(request.path, "/proxy/soundcloud/foo/bar")
            XCTAssertTrue(request.needsAuthentication)
            XCTAssertTrue(request.doesNotFollowRedirects)
        } else {
            XCTFail("Empty request")
        }
    }

    func testThatItGeneratesAYouTubeRequest() {

        // given
        requestsStatus.add(request: ProxyRequest(type: .youTube, path: "/foo/bar", method: .methodGET, callback: { (_, _, _) -> Void in return}))

        // when
        let request: ZMTransportRequest? = self.sut.nextRequest(for: .v0)

        // then
        if let request = request {
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodGET)
            XCTAssertEqual(request.path, "/proxy/youtube/foo/bar")
            XCTAssertTrue(request.needsAuthentication)
        } else {
            XCTFail("Empty request")
        }
    }

    func testThatItGeneratesARequestOnlyOnce() {

        // given
        requestsStatus.add(request: ProxyRequest(type: .giphy, path: "/foo/bar1", method: .methodGET, callback: { (_, _, _) -> Void in return}))

        // when
        let request1: ZMTransportRequest? = self.sut.nextRequest(for: .v0)
        let request2: ZMTransportRequest? = self.sut.nextRequest(for: .v0)

        // then
        XCTAssertNotNil(request1)
        XCTAssertNil(request2)

    }

    func testThatItCallsTheCompletionHandlerWhenTheRequestIsCompleted() {

        // given
        let error = NSError(domain: "ZMTransportSession", code: 10, userInfo: nil)
        let data = "Foobar".data(using: String.Encoding.utf8, allowLossyConversion: true)!
        let HTTPResponse = HTTPURLResponse(url: URL(string: "http://www.example.com/")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [
                "Content-Length": "\(data.count)",
                "Server": "nginx"
            ]
        )!

        let response = ZMTransportResponse(httpurlResponse: HTTPResponse, data: data, error: error, apiVersion: APIVersion.v0.rawValue)
        let expectation = self.expectation(description: "Callback invoked")

        requestsStatus.add(request: ProxyRequest(type: .giphy, path: "/foo/bar1", method: .methodGET, callback: { responseData, responseURLResponse, responseError in
            XCTAssertEqual(data, responseData)
            XCTAssertEqual(error, responseError)
            XCTAssertEqual(HTTPResponse, responseURLResponse)
            expectation.fulfill()

            return
        }))

        // when
        let request: ZMTransportRequest? = self.sut.nextRequest(for: .v0)
        if let request = request {
            request.complete(with: response)
        }

        // then
        self.spinMainQueue(withTimeout: 0.2)
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItMakesTheRequestExpireAfter20Seconds() {

        // given
        let ExpectedDelay: TimeInterval = 20
        requestsStatus.add(request: ProxyRequest(type: .giphy, path: "/foo/bar1", method: .methodGET, callback: { (_, _, _) -> Void in return}))

        // when
        let request: ZMTransportRequest? = self.sut.nextRequest(for: .v0)

        // then
        if let request = request {
            XCTAssertNotNil(request.expirationDate)
            let delay = request.expirationDate!.timeIntervalSinceNow
            XCTAssertLessThanOrEqual(delay, ExpectedDelay)
            XCTAssertGreaterThanOrEqual(delay, ExpectedDelay - 3)

        } else {
            XCTFail("Empty request")
        }
    }

    func testThatItUpdateTheRequestStatusWhenTaskIsCreated() {

        // given
        let proxyRequest = ProxyRequest(type: .giphy, path: "/foo/bar1", method: .methodGET, callback: { (_, _, _) -> Void in return})
        requestsStatus.add(request: proxyRequest)
        let request: ZMTransportRequest? = self.sut.nextRequest(for: .v0)

        // when
        request?.callTaskCreationHandlers(withIdentifier: 1, sessionIdentifier: "123")

        // then
        self.spinMainQueue(withTimeout: 0.2)
        let (executedRequest, taskIdentifier) = requestsStatus.executedRequests.first!
        XCTAssertEqual(proxyRequest, executedRequest)
        XCTAssertEqual(taskIdentifier.identifier, 1)
        XCTAssertEqual(taskIdentifier.sessionIdentifier, "123")

    }
}
