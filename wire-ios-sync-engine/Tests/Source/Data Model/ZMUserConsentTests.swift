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

final class ZMUserConsentTests: DatabaseTest {

    var mockTransportSession: MockTransportSession!

    override func setUp() {
        super.setUp()

        mockTransportSession = MockTransportSession(dispatchGroup: dispatchGroup)
    }

    override func tearDown() {
        mockTransportSession.cleanUp()
        mockTransportSession = nil

        super.tearDown()
    }

    var selfUser: ZMUser {
        let selfUser = ZMUser.selfUser(in: uiMOC)
        if selfUser.remoteIdentifier == nil {
            selfUser.remoteIdentifier = UUID()
        }
        return selfUser
    }

    func testGetRequest() {
        // given
        let request = WireSyncEngine.ConsentRequestFactory.fetchConsentRequest(apiVersion: .v0)

        // then
        XCTAssertEqual(request.method, .methodGET)
        XCTAssertEqual(request.path, "/self/consent")
        XCTAssertNil(request.payload)
    }

    func testSetRequest_true() {
        // given
        let request = WireSyncEngine.ConsentRequestFactory.setConsentRequest(for: .marketing, value: true, apiVersion: .v0)
        // then
        XCTAssertEqual(request.method, .methodPUT)
        XCTAssertEqual(request.path, "/self/consent")
        let expectedPayload: [AnyHashable: Any] = ["type": 2, "value": 1, "source": "iOS 1.0"]
        XCTAssertEqual(request.payload!.asDictionary()! as NSDictionary, expectedPayload as NSDictionary)
    }

    func testSetRequest_false() {
        // given
        let request = WireSyncEngine.ConsentRequestFactory.setConsentRequest(for: .marketing, value: false, apiVersion: .v0)
        // then
        XCTAssertEqual(request.method, .methodPUT)
        XCTAssertEqual(request.path, "/self/consent")
        let expectedPayload: [AnyHashable: Any] = ["type": 2, "value": 0, "source": "iOS 1.0"]
        XCTAssertEqual(request.payload!.asDictionary()! as NSDictionary, expectedPayload as NSDictionary)
    }

    func testThatItCanParseResponse() {
        typealias PayloadPair = ([String: Any], Bool)

        let pairs: [PayloadPair] =
            [(["results": [["type": "yobobo", "value": 1]]], false),
             (["results": [["type": 2, "value": 1]]], true),
             (["results": [["type": 2, "value": 0]]], false),
             (["results": [["type": 1, "value": 1]]], false),
             (["results": [["type": 1000, "value": 0], ["type": 2, "value": 1]]], true),
             (["results": []], false),
             ([:], false)]

            pairs.forEach {
                let payload = ZMUser.parse(consentPayload: $0.0 as ZMTransportData)

                let value = payload[.marketing] ?? false
                XCTAssertEqual(value, $0.1)
            }
    }

    func testThatItCanFetchState() {
        // given
        mockTransportSession.responseGeneratorBlock = { request in
            guard request.path == "/self/consent" else { return nil }

            return ZMTransportResponse(payload: ["results": [["type": 2, "value": 1]]] as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        }

        let fetchedData = expectation(description: "fetched data")

        // when
        selfUser.fetchConsent(for: .marketing, on: mockTransportSession) { result in
            switch result {
            case .failure:
                XCTFail()
            case .success(let result):
                XCTAssertTrue(result)
                fetchedData.fulfill()
            }
        }

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        mockTransportSession.responseGeneratorBlock = nil
        mockTransportSession.resetReceivedRequests()
    }

    func testThatItFailsOnInvalidOperation_get() {
        // given
        mockTransportSession.responseGeneratorBlock = { request in
            guard request.path == "/self/consent" else { return nil }

            return ZMTransportResponse(payload: ["label": "invalid-op"] as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        }

        let receivedError = expectation(description: "received error")
        // when

        selfUser.fetchConsent(for: .marketing, on: mockTransportSession) { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as! WireSyncEngine.ConsentRequestError, WireSyncEngine.ConsentRequestError.unknown)
                receivedError.fulfill()
            case .success:
                XCTFail()
            }
        }

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        mockTransportSession.responseGeneratorBlock = nil
        mockTransportSession.resetReceivedRequests()
    }

    func testThatItCanSetTheState() {
        // given
        mockTransportSession.responseGeneratorBlock = { request in
            guard request.path == "/self/consent" else { return nil }

            return ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        }

        let successExpectation = expectation(description: "set is successful")

        // when
        selfUser.setConsent(to: true, for: .marketing, on: mockTransportSession) { result in
            switch result {
            case .failure:
                XCTFail()
            case .success:
                successExpectation.fulfill()
            }
        }

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        mockTransportSession.responseGeneratorBlock = nil
        mockTransportSession.resetReceivedRequests()
    }

    func testThatItFailsOnInvalidOperation_set() {
        // given
        mockTransportSession.responseGeneratorBlock = { request in
            guard request.path == "/self/consent" else { return nil }

            return ZMTransportResponse(payload: ["label": "invalid-op"] as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        }

        let receivedError = expectation(description: "received error")

        // when
        selfUser.setConsent(to: true, for: .marketing, on: mockTransportSession) { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as! WireSyncEngine.ConsentRequestError, WireSyncEngine.ConsentRequestError.unknown)
                receivedError.fulfill()
            case .success:
                XCTFail()
            }
        }

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        mockTransportSession.responseGeneratorBlock = nil
        mockTransportSession.resetReceivedRequests()
    }
}
