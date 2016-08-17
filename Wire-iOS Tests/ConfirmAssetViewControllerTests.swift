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

import Cartography
@testable import Wire

class ConfirmAssetViewControllerTests: ZMSnapshotTestCase {

    var sut: ConfirmAssetViewController!
    
    override func setUp() {
        super.setUp()
        sut = ConfirmAssetViewController()
        snapshotBackgroundColor = .whiteColor()
    }

    func testThatItRendersTheAssetViewControllerWithLandscapeImage() {
        accentColor = .StrongBlue
        sut.image = imageInTestBundleNamed("unsplash_matterhorn.jpg")
        sut.editButtonVisible = true
        sut.previewTitle = "Matterhorn"
        verifyInAllIPhoneSizes(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersTheAssetViewControllerWithLandscapeImage_WithoutEditButton() {
        accentColor = .SoftPink
        sut.image = imageInTestBundleNamed("unsplash_matterhorn.jpg")
        sut.previewTitle = "Matterhorn"
        verifyInAllIPhoneSizes(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersTheAssetViewControllerWithPortraitImage() {
        accentColor = .VividRed
        sut.image = imageInTestBundleNamed("unsplash_burger.jpg")
        sut.editButtonVisible = true
        sut.previewTitle = "Burger & Beer"
        verifyInAllIPhoneSizes(view: sut.prepareForSnapshot())
    }

}

private extension UIViewController {
    func prepareForSnapshot() -> UIView {
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
        return view
    }
}
