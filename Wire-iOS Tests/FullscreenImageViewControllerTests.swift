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

final class MockTapGestureRecognizer: UITapGestureRecognizer {
    let mockState: UIGestureRecognizerState
    var mockLocation: CGPoint?

    init(location: CGPoint?, state: UIGestureRecognizerState) {
        mockLocation = location
        mockState = state

        super.init(target: nil, action: nil)
    }

    override func location(in view: UIView?) -> CGPoint {
        if let mockLocation = mockLocation {
            return mockLocation
        }
        return super.location(in: view)
    }

    override var state: UIGestureRecognizerState {
        return mockState
    }
}

final class FullscreenImageViewControllerTests: XCTestCase {
    
    var sut: FullscreenImageViewController!
    var image: UIImage!

    override func setUp() {
        super.setUp()

        UIView.setAnimationsEnabled(false)

        // The image is 1280 * 854 W/H = ~1.5
        let data = self.data(forResource: "unsplash_matterhorn", extension: "jpg")!
        image = UIImage(data: data)

        let message = MockMessageFactory.imageMessage(with: image)!

        sut = FullscreenImageViewController(message: message)
        sut.setBoundsSizeAsIPhone4_7Inch()
        sut.viewDidLoad()

        sut.setupImageView(image: image, parentSize: sut.view.bounds.size)
    }
    
    override func tearDown() {
        sut = nil
        image = nil

        UIView.setAnimationsEnabled(true)

        super.tearDown()
    }

    func testThatScrollViewMinimumZoomScaleIsSet() {
        // GIVEN & WHEN
        sut.updateScrollViewMinimumZoomScale(viewSize: sut.view.bounds.size, imageSize: image.size)

        // THEN
        XCTAssertEqual(sut.scrollView.minimumZoomScale, sut.view.bounds.size.width / image.size.width)
    }

    func testThatDoubleTapZoomInTheImage() {
        // GIVEN & WHEN
        sut.updateScrollViewMinimumZoomScale(viewSize: sut.view.bounds.size, imageSize: image.size)
        sut.updateZoom(withSize: sut.view.bounds.size)

        // THEN
        let delta: CGFloat = 0.0003
        XCTAssertLessThanOrEqual(fabs(sut.scrollView.zoomScale - sut.scrollView.minimumZoomScale), delta)

        // WHEN
        let mockTapGestureRecognizer = MockTapGestureRecognizer(location: CGPoint(x: sut.view.bounds.size.width / 2, y: sut.view.bounds.size.height / 2), state: .ended)

        sut.handleDoubleTap(mockTapGestureRecognizer)
        sut.view.layoutIfNeeded()
        sut.view.layoutSubviews()

//        sut.handleDoubleTap(mockTapGestureRecognizer)
//        sut.view.layoutIfNeeded()

        // THEN
        XCTAssertEqual(sut.scrollView.zoomScale, 1) ///TODO: check zoom rect/image size
    }
}
