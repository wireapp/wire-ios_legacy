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

extension XCTestCase {
    func doubleTap(fullscreenImageViewController: FullscreenImageViewController) {
        let mockTapGestureRecognizer = MockTapGestureRecognizer(location: CGPoint(x: fullscreenImageViewController.view.bounds.size.width / 2, y: fullscreenImageViewController.view.bounds.size.height / 2), state: .ended)

        fullscreenImageViewController.handleDoubleTap(mockTapGestureRecognizer)
        fullscreenImageViewController.view.layoutIfNeeded()
    }

    func createFullscreenImageViewControllerForTest(imageFileName: String) -> FullscreenImageViewController {
        let image = self.image(inTestBundleNamed: imageFileName)


        let message = MockMessageFactory.imageMessage(with: image)

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
