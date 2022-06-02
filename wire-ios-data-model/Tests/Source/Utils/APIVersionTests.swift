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
@testable import WireDataModel

final class APIVersionTests: XCTestCase {

    private var lowestVersion: APIVersion!
    private var highestVersion: APIVersion!

    override func setUp() {
        lowestVersion = APIVersion.allCases.first
        highestVersion = APIVersion.allCases.last
    }

    override func tearDown() {
        lowestVersion = nil
        highestVersion = nil
    }

    func testThatTheCommonVersionIsNil_whenBackendSupportsHigherVersionsOnly() {
        // given
        let backendVersions = (1...5).map { highestVersion.rawValue + $0 }

        // when
        let commonVersion = APIVersion.highestSupportedVersion(in: backendVersions)

        // then
        XCTAssertNil(commonVersion)
    }

    func testThatTheCommonVersionIsNil_whenBackendSupportsLowerVersionsOnly() {
        // given
        let backendVersions = ((-5)...(-1)).map { lowestVersion.rawValue + $0 }

        // when
        let commonVersion = APIVersion.highestSupportedVersion(in: backendVersions)

        // then
        XCTAssertNil(commonVersion)
    }

    func testThatTheCommonVersionIsTheHighestVersion_whenBackendSupportsTheHighestVersion() {
        // given
        let backendVersions = APIVersion.allCases.map(\.rawValue)

        // when
        let commonVersion = APIVersion.highestSupportedVersion(in: backendVersions)

        // then
        XCTAssertEqual(commonVersion, highestVersion)
    }

}
