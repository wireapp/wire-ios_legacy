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
import FLAnimatedImage

final class GiphyConfirmationViewControllerTests: ZMSnapshotTestCase {
    
    var sut: GiphyConfirmationViewController!
    var mockNavigationController: UINavigationController!
    
    override func setUp() {
        super.setUp()
        ///TODO: a gif
        let data = self.data(forResource: "animated", extension: "gif")!
        let image = FLAnimatedImage(animatedGIFData: data)
        sut = GiphyConfirmationViewController(withZiph: nil, previewImage: image, searchResultController: nil)

        mockNavigationController = wrapInsideNavigationController()

        sut.title = "Giphy Test"
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func wrapInsideNavigationController() -> UINavigationController {
        let navigationController = GiphyNavigationController(rootViewController: sut)

        var backButtonImage = UIImage(for: .backArrow, iconSize: .tiny, color: .black)
        backButtonImage = backButtonImage?.withInsets(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0), backgroundColor: .clear)
        backButtonImage = backButtonImage?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: -4, right: 0))
        navigationController.navigationBar.backIndicatorImage = backButtonImage
        navigationController.navigationBar.backIndicatorTransitionMaskImage = backButtonImage

        navigationController.navigationBar.backItem?.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationController.navigationBar.tintColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground)
        navigationController.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: ColorScheme.default().variant)
        navigationController.navigationBar.barTintColor = ColorScheme.default().color(withName: ColorSchemeColorBackground)
        navigationController.navigationBar.isTranslucent = false

        return navigationController
    }

    func testAcceptButtonIsDisableWhenInit(){
        verify(view: mockNavigationController.view)
    }
}
