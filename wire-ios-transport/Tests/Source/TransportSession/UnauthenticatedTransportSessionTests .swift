//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


import WireTesting
@testable import WireTransport


private class MockTask: DataTaskProtocol {

    var resumeCallCount = 0

    func resume() {
        resumeCallCount += 1
    }

}


private class MockURLSession: SessionProtocol {

    var recordedRequest: URLRequest?
    var recordedCompletionHandler: ((Data?, URLResponse?, Error?) -> Void)?
    var nextCompletionParameters: (Data?, URLResponse?, Error?)?
    var nextMockTask: MockTask?

    func task(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> DataTaskProtocol {
        recordedRequest = request
        recordedCompletionHandler = completionHandler
        if let params = nextCompletionParameters {
            completionHandler(params.0, params.1, params.2)
        }
        return nextMockTask ?? MockTask()
    }

}

private class MockReachability: NSObject, ReachabilityProvider, TearDownCapable {

    let mayBeReachable = true
    let isMobileConnection = true
    let oldMayBeReachable = true
    let oldIsMobileConnection = true
    
    func tearDown() {}
    func add(_ observer: ZMReachabilityObserver, queue: OperationQueue?) -> Any { return NSObject() }
    func addReachabilityObserver(on queue: OperationQueue?, block: @escaping ReachabilityObserverBlock) -> Any {
        return NSObject()
    }
    
}

@objcMembers
class MockCertificateTrust: NSObject, BackendTrustProvider {
    
    var isTrustingServer: Bool = true
    
    func verifyServerTrust(trust: SecTrust, host: String?) -> Bool {
        return isTrustingServer
    }
}

final class UnauthenticatedTransportSessionTests: ZMTBaseTest {

    private var sut: UnauthenticatedTransportSession!
    private var sessionMock: MockURLSession!
    private let url = URL(string: "http://base.example.com")!

    override func setUp() {
        super.setUp()
        sessionMock = MockURLSession()
        let endpoints = BackendEndpoints(backendURL: url,
                                         backendWSURL: url,
                                         blackListURL: url,
                                         teamsURL: url,
                                         accountsURL: url,
                                         websiteURL: url,
                                         countlyURL: url)
        let trust = MockCertificateTrust()
        let environment = BackendEnvironment(title: name, environmentType: .production, endpoints: endpoints, certificateTrust: trust)
        sut = UnauthenticatedTransportSession(environment: environment,
                                              urlSession: sessionMock,
                                              reachability: MockReachability(),
                                              applicationVersion: "1.0")
    }

    override func tearDown() {
        sessionMock = nil
        sut = nil
        super.tearDown()
    }
    
    func testThatEnqueueOneTime_IncrementsTheRequestCounter() {
        // when
        (0..<3).forEach { _ in
            sut.enqueueOneTime(.init(getFromPath: "/", apiVersion: 0))
        }
        
        // then
        let result = sut.enqueueRequest { .init(getFromPath: "/", apiVersion: 0) }
        XCTAssertEqual(result, .maximumNumberOfRequests)
    }
    
    func testThatEnqueueOneTime_IsNotLimitedByRequestLimit() {
        // given
        (0..<3).forEach { _ in
            sut.enqueueOneTime(.init(getFromPath: "/", apiVersion: 0))
        }
        
        let task = MockTask()
        sessionMock.nextMockTask = task
        
        // when
        sut.enqueueOneTime(.init(getFromPath: "/", apiVersion: 0))
        
        // then
        XCTAssertEqual(task.resumeCallCount, 1)
    }

    func testThatItEnqueuesANonNilRequestAndReturnsTheCorrectResult() {
        // given
        let task = MockTask()
        sessionMock.nextMockTask = task

        // when
        let result = sut.enqueueRequest { .init(getFromPath: "/", apiVersion: 0) }

        // then
        XCTAssertEqual(result, .success)
        XCTAssertEqual(task.resumeCallCount, 1)
    }

    func testThatItReturnsTheCorrectResultForNilRequests() {
        // when
        let result = sut.enqueueRequest { nil }

        // then
        XCTAssertEqual(result, .nilRequest)
    }

    func testThatItDoesNotEnqueueMoreThanThreeRequests() {
        // when
        (0..<3).forEach { _ in
            let result = sut.enqueueRequest { .init(getFromPath: "/", apiVersion: 0) }
            XCTAssertEqual(result, .success)
        }

        // then
        let result = sut.enqueueRequest { .init(getFromPath: "/", apiVersion: 0) }
        XCTAssertEqual(result, .maximumNumberOfRequests)
    }

    func testThatItDoesEnqueueAnotherRequestAfterTheLastOneHasBeenCompleted() {
        // when
        (0..<3).forEach { _ in
            let result = sut.enqueueRequest { .init(getFromPath: "/", apiVersion: 0) }
            XCTAssertEqual(result, .success)
        }

        guard let lastCompletion = sessionMock.recordedCompletionHandler else { return XCTFail("No completion handler") }

        // then
        do {
            let result = sut.enqueueRequest { .init(getFromPath: "/", apiVersion: 0) }
            XCTAssertEqual(result, .maximumNumberOfRequests)
        }

        // when
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)
        lastCompletion(nil, response, nil)

        // then
        do {
            let result = sut.enqueueRequest { .init(getFromPath: "/", apiVersion: 0) }
            XCTAssertEqual(result, .success)
        }
    }

    func testThatItCallsTheRequestsCompletionHandler() {
        // given
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)
        sessionMock.nextCompletionParameters = (nil, response, nil)
        let completionExpectation = expectation(description: "Completion handler should be called")
        let request = ZMTransportRequest(getFromPath: "/", apiVersion: 0)

        request.add(ZMCompletionHandler(on: fakeUIContext) { response in
            // then
            XCTAssertEqual(response.httpStatus, 200)
            completionExpectation.fulfill()
        })

        // when
        let result = sut.enqueueRequest { request }
        XCTAssert(waitForCustomExpectations(withTimeout: 0.1))

        // then
        XCTAssertEqual(result, .success)
    }

    func testThatPostsANewRequestAvailableNotificationAfterCompletingARunningRequest() {
        // given && then
        _ = expectation(
            forNotification: NSNotification.Name(rawValue: NSNotification.Name.ZMTransportSessionNewRequestAvailable.rawValue),
            object: nil,
            handler: nil
        )

        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        sessionMock.nextCompletionParameters = (nil, response, nil)
        let request = ZMTransportRequest(getFromPath: "/", apiVersion: 0)

        // when
        _ = sut.enqueueRequest { request }
        XCTAssert(waitForCustomExpectations(withTimeout: 0.1))

    }

    func testWrongURLResponseError() {
        // given
        let response = URLResponse(url: url, mimeType: "", expectedContentLength: 1, textEncodingName: nil)
        sessionMock.nextCompletionParameters = (nil, response, NSError.requestExpiredError())
        let completionExpectation = expectation(description: "Completion handler should be called with errors")
        let request = ZMTransportRequest(getFromPath: "/", apiVersion: 0)
        
        request.add(ZMCompletionHandler(on: fakeUIContext) { response in
            // then
            XCTAssertFalse(response.rawResponse == nil)
            XCTAssertFalse(response.transportSessionError == nil)
            completionExpectation.fulfill()
        })
        
        // when
        let result = sut.enqueueRequest { request }
        XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        
        // then
        XCTAssertEqual(result, .success)
    }
}

enum TestError: Error {
    case genericError
}
