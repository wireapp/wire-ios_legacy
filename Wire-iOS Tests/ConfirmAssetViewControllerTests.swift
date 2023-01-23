//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import FLAnimatedImage
@testable import Wire

final class ConfirmAssetViewControllerTests: ZMSnapshotTestCase {

    var sut: ConfirmAssetViewController!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItRendersTheAssetViewControllerWithLandscapeImage() {
        sut = ConfirmAssetViewController(context: ConfirmAssetViewController.Context(asset: .image(mediaAsset: image(inTestBundleNamed: "unsplash_matterhorn.jpg"))))

        accentColor = .strongLimeGreen
        sut.previewTitle = "Matterhorn"

        verifyAllIPhoneSizes(matching: sut)
    }

    func testThatItRendersTheAssetViewControllerWithPortraitImage() {
        sut = ConfirmAssetViewController(context: ConfirmAssetViewController.Context(asset: .image(mediaAsset: image(inTestBundleNamed: "unsplash_burger.jpg"))))

        accentColor = .vividRed
        sut.previewTitle = "Burger & Beer"

        verifyAllIPhoneSizes(matching: sut)
    }

    func testThatItRendersTheAssetViewControllerWithSmallImage() {
        sut = ConfirmAssetViewController(context: ConfirmAssetViewController.Context(asset: .image(mediaAsset: image(inTestBundleNamed: "unsplash_small.jpg").imageScaled(with: 0.5)!)))

        accentColor = .vividRed
        sut.previewTitle = "Sea Food"

        verifyAllIPhoneSizes(matching: sut)
    }
}

// MARK: - GIF

extension ConfirmAssetViewControllerTests {
    func testThatItShowsEditOptionsForSignalFrameGIF() {
        // GIVEN & WHEN
        sut = ConfirmAssetViewController(context: ConfirmAssetViewController.Context(asset: .image(mediaAsset: image(inTestBundleNamed: "not_animated.gif"))))

        // THEN
        XCTAssert(sut.showEditingOptions)
    }

    func testThatItHidesEditOptionsForAnimatedGIF() {
        // GIVEN & WHEN
        let data = dataInTestBundleNamed("animated.gif")
        sut = ConfirmAssetViewController(context: ConfirmAssetViewController.Context(asset: .image(mediaAsset: FLAnimatedImage(animatedGIFData: data))))

        // THEN
        XCTAssertFalse(sut.showEditingOptions)
    }
}
