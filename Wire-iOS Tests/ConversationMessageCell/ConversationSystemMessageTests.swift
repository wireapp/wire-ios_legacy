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

class ConversationSystemMessageTests: ConversationCellSnapshotTestCase {

    override func setUp() {
        super.setUp()
    }

    func testRenameConversation() {
        let message = MockMessageFactory.systemMessage(with: .conversationNameChanged, users: 0, clients: 0)!
        message.backingSystemMessageData.text = "Blue room"
        message.sender = MockUser.mockUsers()?.first
        
        verify(message: message)
    }
    
    func testAddParticipant() {
        let message = MockMessageFactory.systemMessage(with: .participantsAdded, users: 1, clients: 0)!
        message.sender = MockUser.mockUsers()?.last
        
        verify(message: message)
    }
    
    func testAddManyParticipants() {
        let message = MockMessageFactory.systemMessage(with: .participantsAdded, users: 10, clients: 0)!
        message.sender = MockUser.mockUsers()?.last
        
        verify(message: message)
    }
    
    func testRemoveParticipant() {
        let message = MockMessageFactory.systemMessage(with: .participantsRemoved, users: 1, clients: 0)!
        message.sender = MockUser.mockUsers()?.last
        
        verify(message: message)
    }
    
    func testTeamMemberLeave() {
        let message = MockMessageFactory.systemMessage(with: .teamMemberLeave, users: 1, clients: 0)!
        message.sender = MockUser.mockUsers()?.last
        
        verify(message: message)
    }

}
