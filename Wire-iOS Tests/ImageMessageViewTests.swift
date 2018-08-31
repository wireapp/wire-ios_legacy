//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import Foundation
import XCTest
import Cartography
@testable import WireExtensionComponents

class ImageMessageViewTests: ZMSnapshotTestCase {
    var sut: ImageMessageView!

    override func setUp() {
        super.setUp()
        sut = ImageMessageView()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }


    func testThatItRendersSmallImage() {
        // GIVEN & WHEN
        sut.message = MockMessageFactory.imageMessage(with: self.image(inTestBundleNamed: "unsplash_small.jpg"))
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersPortraitImage() {
        // GIVEN & WHEN
        sut.message = MockMessageFactory.imageMessage(with: self.image(inTestBundleNamed: "unsplash_burger.jpg"))
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItRendersLandscapeImage() {
        // GIVEN & WHEN
        sut.message = MockMessageFactory.imageMessage(with: self.image(inTestBundleNamed: "unsplash_matterhorn.jpg"))
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsLoadingIndicator() {
        // GIVEN & WHEN
        sut.message = MockMessageFactory.pendingImageMessage()
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
}


fileprivate extension ImageMessageView {
    func snapshotView() -> UIView {
        constrain(self) { cell in
            cell.width == 320
        }
        self.layer.speed = 0
        self.setNeedsLayout()
        self.layoutIfNeeded()
        return self
    }
}

