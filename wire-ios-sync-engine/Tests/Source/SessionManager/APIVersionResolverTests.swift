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
@testable import WireSyncEngine
import XCTest

class APIVersionResolverTests: ZMTBaseTest {

    private var sut: APIVersionResolver!
    private var transportSession: MockTransportSession!
    private var mockDelegate: MockAPIVersionResolverDelegate!

    override func setUp() {
        mockDelegate = .init()
        transportSession = MockTransportSession(dispatchGroup: dispatchGroup)
        sut = APIVersionResolver(transportSession: transportSession)
        sut.delegate = mockDelegate
        APIVersion.current = nil
        super.setUp()
    }

    override func tearDown() {
        mockDelegate = nil
        transportSession = nil
        sut = nil
        super.tearDown()
    }

    private func mockBackendInfo(
        supportedVersions: ClosedRange<Int32>,
        domain: String,
        isFederationEnabled: Bool
    ) {
        transportSession.supportedAPIVersions = supportedVersions.map(NSNumber.init(value:))
        transportSession.domain = domain
        transportSession.federation = isFederationEnabled
    }

    // MARK: - Tests

    func testThatItResolvesTheAPIVersion() throws {
        // Given
        let maxSupportedAPIVersion = try XCTUnwrap(APIVersion.allCases.max())

        mockBackendInfo(
            supportedVersions: 0...(maxSupportedAPIVersion.rawValue + 1),
            domain: "foo.com",
            isFederationEnabled: true
        )

        XCTAssertNil(APIVersion.current)

        // When
        let done = expectation(description: "done")
        sut.resolveAPIVersion(completion: done.fulfill)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // Then
        XCTAssertEqual(APIVersion.current, maxSupportedAPIVersion)
        XCTAssertEqual(APIVersion.domain, "foo.com")
        XCTAssertEqual(APIVersion.isFederationEnabled, true)
    }

    func testThatItDefaultsToVersionZeroIfEndpointIsUnavailable() throws {
        // Given
        transportSession.isAPIVersionEndpointAvailable = false

        // When
        let done = expectation(description: "done")
        sut.resolveAPIVersion(completion: done.fulfill)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // Then
        let resolvedVersion = try XCTUnwrap(APIVersion.current)
        XCTAssertEqual(resolvedVersion, .v0)
        XCTAssertEqual(APIVersion.domain, "wire.com")
        XCTAssertEqual(APIVersion.isFederationEnabled, false)
    }

    func testThatItReportsBlacklistReasonWhenBackendIsObsolete() throws {
        // Given
        APIVersion.current = .v0
        let minSupportedAPIVersion = try XCTUnwrap(APIVersion.allCases.min())

        mockBackendInfo(
            supportedVersions: (minSupportedAPIVersion.rawValue - 3)...(minSupportedAPIVersion.rawValue - 1),
            domain: "foo.com",
            isFederationEnabled: true
        )

        // When
        let done = expectation(description: "done")
        sut.resolveAPIVersion(completion: done.fulfill)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // Then
        XCTAssertNil(APIVersion.current)
        XCTAssertEqual(APIVersion.domain, "foo.com")
        XCTAssertEqual(APIVersion.isFederationEnabled, true)
        XCTAssertEqual(mockDelegate.blacklistReason, .backendAPIVersionObsolete)

    }

    func testThatItReportsBlacklistReasonWhenClientIsObsolete() throws {
        // Given
        APIVersion.current = .v0
        let maxSupportedAPIVersion = try XCTUnwrap(APIVersion.allCases.max())

        mockBackendInfo(
            supportedVersions: (maxSupportedAPIVersion.rawValue + 1)...(maxSupportedAPIVersion.rawValue + 3),
            domain: "foo.com",
            isFederationEnabled: true
        )

        // When
        let done = expectation(description: "done")
        sut.resolveAPIVersion(completion: done.fulfill)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // Then
        XCTAssertNil(APIVersion.current)
        XCTAssertEqual(APIVersion.domain, "foo.com")
        XCTAssertEqual(APIVersion.isFederationEnabled, true)
        XCTAssertEqual(mockDelegate.blacklistReason, .clientAPIVersionObsolete)
    }

    func testThatItReportsToDelegate_WhenFederationHasBeenEnabled() throws {
        // Given
        APIVersion.isFederationEnabled = false
        let maxSupportedAPIVersion = try XCTUnwrap(APIVersion.allCases.max())

        mockBackendInfo(
            supportedVersions: 0...(maxSupportedAPIVersion.rawValue + 1),
            domain: "foo.com",
            isFederationEnabled: true
        )

        // When
        let done = expectation(description: "done")
        sut.resolveAPIVersion(completion: done.fulfill)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // Then
        XCTAssertTrue(APIVersion.isFederationEnabled)
        XCTAssertTrue(mockDelegate.didReportFederationHasBeenEnabled)
    }

}

// MARK: - Mocks

private class MockAPIVersionResolverDelegate: APIVersionResolverDelegate {

    var blacklistReason: BlacklistReason?

    func apiVersionResolverFailedToResolveVersion(reason: BlacklistReason) {
        blacklistReason = reason
    }

    var didReportFederationHasBeenEnabled: Bool = false
    func apiVersionResolverDetectedFederationHasBeenEnabled() {
        didReportFederationHasBeenEnabled = true
    }
}
