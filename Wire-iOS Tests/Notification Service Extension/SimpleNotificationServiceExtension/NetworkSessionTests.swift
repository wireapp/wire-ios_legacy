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
    var networkRequestMock: NetworkRequest!

    override func setUp() {
        networkRequestMock = NetworkRequest(path: "test", httpMethod: .get, contentType: .json, acceptType: .json)
        super.setUp()
    }

    override func tearDown() {
        networkRequestMock = nil
        super.tearDown()
    }

    func testErrorWhenIncorrectPath() async {
        let request = NetworkRequest(path: "", httpMethod: .get, contentType: .json, acceptType: .json)
        do {
            let sut = try NetworkSession(userID: UUID())
            _ = try await sut.send(request: request)
        } catch NetworkSession.NetworkError.invalidRequestURL {
            return
        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }
        XCTFail("Request passed with incorrect URL")
    }

    func testErrorWhenInvalidResponse() async {
        do {
            let sut = try NetworkSession(userID: UUID(), urlRequestable: URLSessionMock())
            _ = try await sut.send(request: networkRequestMock)
        } catch NetworkSession.NetworkError.invalidResponse {
            return
        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }
        XCTFail("Request passed with incorrect Response")
    }

    func testErrorWhenIncorrectResponseContent() async throws {
        let reqestable = URLSessionMock()
        let response = HTTPURLResponse(url: URL(string: "wire.com")!,
                                       statusCode: 200,
                                       httpVersion: "",
                                       headerFields: ["Content-Type": "Text/plain"])!
        reqestable.mockedResponse = (Data(), response)

        do {
            let sut = try NetworkSession(userID: UUID(), urlRequestable: reqestable)
            _ = try await sut.send(request: networkRequestMock)
        } catch NetworkSession.NetworkError.invalidResponse {
            return
        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }
        XCTFail("Request passed with incorrect content-type")
    }

    func testFailureWhenErrorResponse() async throws {
        let reqestable = URLSessionMock()
        reqestable.mockedResponse = reqestable.failureResponse
        let sut = try NetworkSession(userID: UUID(), urlRequestable: reqestable)
        let result = try await sut.send(request: networkRequestMock)
        guard case .failure(_) = result else {
            XCTFail()
            return
        }
    }

    func testSuccessResponse() async throws {
        let reqestable = URLSessionMock()
        reqestable.mockedResponse = reqestable.successResponse
        let sut = try NetworkSession(userID: UUID(), urlRequestable: reqestable)
        let result = try await sut.send(request: networkRequestMock)
        guard case .success(_) = result else {
            XCTFail()
            return
        }
    }

    func testRequestHeaders() async throws {
        let request = NetworkRequest(path: "test", httpMethod: .get, contentType: .json, acceptType: .json)
        let requestable = URLSessionMock()
        requestable.mockedResponse = requestable.successResponse
        do {
            let sut = try NetworkSession(userID: UUID(), urlRequestable: requestable)
            sut.accessToken =  AccessToken(token: "1234", type: "type1", expiresInSeconds: 123456789)
            _ = try await sut.send(request: request)
            guard let urlRequest = requestable.calledRequest else {
                XCTFail()
                return
            }

            XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Content-Type"], "application/json")
            XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Accept"], "application/json")
            XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "type1 1234")
        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }
    }
}


class CookieStorageMock: CookieProvider {
    func setRequestHeaderFieldsOn(_ request: NSMutableURLRequest) {
    }

    var isAuthenticated: Bool = true
}

class URLSessionMock: URLRequestable {
    var mockedResponse: (Data, URLResponse) = (Data(), URLResponse())
    private(set) var calledRequest: URLRequest?
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        calledRequest = request
        return mockedResponse
    }

    var failureResponse: (Data, URLResponse)  {
        let JSON = """
        {
            "code": 500,
            "label": "error",
            "message": "server error"
        }
        """
        let response =  HTTPURLResponse(url: URL(string: "wire.com")!,
                                        statusCode: 500,
                                        httpVersion: "",
                                        headerFields: ["Content-Type": "application/json"])!
        return (JSON.data(using: .utf8)!, response)
    }
    var successResponse: (Data, URLResponse)  {
        let JSON = """
        """
        let response =  HTTPURLResponse(url: URL(string: "wire.com")!,
                                        statusCode: 200,
                                        httpVersion: "",
                                        headerFields: ["Content-Type": "application/json"])!
        return (JSON.data(using: .utf8)!, response)
    }

}
