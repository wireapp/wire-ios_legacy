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

final class FullscreenImageViewControllerSnapshotTests: ZMSnapshotTestCase {
    
    var sut: FullscreenImageViewController!
    var image: UIImage!

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)

        // The image is 70 * 70
        let data = self.data(forResource: "unsplash_matterhorn_small_size", extension: "jpg")!
        image = UIImage(data: data)

        // The image is 1280 * 854 W:H = 3:2
//        let data = self.data(forResource: "unsplash_matterhorn", extension: "jpg")!
//        image = UIImage(data: data)

        let message = MockMessageFactory.imageMessage(with: image)!

        sut = FullscreenImageViewController(message: message)
        sut.setBoundsSizeAsIPhone4_7Inch()
        sut.viewDidLoad()

        sut.setupImageView(image: image, parentSize: sut.view.bounds.size)

        recordMode = true
    }
    
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }



    /// Example checker method which can be reused in different tests
//    fileprivate func checkerExample(file: StaticString = #file, line: UInt = #line) {
//        XCTAssert(true, file: file, line: line)
//    }

    func testSmallImageIsCenteredInTheScreen(){
        // GIVEN

        // WHEN

        // THEN
//        checkerExample()
        verify(view: sut.view)
    }

    ///TODO: snapshot after double tapped
}
