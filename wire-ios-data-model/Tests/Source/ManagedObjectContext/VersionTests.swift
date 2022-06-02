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

final class VersionTests: XCTestCase {

    func testThatItComparesCorrectly() {
        let version1 = Version(string: "0.1")
        let version2 = Version(string: "1.0")
        let version3 = Version(string: "1.0")
        let version4 = Version(string: "1.0.1")
        let version5 = Version(string: "1.1")

        XCTAssertLessThan(version1, version2)
        XCTAssertLessThan(version1, version3)
        XCTAssertLessThan(version1, version4)
        XCTAssertLessThan(version1, version5)

        XCTAssertGreaterThan(version2, version1)
        XCTAssertEqual(version2, version3)
        XCTAssertEqual(version2.compare(with: version3), .orderedSame)
        XCTAssertLessThan(version2, version4)
        XCTAssertLessThan(version2, version5)

        XCTAssertGreaterThan(version3, version1)
        XCTAssertEqual(version3, version2)
        XCTAssertEqual(version3.compare(with: version2), .orderedSame)
        XCTAssertLessThan(version3, version4)
        XCTAssertLessThan(version3, version5)

        XCTAssertGreaterThan(version4, version1)
        XCTAssertGreaterThan(version4, version2)
        XCTAssertGreaterThan(version4, version3)
        XCTAssertLessThan(version4, version5)

        XCTAssertGreaterThan(version5, version1)
        XCTAssertGreaterThan(version5, version2)
        XCTAssertGreaterThan(version5, version3)
        XCTAssertGreaterThan(version5, version4)
    }

}
