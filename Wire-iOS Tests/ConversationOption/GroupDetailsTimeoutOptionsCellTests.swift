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

final class GroupDetailsTimeoutOptionsCellTests: CoreDataSnapshotTestCase {

    var cell: GroupDetailsTimeoutOptionsCell!
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()
        cell = GroupDetailsTimeoutOptionsCell(frame: CGRect(x: 0, y: 0, width: 350, height: 56))
        conversation = createGroupConversation()
    }

    override func tearDown() {
        cell = nil
        conversation = nil
        resetColorScheme()
        super.tearDown()
    }

    func testThatItDisplaysCell_WithoutTimeout_Light() {
        updateTimeout(0)
        cell.colorSchemeVariant = .light
        verify(view: cell)
    }

    func testThatItDisplaysCell_WithoutTimeout_Dark() {
        updateTimeout(0)
        cell.colorSchemeVariant = .dark
        verify(view: cell)
    }

    func testThatItDisplaysCell_WithTimeout_Light() {
        updateTimeout(300)
        cell.colorSchemeVariant = .light
        verify(view: cell)
    }

    func testThatItDisplaysCell_WithTimeout_Dark() {
        updateTimeout(300)
        cell.colorSchemeVariant = .dark
        verify(view: cell)
    }

    private func updateTimeout(_ newValue: TimeInterval) {
        conversation.messageDestructionTimeout = .synced(MessageDestructionTimeoutValue(rawValue: newValue))
        cell.configure(with: (conversation as Any) as! ZMConversation)
    }

}
