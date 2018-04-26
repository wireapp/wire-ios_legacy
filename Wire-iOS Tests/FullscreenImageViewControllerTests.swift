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
        return mockLocation ?? super.location(in: view)
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

    func doubleTap() {
        let mockTapGestureRecognizer = MockTapGestureRecognizer(location: CGPoint(x: sut.view.bounds.size.width / 2, y: sut.view.bounds.size.height / 2), state: .ended)

        sut.handleDoubleTap(mockTapGestureRecognizer)
        sut.view.layoutIfNeeded()
    }

    func testThatScrollViewMinimumZoomScaleAndZoomScaleAreSet() {
        // GIVEN & WHEN
        sut.updateScrollViewMinimumZoomScale(viewSize: sut.view.bounds.size, imageSize: image.size)

        // THEN
        XCTAssertEqual(sut.scrollView.minimumZoomScale, sut.view.bounds.size.width / image.size.width)

        XCTAssertLessThanOrEqual(fabs(sut.scrollView.zoomScale - sut.scrollView.minimumZoomScale), kZoomScaleDelta)
    }

    func testThatDoubleTapZoomInTheImage() {
        // GIVEN
        sut.updateScrollViewMinimumZoomScale(viewSize: sut.view.bounds.size, imageSize: image.size)
        sut.updateZoom(withSize: sut.view.bounds.size)
        sut.view.layoutIfNeeded()

        // WHEN
        doubleTap()

        // THEN
        XCTAssertEqual(sut.scrollView.zoomScale, 1)
    }

    func testThatRotateScreenResetsZoomScaleToMinZoomScale() {
        // GIVEN
        sut.updateScrollViewMinimumZoomScale(viewSize: sut.view.bounds.size, imageSize: image.size)
        sut.updateZoom(withSize: sut.view.bounds.size)
        sut.view.layoutIfNeeded()

        // WHEN
        let landscapeSize = CGSize(width: CGSize.iPhoneSize.iPhone4_7.height, height: CGSize.iPhoneSize.iPhone4_7.width)
        sut.view.bounds.size = landscapeSize
        sut.viewWillTransition(to: landscapeSize, with: nil)

        // THEN
        XCTAssertEqual(sut.scrollView.minimumZoomScale, sut.scrollView.zoomScale)
        XCTAssertEqual(sut.view.bounds.size.height / image.size.height, sut.scrollView.minimumZoomScale)
    }

    func testThatRotateScreenReserveZoomScaleIfDoubleTapped() {
        // GIVEN
        sut.updateScrollViewMinimumZoomScale(viewSize: sut.view.bounds.size, imageSize: image.size)
        sut.updateZoom(withSize: sut.view.bounds.size)
        sut.view.layoutIfNeeded()

        // WHEN
        doubleTap()

        // THEN
        XCTAssertEqual(1, sut.scrollView.zoomScale)

        // WHEN
        let landscapeSize = CGSize(width: CGSize.iPhoneSize.iPhone4_7.height, height: CGSize.iPhoneSize.iPhone4_7.width)
        sut.view.bounds.size = landscapeSize
        sut.viewWillTransition(to: landscapeSize, with: nil)

        // THEN
        XCTAssertEqual(1, sut.scrollView.zoomScale)
    }
}
