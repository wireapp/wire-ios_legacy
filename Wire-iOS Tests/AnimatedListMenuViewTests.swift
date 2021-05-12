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

import XCTest
@testable import Wire

final class AnimatedListMenuViewTests: XCTestCase {

    func testThatProgressIsClamped() {
        // GIVEN
        let sut = AnimatedListMenuView()

        // WHEN
        sut.progress = 1.3

        // THEN
        XCTAssertEqual(sut.progress, 1)

        // WHEN
        sut.progress = -1

        // THEN
        XCTAssertEqual(sut.progress, 0)

        // WHEN
        sut.progress = 0.5

        // THEN
        XCTAssertEqual(sut.progress, 0.5)
    }
}
