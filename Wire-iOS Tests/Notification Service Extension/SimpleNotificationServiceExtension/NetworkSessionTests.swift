//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireTransport

@available(iOS 15, *)
class NetworkSessionTests: XCTestCase {

    var mockURLSession: URLSessionMock!
    var mockNetworkRequest: NetworkRequest!

    override func setUp() {
        super.setUp()

        mockURLSession = URLSessionMock()

        mockNetworkRequest = NetworkRequest(
            path: "test",
            httpMethod: .get,
            contentType: .json,
            acceptType: .json
        )
    }

    override func tearDown() {
        mockURLSession = nil
        mockNetworkRequest = nil
        super.tearDown()
    }

    // MARK: - Send request

    var invalidResponse: (Data, URLResponse) {
        return (Data(), URLResponse())
    }

    var failureResponse: (Data, URLResponse) {
        let JSON = """
        {
            "code": 500,
            "label": "error",
            "message": "server error"
        }
        """

        let response = HTTPURLResponse(
            url: URL(string: "wire.com")!,
            statusCode: 500,
            httpVersion: "",
            headerFields: ["Content-Type": "application/json"]
        )!

        return (JSON.data(using: .utf8)!, response)
    }

    var successResponse: (Data, URLResponse) {
        let response =  HTTPURLResponse(
            url: URL(string: "wire.com")!,
            statusCode: 200,
            httpVersion: "",
            headerFields: ["Content-Type": "application/json"]
        )!

        return (Data([1, 2, 3]), response)
    }

    func test_SendRequest_InvalidRequestURL() async throws {
        // Given
        let sut = try NetworkSession(userID: UUID())

        let invalidRequest = NetworkRequest(
            path: "",
            httpMethod: .get,
            contentType: .json,
            acceptType: .json
        )

        // When
        await assertThrows(expectedError: NetworkSession.NetworkError.invalidRequestURL) {
            _ = try await sut.send(request: invalidRequest)
        }
    }

    func test_SendRequest_InvalidResponse() async throws {
        // Given
        let sut = try NetworkSession(userID: UUID.create(), urlRequestable: mockURLSession)
        mockURLSession.mockedResponse = invalidResponse

        // When
        await assertThrows(expectedError: NetworkSession.NetworkError.invalidResponse) {
            _ = try await sut.send(request: self.mockNetworkRequest)
        }
    }

    func test_SendRequest_InvalidResponseContentType() async throws {
        // Given
        let sut = try NetworkSession(userID: UUID.create(), urlRequestable: mockURLSession)

        let plainTextResponse = HTTPURLResponse(
            url: URL(string: "wire.com")!,
            statusCode: 200,
            httpVersion: "",
            headerFields: ["Content-Type": "Text/plain"]
        )!

        mockURLSession.mockedResponse = (Data(), plainTextResponse)

        // When
        await assertThrows(expectedError: NetworkSession.NetworkError.invalidResponse) {
            _ = try await sut.send(request: self.mockNetworkRequest)
        }
    }

    func test_SendRequest_ErrorResponse() async throws {
        // Given
        let sut = try NetworkSession(userID: UUID.create(), urlRequestable: mockURLSession)
        mockURLSession.mockedResponse = failureResponse

        // When
        let result = try await sut.send(request: mockNetworkRequest)

        // Then
        guard case .failure(let response) = result else {
            XCTFail("expected failure")
            return
        }

        XCTAssertEqual(response.code, 500)
        XCTAssertEqual(response.label, "error")
        XCTAssertEqual(response.message, "server error")
    }

    func test_SendRequest_SuccessResponse() async throws {
        // Given
        let sut = try NetworkSession(userID: UUID(), urlRequestable: mockURLSession)

        sut.accessToken = AccessToken(
            token: "1234",
            type: "type1",
            expiresInSeconds: 10
        )

        mockURLSession.mockedResponse = successResponse

        // When
        let result = try await sut.send(request: mockNetworkRequest)

        // Then
        guard case .success(let response) = result else {
            XCTFail("expected success")
            return
        }

        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.data, Data([1, 2, 3]))

        guard let urlRequest = mockURLSession.calledRequest else {
            XCTFail("unable to get URLRequest")
            return
        }

        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Content-Type"], "application/json")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Accept"], "application/json")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "type1 1234")
    }

}

class MockCookieStorage: CookieProvider {

    var isAuthenticated: Bool = true

    func setRequestHeaderFieldsOn(_ request: NSMutableURLRequest) {}

}

class URLSessionMock: URLRequestable {

    var mockedResponse = (Data(), URLResponse())

    private(set) var calledRequest: URLRequest?

    func data(
        for request: URLRequest,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, URLResponse) {
        calledRequest = request
        return mockedResponse
    }

}
