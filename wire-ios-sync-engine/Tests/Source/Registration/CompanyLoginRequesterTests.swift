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
@testable import WireSyncEngine

class CompanyLoginRequesterTests: XCTestCase {

    func testThatItGeneratesLoginURLForToken() {
        // GIVEN
        let defaults = UserDefaults(suiteName: name)!
        let requester: CompanyLoginRequester = CompanyLoginRequester(
            callbackScheme: "wire",
            defaults: defaults
        )

        let userID = UUID(uuidString: "A0ACF9C2-2000-467F-B640-14BF4FCCC87A")!

        // WHEN
        var url: URL?
        let callbackExpectation = expectation(description: "Requester calls delegate to handle URL")

        let delegate = MockCompanyLoginRequesterDelegate {
            url = $0
            callbackExpectation.fulfill()
        }

        requester.delegate = delegate
        requester.requestIdentity(host: "localhost", token: userID)
        waitForExpectations(timeout: 1, handler: nil)

        guard let validationToken = CompanyLoginVerificationToken.current(in: defaults) else { return XCTFail("no token") }
        let validationIdentifier = validationToken.uuid.transportString()
        let expectedURL = URL(string: "https://localhost/sso/initiate-login/\(userID)?success_redirect=wire://login/success?cookie=$cookie&userid=$userid&validation_token=\(validationIdentifier)&error_redirect=wire://login/failure?label=$label&validation_token=\(validationIdentifier)")!

        // THEN
        guard let validationURL = url else {
           return XCTFail("The requester did not call the delegate.")
        }

        guard let components = URLComponents(url: validationURL, resolvingAgainstBaseURL: false) else {
            return XCTFail("The requester did not request to open a valid URL.")
        }

        XCTAssertEqual(components.query(for: "success_redirect"), "wire://login/success?cookie=$cookie&userid=$userid&validation_token=\(validationIdentifier)")
        XCTAssertEqual(components.query(for: "error_redirect"), "wire://login/failure?label=$label&validation_token=\(validationIdentifier)")
        XCTAssertEqual(validationURL.absoluteString.removingPercentEncoding, expectedURL.absoluteString)
    }

    func testThatItReturnsNilWhenVerifyingTokenNoError() {
        // Given
        let session = MockSession { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (nil, response, nil)
        }

        let sut = CompanyLoginRequester(
            callbackScheme: "wire",
            defaults: UserDefaults(suiteName: name)!,
            session: session
        )

        let callbackExpectation = expectation(description: "The completion closure is called")

        // When
        sut.validate(host: "localhost", token: .create()) { error in
            XCTAssertNil(error)
            callbackExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testThatItReturnsInvalidCodeErrorFor404Response() {
        // Given
        let session = MockSession { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)
            return (nil, response, nil)
        }

        let sut = CompanyLoginRequester(
            callbackScheme: "wire",
            defaults: UserDefaults(suiteName: name)!,
            session: session
        )

        let callbackExpectation = expectation(description: "The completion closure is called")

        // When
        sut.validate(host: "localhost", token: .create()) { error in
            XCTAssertEqual(error, .invalidCode)
            callbackExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testThatItReturnsUnknownErrorForServerError() {
        // Given
        let session = MockSession { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)
            return (nil, response, nil)
        }

        let sut = CompanyLoginRequester(
            callbackScheme: "wire",
            defaults: UserDefaults(suiteName: name)!,
            session: session
        )

        let callbackExpectation = expectation(description: "The completion closure is called")

        // When
        sut.validate(host: "localhost", token: .create()) { error in
            XCTAssertEqual(error, .invalidStatus(500))
            callbackExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testThatItReturnsUnknownErrorForTransportError() {
        // Given
        let session = MockSession { _ in
            let error = NSError(domain: "", code: NSURLErrorTimedOut, userInfo: nil)
            return (nil, nil, error)
        }

        let sut = CompanyLoginRequester(
            callbackScheme: "wire",
            defaults: UserDefaults(suiteName: name)!,
            session: session
        )

        let callbackExpectation = expectation(description: "The completion closure is called")

        // When
        sut.validate(host: "localhost", token: .create()) { error in
            XCTAssertEqual(error, .unknown)
            callbackExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testThatItReturnsUnknownErrorForInvalidResponse() {
        // Given
        let session = MockSession { _ in (nil, nil, nil) }

        let sut = CompanyLoginRequester(
            callbackScheme: "wire",
            defaults: UserDefaults(suiteName: name)!,
            session: session
        )

        let callbackExpectation = expectation(description: "The completion closure is called")

        // When
        sut.validate(host: "localhost", token: .create()) { error in
            XCTAssertEqual(error, .unknown)
            callbackExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)
    }

}

// MARK: - Helper

private class MockSession: NSObject, URLSessionProtocol {

    class MockURLSessionDataTask: URLSessionDataTask {
        override func resume() {
            // no-op
        }
    }

    typealias RequestHandler = (URLRequest) -> (Data?, URLResponse?, Error?)
    let handler: RequestHandler

    init(handler: @escaping RequestHandler) {
        self.handler = handler
        super.init()
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let (data, response, error) = handler(request)
        completionHandler(data, response, error)
        return MockURLSessionDataTask()
    }

}
