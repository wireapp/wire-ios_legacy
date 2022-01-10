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

final class ThumbnailCreationTests: ZMSnapshotTestCase {

    func testThatItCreatesThumbnailForSquareImage() {
        // Given
        let image = self.image(inTestBundleNamed: "unsplash_square.jpg")
        guard let data = image.imageData else {
            return XCTFail("Failed to create image data")
        }

        // When
        guard let thumbnail = UIImage(from: data, withShorterSideLength: 100 * UIScreen.main.scale) else {
            return XCTFail("Failed to create thumbnail") }

        // Then
        XCTAssertEqual(thumbnail.size.width, 100, accuracy: 1)
        XCTAssertEqual(thumbnail.size.height, 100, accuracy: 1)
        verify(view: thumbnail.wrappedInImageView())
    }

    func testThatItCreatesThumbnailForVerticalPanorama() {
        // Given
        let image = self.image(inTestBundleNamed: "unsplash_vertical_pano.jpg")
        guard let data = image.imageData else {
            return XCTFail("Failed to create image data")
        }

        // When
        guard let thumbnail = UIImage(from: data, withShorterSideLength: 100 * UIScreen.main.scale) else {
            return XCTFail("Failed to create thumbnail")
        }

        // Then
        XCTAssertEqual(thumbnail.size.width, 100, accuracy: 1)
        verify(view: thumbnail.wrappedInImageView())
    }

    func testThatItCreatesThumbnailForHorizontalPanorama() {
        // Given
        let image = self.image(inTestBundleNamed: "unsplash_pano.jpg")
        guard let data = image.imageData else {
            return XCTFail("Failed to create image data")
        }

        // When
        guard let thumbnail = UIImage(from: data, withShorterSideLength: 100 * UIScreen.main.scale) else {
            return XCTFail("Failed to create a thumbnail")
        }

        // Then
        XCTAssertEqual(thumbnail.size.height, 100, accuracy: 1)
        verify(view: thumbnail.wrappedInImageView())
    }

    func testThatItReturnsEarlyForInvalidImage() {
        // Given & When
        let thumbnail = UIImage(from: Data(), withShorterSideLength: 100 * UIScreen.main.scale)

        // Then
        XCTAssertNil(thumbnail)
    }

}

// MARK: - Helper

fileprivate extension UIImage {

    func wrappedInImageView() -> UIImageView {
        let view = UIImageView()
        view.frame = CGRect(origin: .zero, size: size)
        view.image = self
        view.contentMode = .center
        return view
    }

}
