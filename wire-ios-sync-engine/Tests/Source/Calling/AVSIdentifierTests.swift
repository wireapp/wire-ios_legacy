//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import XCTest
@testable import WireSyncEngine

class AVSIdentifierTests: XCTestCase {

    let uuid = UUID()
    let domain = "wire.com"

    override func tearDown() {
        APIVersion.isFederationEnabled = false
        super.tearDown()
    }

    func testProperties_WhenCreatedFromSerializedString_WithUUIDAndDomain() {
        // Given
        APIVersion.isFederationEnabled = true
        let serializedString = "\(uuid.transportString())@\(domain)"

        // When
        let sut = AVSIdentifier(string: serializedString)

        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut?.identifier, uuid)
        XCTAssertEqual(sut?.domain, domain)
        XCTAssertEqual(sut?.serialized, serializedString)
    }

    func testProperties_WhenCreatedFromSerializedString_WithUUID() {
        // When
        let serializedString = uuid.transportString()
        let sut = AVSIdentifier(string: serializedString)

        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut?.identifier, uuid)
        XCTAssertNil(sut?.domain)
        XCTAssertEqual(sut?.serialized, serializedString)
    }

    func testThatItSerializesUUIDToLowercase() {
        // When
        let lowercaseUUIDString = "aaab81b1-674d-445d-b609-e11781d4aebf"
        let uuid = UUID(uuidString: lowercaseUUIDString)!
        let sut = AVSIdentifier(identifier: uuid, domain: nil)

        // Then
        XCTAssertEqual(sut.serialized, lowercaseUUIDString)
    }

    func testThatCreationFromInvalidStringReturnsNil() {
        // When / Then
        XCTAssertNil(AVSIdentifier(string: "invalidUUID@domain.com"))
        XCTAssertNil(AVSIdentifier(string: "UUID@domain.com@something"))
        XCTAssertNil(AVSIdentifier(string: ""))
    }

    func testThatItIgnoresDomain_WhenFederationIsDisabled() {
        // Given
        APIVersion.isFederationEnabled = false
        let uuid = UUID()

        // When
        let sut = AVSIdentifier(identifier: uuid, domain: "example.domain.com")

        // Then
        XCTAssertNil(sut.domain)
        XCTAssertEqual(sut.identifier, uuid)
    }

    func testThatItDoesntIgnoreDomain_WhenFederationIsEnabled() {
        // Given
        APIVersion.isFederationEnabled = true
        let uuid = UUID()
        let domain = "example.domain.com"

        // When
        let sut = AVSIdentifier(identifier: uuid, domain: domain)

        // Then
        XCTAssertEqual(sut.domain, domain)
        XCTAssertEqual(sut.identifier, uuid)
    }
}
