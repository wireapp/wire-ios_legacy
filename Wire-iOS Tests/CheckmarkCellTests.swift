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

import UIKit
@testable import Wire

class CheckmarkCellTests: ZMSnapshotTestCase {

    var cell: CheckmarkCell!
    var conversation: MockConversation!

    override func setUp() {
        super.setUp()
        cell = CheckmarkCell(frame: CGRect(x: 0, y: 0, width: 350, height: 56))
        conversation = MockConversation.groupConversation()
    }

    override func tearDown() {
        cell = nil
        conversation = nil
        resetColorScheme()

        super.tearDown()
    }

    func testCheckmarkCell_NoCheckmark_Light() {
        cell.title = "Option A"
        cell.showCheckmark = false
        cell.colorSchemeVariant = .light
        verify(view: cell)
    }

    func testCheckmarkCell_NoCheckmark_Dark() {
        cell.title = "Option A"
        cell.showCheckmark = false
        cell.colorSchemeVariant = .dark
        verify(view: cell)
    }

    func testCheckmarkCell_WithCheckmark_Light() {
        cell.title = "Option B"
        cell.showCheckmark = true
        cell.colorSchemeVariant = .light
        verify(view: cell)

    }

    func testCheckmarkCell_WithCheckmark_Dark() {
        cell.title = "Option B"
        cell.showCheckmark = true
        cell.colorSchemeVariant = .dark
        verify(view: cell)
    }

}
