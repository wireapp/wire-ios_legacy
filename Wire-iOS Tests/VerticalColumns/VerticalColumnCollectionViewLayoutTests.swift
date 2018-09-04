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

class VerticalColumnCollectionViewLayoutTests: ZMSnapshotTestCase {

    var tiles: [ColorTile]! = [
        // square, downscale
        ColorTile(color: .vividRed, size: CGSize(width: 1000, height: 1000)),
        // square, upscale
        ColorTile(color: .violet, size: CGSize(width: 10, height: 10)),
        // portrait, downscale
        ColorTile(color: .brightYellow, size: CGSize(width: 1000, height: 1500)),
        // landscape, upscale
        ColorTile(color: .softPink, size: CGSize(width: 15, height: 10)),
        // landscape, downscale
        ColorTile(color: .strongBlue, size: CGSize(width: 1500, height: 1000)),
        // portrait, upscale
        ColorTile(color: .strongLimeGreen, size: CGSize(width: 10, height: 15)),
        // add 4 more to test multiline on iPad
        ColorTile(color: .vividRed, size: CGSize(width: 1000, height: 1000)),
        ColorTile(color: .strongLimeGreen, size: CGSize(width: 10, height: 15)),
        ColorTile(color: .violet, size: CGSize(width: 10, height: 10)),
        ColorTile(color: .brightYellow, size: CGSize(width: 1000, height: 1500)),
    ]

    override func tearDown() {
        tiles = nil
        super.tearDown()
    }

    func testThatVerticalLayoutAdaptsToDeviceSize() {
        let sut = ColorTilesViewController(tiles: tiles)

        verifyInAllDeviceSizes(view: sut.view) { _, isTablet in
            sut.isTablet = isTablet
        }
    }

}

