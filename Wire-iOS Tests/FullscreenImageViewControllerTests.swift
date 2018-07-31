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

extension XCTestCase {
    func doubleTap(fullscreenImageViewController: FullscreenImageViewController) {
        let mockTapGestureRecognizer = MockTapGestureRecognizer(location: CGPoint(x: fullscreenImageViewController.view.bounds.size.width / 2, y: fullscreenImageViewController.view.bounds.size.height / 2), state: .ended)

        fullscreenImageViewController.handleDoubleTap(mockTapGestureRecognizer)
        fullscreenImageViewController.view.layoutIfNeeded()
    }

    ///TODO: rename
    func setupSut(imageName: String) -> FullscreenImageViewController {
        // The image is 1280 * 854 W:H = 3:2
        let data = self.data(forResource: imageName, extension: "jpg")!
        let image = UIImage(data: data)!

        let message = MockMessageFactory.imageMessage(with: image)!

        let sut = FullscreenImageViewController(message: message)
        sut.setBoundsSizeAsIPhone4_7Inch()
        sut.viewDidLoad()

        sut.setupImageView(image: image, parentSize: sut.view.bounds.size)

        sut.updateScrollViewZoomScale(viewSize: sut.view.bounds.size, imageSize: image.size)
        sut.updateZoom(withSize: sut.view.bounds.size)
        sut.view.layoutIfNeeded()

        return sut
    }
}

final class FullscreenImageViewControllerTests: XCTestCase {
    
    var sut: FullscreenImageViewController!

    override func setUp() {
        super.setUp()

        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        sut = nil

        UIView.setAnimationsEnabled(true)

        super.tearDown()
    }

    func testThatScrollViewMinimumZoomScaleAndZoomScaleAreSet() {
        // GIVEN & WHEN
        sut = setupSut(imageName: "unsplash_matterhorn")
        let image: UIImage = sut.imageView!.image!
        sut.updateScrollViewZoomScale(viewSize: sut.view.bounds.size, imageSize: image.size)

        // THEN
        XCTAssertEqual(sut.scrollView.minimumZoomScale, sut.view.bounds.size.width / image.size.width)

        XCTAssertLessThanOrEqual(fabs(sut.scrollView.zoomScale - sut.scrollView.minimumZoomScale), kZoomScaleDelta)
    }

    func testThatDoubleTapZoomToScreenFitWhenTheImageIsSmallerThanTheView() {
        // GIVEN
        // The image is 70 * 70
        sut = setupSut(imageName: "unsplash_matterhorn_small_size")

        let maxZoomScale = sut.scrollView.maximumZoomScale

        XCTAssertEqual(maxZoomScale, sut.view.frame.width / 70.0)

        XCTAssertLessThanOrEqual(fabs(sut.scrollView.zoomScale - 1), kZoomScaleDelta)

        // WHEN
        doubleTap(fullscreenImageViewController: sut)

        // THEN
        XCTAssertEqual(sut.scrollView.zoomScale, maxZoomScale)
    }

    func testThatDoubleTapZoomInTheImage() {
        // GIVEN
        sut = setupSut(imageName: "unsplash_matterhorn")

        XCTAssertLessThanOrEqual(fabs(sut.scrollView.zoomScale - sut.scrollView.minimumZoomScale), kZoomScaleDelta)

        // WHEN
        doubleTap(fullscreenImageViewController: sut)

        // THEN
        XCTAssertEqual(sut.scrollView.zoomScale, 1)
    }

    func testThatRotateScreenResetsZoomScaleToMinZoomScale() {
        // GIVEN
        sut = setupSut(imageName: "unsplash_matterhorn")

        // WHEN
        let landscapeSize = CGSize(width: CGSize.iPhoneSize.iPhone4_7.height, height: CGSize.iPhoneSize.iPhone4_7.width)
        sut.view.bounds.size = landscapeSize
        sut.viewWillTransition(to: landscapeSize, with: nil)

        // THEN
        XCTAssertEqual(sut.scrollView.minimumZoomScale, sut.scrollView.zoomScale)
        let image: UIImage = sut.imageView!.image!
        XCTAssertEqual(sut.view.bounds.size.height / image.size.height, sut.scrollView.minimumZoomScale)
    }

    func testThatRotateScreenReserveZoomScaleIfDoubleTapped() {
        // GIVEN
        sut = setupSut(imageName: "unsplash_matterhorn")

        // WHEN
        doubleTap(fullscreenImageViewController: sut)

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
