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

import Foundation
@testable import WireRequestStrategy

class GetPushTokensActionHandlerTests: MessagingTestBase {

    // MARK: - Helpers

    typealias Payload = GetPushTokensActionHandler.ResponsePayload
    typealias Token = GetPushTokensActionHandler.Token

    func token(clientID: String, data: Data, type: String) -> Token {
        return Token(app: "app", client: clientID, token: data.zmHexEncodedString(), transport: type)
    }

    func response(payload: GetPushTokensActionHandler.ResponsePayload, status: Int) -> ZMTransportResponse {
        let data = try! JSONEncoder().encode(payload)
        let payloadAsString = String(bytes: data, encoding: .utf8)!
        return response(payload: payloadAsString as ZMTransportData, status: status)
    }

    func response(payload: ZMTransportData?, status: Int) -> ZMTransportResponse {
        return ZMTransportResponse(
            payload: payload,
            httpStatus: status,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    // MARK: - Request generation

    func test_itGeneratesARequest() throws {
        // Given
        let sut = GetPushTokensActionHandler(context: syncMOC)
        let action = GetPushTokensAction(clientID: "clientID")

        // When
        let request = try XCTUnwrap(sut.request(for: action, apiVersion: .v0))

        // Then
        XCTAssertEqual(request.path, "/push/tokens")
        XCTAssertEqual(request.method, .methodGET)
    }

    // MARK: - Response handling

    func test_itHandlesResponse_200() throws {
        // Given
        let sut = GetPushTokensActionHandler(context: syncMOC)
        var action = GetPushTokensAction(clientID: "clientA")

        // Expectation
        let didSucceed = expectation(description: "didSucceed")
        var receivedTokens = [PushToken]()

        action.onResult { result in
            guard case .success(let tokens) = result else { return }
            receivedTokens = tokens
            didSucceed.fulfill()
        }

        // When
        let payload = Payload(tokens: [
            token(clientID: "clientA", data: Data([0x01, 0x01, 0x01]), type: "APNS"),
            token(clientID: "clientB", data: Data([0x02, 0x02, 0x02]), type: "APNS_SANDBOX"),
            token(clientID: "clientA", data: Data([0x03, 0x03, 0x03]), type: "APNS_VOIP"),
            token(clientID: "clientB", data: Data([0x04, 0x04, 0x04]), type: "APNS_VOIP_SANDBOX"),
            token(clientID: "clientA", data: Data([0x05, 0x05, 0x05]), type: "GCM")
        ])

        sut.handleResponse(response(payload: payload, status: 200), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

        // Then
        XCTAssertEqual(receivedTokens.count, 2)

        let apns = PushToken(deviceToken: Data([0x01, 0x01, 0x01]), appIdentifier: "app", transportType: "APNS", tokenType: .standard)
        XCTAssertEqual(receivedTokens.element(atIndex: 0), apns)

        let voIP = PushToken(deviceToken: Data([0x03, 0x3, 0x03]), appIdentifier: "app", transportType: "APNS_VOIP", tokenType: .voip)
        XCTAssertEqual(receivedTokens.element(atIndex: 1), voIP)
    }

    func test_itHandlesResponse_200_MalformedResponse() throws {
        // Given
        let sut = GetPushTokensActionHandler(context: syncMOC)
        var action = GetPushTokensAction(clientID: "clientID")

        // Expectation
        let didFail = expectation(description: "didFail")

        action.onResult { result in
            guard case .failure(.malformedResponse) = result else { return }
            didFail.fulfill()
        }

        // When
        sut.handleResponse(response(payload: nil, status: 200), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_itHandlesResponse_UnknownError() throws {
        // Given
        let sut = GetPushTokensActionHandler(context: syncMOC)
        var action = GetPushTokensAction(clientID: "clientID")

        // Expectation
        let didFail = expectation(description: "didFail")

        action.onResult { result in
            guard case .failure(.unknown(status: 999)) = result else { return }
            didFail.fulfill()
        }

        // When
        sut.handleResponse(response(payload: nil, status: 999), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

}
