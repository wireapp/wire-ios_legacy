//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import SnapshotTesting

final class SketchColorPickerControllerSnapshotTests: XCTestCase {

    var sut: SketchColorPickerController!

    override func setUp() {
        super.setUp()
        sut = SketchColorPickerController()

        sut.sketchColors = [.black,
                            .white,
                            SemanticColors.LegacyColors.strongBlue,
                            SemanticColors.LegacyColors.strongLimeGreen,
                            SemanticColors.LegacyColors.brightYellow,
                            SemanticColors.LegacyColors.vividRed,
                            SemanticColors.LegacyColors.brightOrange,
                            SemanticColors.LegacyColors.softPink,
                            SemanticColors.LegacyColors.violet,
                            UIColor(red: 0.688, green: 0.342, blue: 0.002, alpha: 1),
                            UIColor(red: 0.381, green: 0.192, blue: 0.006, alpha: 1),
                            UIColor(red: 0.894, green: 0.735, blue: 0.274, alpha: 1),
                            UIColor(red: 0.905, green: 0.317, blue: 0.466, alpha: 1),
                            UIColor(red: 0.58, green: 0.088, blue: 0.318, alpha: 1),
                            UIColor(red: 0.431, green: 0.65, blue: 0.749, alpha: 1),
                            UIColor(red: 0.6, green: 0.588, blue: 0.278, alpha: 1),
                            UIColor(red: 0.44, green: 0.44, blue: 0.44, alpha: 1)]

        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 48)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForInitState() {
        verify(matching: sut)
    }

    func testForAllItemsAreVisible() {
        sut.view.frame = CGRect(x: 0, y: 0, width: 768, height: 48)
        verify(matching: sut)
    }

    func testForColorButtonBumpedThreeTimes() {
        // GIVEN & WHEN
        for _ in 1...3 {
            sut.collectionView(sut.colorsCollectionView, didSelectItemAt: IndexPath(item: 1, section: 0))
        }

        // THEN
        verify(matching: sut)
    }
}
