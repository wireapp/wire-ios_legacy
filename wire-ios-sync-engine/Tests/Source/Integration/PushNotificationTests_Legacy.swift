////
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
@testable import WireSyncEngine
import WireMockTransport

class PushNotificationTokenTests_Legacy: IntegrationTest {

    enum TokenRequest {
        case get
        case post(Data)
        case delete(Data)
    }

    override var shouldProcessLegacyPushes: Bool {
        return true
    }

    func check(request: ZMTransportRequest, expectedRequest: TokenRequest, line: UInt = #line) {
        switch expectedRequest {
        case .get:
            XCTAssertEqual(request.method, .methodGET, "Should be GET '/push/tokens', found \(request)", line: line)
        case .delete(let data):
            XCTAssertEqual(request.method, .methodDELETE, "Should be DELETE '/push/tokens', found \(request)", line: line)
            XCTAssertEqual(request.path, "/push/tokens/\(data.zmHexEncodedString())", "Should be DELETE '/push/tokens/\(data.zmHexEncodedString())', found \(request)", line: line)
        case .post(let data):
            XCTAssertEqual(request.method, .methodPOST, "Should be POST '/push/tokens', found \(request)", line: line)

            guard let payload = request.payload?.asDictionary() as? [String: String] else { return XCTFail("No payload found: \(request)", line: line) }
            guard payload["transport"] == "APNS_VOIP" else { return XCTFail("Not token in transport: \(request)", line: line) }
            guard payload["token"] == data.zmHexEncodedString() else {
                return XCTFail("Wrong device token: \(request)", line: line)

            }
        }
    }

    func checkThatLastRequestContainsTokenRequests(_ requests: [TokenRequest], line: UInt = #line) {
        let tokenRequests = mockTransportSession.receivedRequests()
            .filter { $0.path.hasPrefix("/push/tokens")}
        if tokenRequests.count == requests.count {
            for (request, expectedRequest) in zip(tokenRequests, requests) {
                check(request: request, expectedRequest: expectedRequest, line: line)
            }
        } else if tokenRequests.isEmpty {
            XCTFail("No token requests found", line: line)
        } else {
            XCTFail("Wrong number of token requests, expected \(requests.count), found \(tokenRequests.count)", line: line)
        }
    }

    func checkThatLastRequestContainsTokenRequest(_ request: TokenRequest, line: UInt = #line) {
        checkThatLastRequestContainsTokenRequests([request], line: line)
    }

    override func setUp() {
        super.setUp()
        PushTokenStorage.pushToken = nil
        createSelfUserAndConversation()
    }

    func testThatItRegistersPushToken() {
        XCTAssert(login())

        // given
        let token = Data(repeating: 0x41, count: 10)

        // when
        let pushToken = PushToken.createVOIPToken(from: token)
        userSession?.setPushToken(pushToken)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        checkThatLastRequestContainsTokenRequest(.post(token))
    }

    func testThatItDoesNotReRegisterSamePushToken() {
        XCTAssert(login())

        // given
        let token = Data(repeating: 0x41, count: 10)
        let pushToken1 = PushToken.createVOIPToken(from: token)
        userSession?.setPushToken(pushToken1)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mockTransportSession.resetReceivedRequests()

        // when
        let pushToken2 = PushToken.createVOIPToken(from: token)
        userSession?.setPushToken(pushToken2)

        // then
        XCTAssertTrue(mockTransportSession.receivedRequests().isEmpty)
    }

    func testThatItRegistersUpdatedPushToken() {
        XCTAssert(login())

        // given
        let token = Data(repeating: 0x41, count: 10)
        let pushToken1 = PushToken.createVOIPToken(from: token)
        userSession?.setPushToken(pushToken1)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mockTransportSession.resetReceivedRequests()

        // when
        let otherToken = Data(repeating: 0x42, count: 10)
        let pushToken2 = PushToken.createVOIPToken(from: otherToken)
        userSession?.setPushToken(pushToken2)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        checkThatLastRequestContainsTokenRequest(.post(otherToken))
    }

    func testThatItDeletesTokenWhenMarkedAsToBeDeleted() {
        XCTAssert(login())

        // given
        let token = Data(repeating: 0x41, count: 10)
        let pushToken = PushToken.createVOIPToken(from: token)
        userSession?.setPushToken(pushToken)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mockTransportSession.resetReceivedRequests()

        // when
        userSession?.deletePushToken()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        checkThatLastRequestContainsTokenRequest(.delete(token))
        XCTAssertNil(PushTokenStorage.pushToken)
    }

    func overrideBackendToken(of token: Data, with updatedToken: Data, line: UInt = #line) {
        guard var payload = mockTransportSession.pushTokens[token.zmHexEncodedString()] else { return XCTFail(line: line) }
        payload["token"] = updatedToken.zmHexEncodedString()
        mockTransportSession.addPushToken(token.zmHexEncodedString(), payload: payload)
    }

    func testThatItValidatesTheTokenAndDoesNotUploadIfTheLocalOneIsTheSame() {
        XCTAssert(login())

        // given
        let token = Data(repeating: 0x41, count: 10)
        pushRegistry.mockPushToken = token
        let standardToken = PushToken.createVOIPToken(from: token)
        userSession?.setPushToken(standardToken)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mockTransportSession.resetReceivedRequests()
        guard let pushToken = PushTokenStorage.pushToken else { return XCTFail() }

        // when
        userSession?.validatePushToken()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 55.5))

        // then
        checkThatLastRequestContainsTokenRequests([.get])
        guard let afterUpdate = PushTokenStorage.pushToken else { return XCTFail("Push token should be set") }
        XCTAssertEqual(pushToken, afterUpdate)
    }

    func testThatItValidatesTheTokenAndUploadsTheLocalOneIfOnTheServerItIsDifferent() {
        XCTAssert(login())

        // given
        let token = Data(repeating: 0x41, count: 10)
        pushRegistry.mockPushToken = token
        application?.deviceToken = token
        application?.userSession = userSession
        let standardToken = PushToken.createVOIPToken(from: token)
        userSession?.setPushToken(standardToken)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mockTransportSession.resetReceivedRequests()
        guard let pushToken = PushTokenStorage.pushToken else { return XCTFail() }

        // when
        // Change the registered push token on the backend
        overrideBackendToken(of: token, with: Data(repeating: 0xAA, count: 10))
        userSession?.validatePushToken()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 55.5))

        // then
        checkThatLastRequestContainsTokenRequests([.get, .post(token)])
        guard let afterUpdate = PushTokenStorage.pushToken else { return XCTFail("Push token should be set") }
        XCTAssertEqual(pushToken, afterUpdate)
    }
}
