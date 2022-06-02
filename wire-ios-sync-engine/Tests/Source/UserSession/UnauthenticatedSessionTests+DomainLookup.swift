//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireTesting
@testable import WireSyncEngine

public final class UnauthenticatedSessionTests_DomainLookup: ZMTBaseTest {

    var transportSession: TestUnauthenticatedTransportSession!
    var sut: UnauthenticatedSession!
    var mockDelegate: MockUnauthenticatedSessionDelegate!
    var reachability: MockReachability!
    var mockAuthenticationStatusDelegate: MockAuthenticationStatusDelegate!

    public override func setUp() {
        super.setUp()
        transportSession = TestUnauthenticatedTransportSession()
        mockDelegate = MockUnauthenticatedSessionDelegate()
        reachability = MockReachability()
        sut = UnauthenticatedSession(transportSession: transportSession,
                                     reachability: reachability,
                                     delegate: mockDelegate,
                                     authenticationStatusDelegate: mockAuthenticationStatusDelegate)
        sut.groupQueue.add(dispatchGroup)
        APIVersion.current = .v0
    }

    public override func tearDown() {
        sut.tearDown()
        sut = nil
        transportSession = nil
        mockDelegate = nil
        reachability = nil
        APIVersion.current = nil
        super.tearDown()
    }

    // MARK: Request generation

    func testThatItGeneratesCorrectRequestIfDomainIsSet() {
        // given
        let domain = "example.com"

        // when
        sut.lookup(domain: domain) { _ in }

        // then
        XCTAssertNotNil(transportSession.lastEnqueuedRequest)
        XCTAssertEqual(transportSession.lastEnqueuedRequest?.path, "/custom-backend/by-domain/example.com")
        XCTAssertEqual(transportSession.lastEnqueuedRequest?.method, ZMTransportRequestMethod.methodGET)
    }

    func testThatItURLEncodeRequest() {
        // given
        let domain = "example com"

        // when
        sut.lookup(domain: domain) { _ in }

        // then
        XCTAssertNotNil(transportSession.lastEnqueuedRequest)
        XCTAssertEqual(transportSession.lastEnqueuedRequest?.path, "/custom-backend/by-domain/example%20com")
        XCTAssertEqual(transportSession.lastEnqueuedRequest?.method, ZMTransportRequestMethod.methodGET)
    }

    // MARK: Response handling

    func testThat404ResponseWithNoMatchingLabelIsError() {
        checkThat(statusCode: 404,
                  isProcessedAs:
            .failure(DomainLookupError.unknown), payload: nil)
    }

    func testThat404ResponseWithMatchingLabelIsNotFound() {
        let payload = ["label": "custom-instance-not-found"]
        checkThat(statusCode: 404,
                  isProcessedAs: .failure(DomainLookupError.notFound),
                  payload: payload as ZMTransportData)
    }

    func testThat500ResponseIsError() {
        checkThat(statusCode: 500,
                  isProcessedAs: .failure(DomainLookupError.networkFailure),
                  payload: nil)
    }

    func testThat200ResponseIsProcessedAsValid() {
        let url = URL(string: "https://wire.com/config.json")!
        let payload = ["foo": "bar", "config_json_url": url.absoluteString]

        checkThat(statusCode: 200,
                  isProcessedAs: .success(DomainInfo(configurationURL: url)),
                  payload: payload as ZMTransportData)
    }

    func testThat200ResponseWithMalformdURLGeneratesParseError() {
        checkThat(statusCode: 200,
                  isProcessedAs: .failure(DomainLookupError.malformedData),
                  payload: ["config_json_url": "22"] as ZMTransportData)
    }

    func testThat200ResponseWithMissingPayloadGeneratesParseError() {
        checkThat(statusCode: 200,
                  isProcessedAs: .failure(DomainLookupError.malformedData),
                  payload: nil)
    }

    // MARK: - Helpers

    func checkThat(statusCode: Int, isProcessedAs expectedResult: Result<DomainInfo>, payload: ZMTransportData?) {
        let resultExpectation = expectation(description: "Expected result: \(expectedResult)")

        // given
        sut.lookup(domain: "example.com") { result in

            switch (result, expectedResult) {
            case (.success(let lhsDomainInfo), .success(let rhsDomainInfo)):
                if lhsDomainInfo == rhsDomainInfo {
                    resultExpectation.fulfill()
                }
            case (.failure(let lhsError), .failure(let rhsError)):
                if (lhsError as? DomainLookupError) == (rhsError as? DomainLookupError) {
                    resultExpectation.fulfill()
                }
            default:
                    break
            }
        }

        // when
        transportSession.lastEnqueuedRequest?.complete(with: ZMTransportResponse(payload: payload, httpStatus: statusCode, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
}
