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
        sut = ConfirmAssetViewController()

        accentColor = .strongLimeGreen
        sut.image = image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        sut.previewTitle = "Matterhorn"
        verifyInAllIPhoneSizes(view: sut.view)
    }
        
    func testThatItRendersTheAssetViewControllerWithPortraitImage() {
        sut = ConfirmAssetViewController()

        accentColor = .vividRed
        sut.image = image(inTestBundleNamed: "unsplash_burger.jpg")
        sut.previewTitle = "Burger & Beer"
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testThatItRendersTheAssetViewControllerWithSmallImage() {
        sut = ConfirmAssetViewController()

        accentColor = .vividRed
        sut.image = image(inTestBundleNamed: "unsplash_small.jpg").imageScaled(withFactor: 0.5);
        sut.previewTitle = "Sea Food"
        verifyInAllIPhoneSizes(view: sut.view)
    }

}
