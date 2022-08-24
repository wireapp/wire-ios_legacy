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

class GroupDetailsNotificationOptionsCellTests: CoreDataSnapshotTestCase {

    var cell: GroupDetailsNotificationOptionsCell!
    var conversation: ZMConversation!

    override func setUp() {
        selfUserInTeam = true
        super.setUp()
        cell = GroupDetailsNotificationOptionsCell(frame: CGRect(x: 0, y: 0, width: 350, height: 56))
        cell.colorSchemeVariant = .light
        conversation = self.createGroupConversation()
    }

    override func tearDown() {
        cell = nil
        conversation = nil
        resetColorScheme()
        super.tearDown()
    }

    func testThatItDisplaysCell_NoMuted() {
        update(.none)
        verify(view: cell)
    }

    func testThatItDisplaysCell_NonMentionsMuted() {
        update(.regular)
        verify(view: cell)
    }

    func testThatItDisplaysCell_AllMuted() {
        update(.all)
        verify(view: cell)
    }

    func testThatItDisplaysCell_Dark() {
        cell.colorSchemeVariant = .dark
        cell.overrideUserInterfaceStyle = .dark
        update(.all)
        verify(view: cell)
    }

    private func update(_ newValue: MutedMessageTypes) {
        conversation.mutedMessageTypes = newValue
        cell.configure(with: conversation)
    }

}
