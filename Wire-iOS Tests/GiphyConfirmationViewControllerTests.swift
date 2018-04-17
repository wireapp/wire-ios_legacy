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

        let data = self.data(forResource: "animated", extension: "gif")!
        let image = FLAnimatedImage(animatedGIFData: data)
        sut = GiphyConfirmationViewController(withZiph: nil, previewImage: image, searchResultController: nil)

        mockNavigationController = sut.wrapInsideNavigationController()

        sut.title = "Giphy Test"
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testAcceptButtonIsDisableWhenInit(){
        verify(view: mockNavigationController.view)
    }
}
