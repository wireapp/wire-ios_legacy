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

extension ZMConversation {

    func add(participants: Set<ZMUser>) {
        addParticipantsAndUpdateConversationState(users: participants, role: nil)
    }

    func add(participants: [ZMUser]) {
        add(participants: Set(participants))
    }

    func add(participants: ZMUser...) {
        add(participants: Set(participants))
    }
}

final class GroupParticipantsDetailViewControllerTests: CoreDataSnapshotTestCase {
    
    override func tearDown() {
        resetColorScheme()
        super.tearDown()
    }
    
    func testThatItRendersALotOfUsers() {
        // given
        let users = (0..<20).map { createUser(name: "User #\($0)") }
        let selected = Array(users.dropLast(15))
        let conversation = createGroupConversation()
        conversation.add(participants: users)
        
        // when
        let sut = GroupParticipantsDetailViewController(selectedParticipants: selected, conversation: conversation)
        
        // then
        let wrapped = sut.wrapInNavigationController()
        verify(view: wrapped.view)
    }
    
    func testThatItRendersALotOfUsers_Dark() {
        // given
        ColorScheme.default.variant = .dark
        let users = (0..<20).map { createUser(name: "User #\($0)") }
        let selected = Array(users.dropLast(15))
        let conversation = createGroupConversation()
       conversation.add(participants: users)
        
        // when
        let sut = GroupParticipantsDetailViewController(selectedParticipants: selected, conversation: conversation)
        
        // then
        let wrapped = sut.wrapInNavigationController()
        verify(view: wrapped.view)
        ColorScheme.default.variant = .light
    }
    
    func testEmptyState() {
        // given
        let selected:[ZMUser] = []
        let conversation = createGroupConversation()
        
        // when
        let sut = GroupParticipantsDetailViewController(selectedParticipants: selected, conversation: conversation)
        sut.viewModel.admins = []
        sut.viewModel.members = []
        sut.setupViews()
        sut.participantsDidChange()

        // then
        let wrapped = sut.wrapInNavigationController()
        verify(view: wrapped.view)
    }
}
