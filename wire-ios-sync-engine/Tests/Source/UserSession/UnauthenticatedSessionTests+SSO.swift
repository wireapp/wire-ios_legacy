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

public final class UnauthenticatedSessionTests_SSO: ZMTBaseTest {

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

    func testThatItGeneratesCorrectRequest() {
        // when
        sut.fetchSSOSettings(completion: {_ in })

        // then
        XCTAssertNotNil(transportSession.lastEnqueuedRequest)
        XCTAssertEqual(transportSession.lastEnqueuedRequest?.path, "/sso/settings")
        XCTAssertEqual(transportSession.lastEnqueuedRequest?.method, ZMTransportRequestMethod.methodGET)
    }

    // MARK: Response handling

    func testThat404ResponseIsError() {
        checkThat(statusCode: 404,
                  isProcessedAs: .failure(SSOSettingsError.unknown),
                  payload: nil)
    }

    func testThat500ResponseIsError() {
        checkThat(statusCode: 500,
                  isProcessedAs: .failure(SSOSettingsError.networkFailure),
                  payload: nil)
    }

    func testThat200ResponseIsProcessedAsValid() {
        let ssoCode = UUID()
        let payload = ["default_sso_code": ssoCode.transportString()]

        checkThat(statusCode: 200,
                  isProcessedAs: .success(SSOSettings(ssoCode: ssoCode)),
                  payload: payload as ZMTransportData)
    }

    func testThat200ResponseWithoutDefaultSSOCodeIsProcessedAsValid() {
        let payload: [String: Any] = [:]

        checkThat(statusCode: 200,
                  isProcessedAs: .success(SSOSettings(ssoCode: nil)),
                  payload: payload as ZMTransportData)
    }

    func testThat200ResponseWithMalformedPayloadGeneratesParseError() {
        checkThat(statusCode: 200,
                  isProcessedAs: .failure(SSOSettingsError.malformedData),
                  payload: ["default_sso_code": "invalid-uuid"] as ZMTransportData)
    }

    func testThat200ResponseWithMissingPayloadGeneratesParseError() {
        checkThat(statusCode: 200,
                  isProcessedAs: .failure(SSOSettingsError.malformedData),
                  payload: nil)
    }

    // MARK: - Helpers

    func checkThat(statusCode: Int, isProcessedAs expectedResult: Result<SSOSettings>, payload: ZMTransportData?) {
        let resultExpectation = expectation(description: "Expected result: \(expectedResult)")

        // given
        sut.fetchSSOSettings { result in

            switch (result, expectedResult) {
            case (.success(let lhsSSOSettings), .success(let rhsSSOSettings)):
                if lhsSSOSettings == rhsSSOSettings {
                    resultExpectation.fulfill()
                }
            case (.failure(let lhsError), .failure(let rhsError)):
                if (lhsError as? SSOSettingsError) == (rhsError as? SSOSettingsError) {
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
