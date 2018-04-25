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

final class FullscreenImageViewControllerTests: XCTestCase {
    
    var sut: FullscreenImageViewController!
    var image: UIImage!

    override func setUp() {
        super.setUp()

        // The image is 1280 * 854
        let data = self.data(forResource: "unsplash_matterhorn", extension: "jpg")!
        image = UIImage(data: data)

        let message = MockMessageFactory.imageMessage(with: image)!

        sut = FullscreenImageViewController(message: message)
    }
    
    override func tearDown() {
        sut = nil
        image = nil
        super.tearDown()
    }

    func testThatScrollViewMinimumZoomScaleIsSet() {
        // GIVEN
        sut.setBoundsSizeAsIPhone4_7Inch()

        // WHEN
        sut.updateScrollViewMinimumZoomScale(viewSize: sut.view.bounds.size, imageSize: image.size)

        // THEN
        XCTAssertEqual(sut.scrollView.minimumZoomScale, sut.view.bounds.size.width / image.size.width)
    }
}
