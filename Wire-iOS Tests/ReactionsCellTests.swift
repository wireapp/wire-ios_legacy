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

@testable import Wire
import Cartography

class ReactionsCellTests: ZMSnapshotTestCase {

    var sut: ReactionCell!

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
        accentColor = .strongBlue
        sut = ReactionCell(frame: .zero)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItRendersReactionCellWithoutUsername() {
        sut.user = MockUser.mockUsers().first
        verifyInAllPhoneWidths(view: sut.snapshotView())
    }

    func testThatItRendersReactionCellWithUsername() {
        sut.user = MockUser.mockUsers().last
        verifyInAllPhoneWidths(view: sut.snapshotView())
    }

}

fileprivate extension UICollectionViewCell {
    func snapshotView() -> UIView {
        constrain(self) { cell in
            cell.height == 52
        }
        return self
    }
}
