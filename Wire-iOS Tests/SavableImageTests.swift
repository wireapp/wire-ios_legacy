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
@testable import Wire

final class SavableImageTests: XCTestCase {
    
    weak var sut: SavableImage!
    var imageData: Data!
    override func setUp() {
        super.setUp()
        let image = self.image(inTestBundleNamed: "transparent.png")
        imageData = image.data()
    }
    
    override func tearDown() {
        sut = nil
        imageData = nil

        super.tearDown()
    }

    func testSavableImageIsNotRetainedAfter() {
        autoreleasepool {
            // GIVEN
            var savableImage: SavableImage! = SavableImage(data: imageData!, orientation: .up)
            sut = savableImage

            // WHEN

            savableImage = nil
        }

        // THEN
        XCTAssertNil(sut)
    }
}
