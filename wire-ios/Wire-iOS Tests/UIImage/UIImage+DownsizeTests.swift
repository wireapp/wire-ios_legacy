// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class UIImageDownsizeTests: XCTestCase {
    var sut: UIImage!
    let targetLength: CGFloat = 320

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    override func setUp() {
        super.setUp()

        // the image size is 2459 x 3673 px
        sut = image(inTestBundleNamed: "unsplash_burger.jpg")
    }

    func testDownsizeWithMaxLength() {
        // GIVEN

        // WHEN
        let downsizedImage = sut.downsized(maxLength: targetLength)

        // THEN
        XCTAssertEqual(downsizedImage?.size.height, targetLength / UIScreen.main.scale)
    }

    func testDownsizeWithShorterSizeLength() {
        // GIVEN

        // WHEN
        let downsizedImage = sut.downsized(shorterSizeLength: targetLength)

        // THEN
        XCTAssertEqual(downsizedImage?.size.width, targetLength / UIScreen.main.scale)
    }
}
