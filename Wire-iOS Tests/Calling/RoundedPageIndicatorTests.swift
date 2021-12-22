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
import SnapshotTesting
@testable import Wire

class RoundedPageIndicatorTests: XCTestCase {

    var sut: RoundedPageIndicator!
    let frame = CGRect(x: 0, y: 0, width: 120, height: 24)

    override func setUp() {
        super.setUp()
        accentColor = .strongBlue
        sut = RoundedPageIndicator()
        sut.frame = frame
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatPageIndicator_IsHidden_When_ThereIsOneOrLessPages() {
        // When
        sut.numberOfPages = 1

        // Then
        XCTAssertTrue(sut.isHidden)
    }

    func testWithFivePages() {
        // When
        sut.numberOfPages = 5
        sut.currentPage = 0

        let view = UIView(frame: frame)
        view.backgroundColor = .black
        view.addSubview(sut)

        // Then
        verify(matching: view)
    }
}
