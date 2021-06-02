//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import SnapshotTesting
@testable import Wire

class RoundedBlurViewTests: XCTestCase {

    var sut: RoundedBlurView!

    func testThat_ItBlursTheImageInTheBackground() {
        sut = RoundedBlurView()
        sut.setCornerRadius(12)
        sut.frame = CGRect(x: 50, y: 50, width: 100, height: 100)

        let frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        let container = UIView(frame: frame)
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let imageView = UIImageView(image: image)
        imageView.frame = frame
        imageView.contentMode = .scaleAspectFill

        container.addSubview(imageView)
        container.addSubview(sut)

        verify(matching: container)
    }

}
