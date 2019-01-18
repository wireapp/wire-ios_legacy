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


import XCTest
@testable import Wire


class StartedConversationCellTests: ConversationCellSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        
        selfUserInTeam = true
        MockUser.mockSelf()?.accentColorValue = .strongBlue
    }

    // MARK: - Started a Conversation

    func testThatItRendersParticipantsCellStartedConversationSelfUser() {
        let message = cell(for: .newConversation, fromSelf: true)
        verify(message: message)
    }

    func testThatItRendersParticipantsCellStartedConversationOtherUser() {
        let message = cell(for: .newConversation, fromSelf: false)
        verify(message: message)
    }

    func testThatItRendersParticipantsCellStartedConversation_ManyUsers() {
        let message = cell(for: .newConversation, fromSelf: false, fillUsers: .many)
        verify(message: message)
    }
    
    // MARK: - New Conversation
    
    func testThatItRendersNewConversationCellWithNoParticipantsAndName() {
        let message = cell(for: .newConversation, text: "Italy Trip", fromSelf: true, fillUsers: .none)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithOneParticipantAndName() {
        let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .justYou)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithTwoParticipantsAndName() {
        let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .youAndAnother)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndName() {
        let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameWithOverflow() {
        let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .overflow)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameWithoutOverflow() {
        let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsers() {
        let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .overflow, allTeamUsers: true)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersWithGuests() {
        let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many, allTeamUsers: true, numberOfGuests: 5)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersFromSmallTeam() {
        let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .some, allTeamUsers: true)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersFromSmallTeamWithManyGuests() {
        let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .some, allTeamUsers: true, numberOfGuests: 10)
        verify(message: message)
    }

    func testThatItRendersNewConversationCellWithParticipantsAndNameFromSelfUser() {
        let message = cell(for: .newConversation, text: "Italy Trip", fromSelf: true, fillUsers: .many)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithOneParticipantAndWithoutName() {
        let message = cell(for: .newConversation, fillUsers: .justYou)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellStartedFromSelfWithOneParticipantAndWithoutName() {
        let message = cell(for: .newConversation, fromSelf: true, fillUsers: .youAndAnother)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndWithoutName() {
        let message = cell(for: .newConversation, fillUsers: .many)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithoutParticipants() {
        let message = cell(for: .newConversation, text: "Italy Trip")
        verify(message: message)
    }
    
    // MARK: - Invite Guests
    
    func testThatItRendersNewConversationCellWithParticipantsAndName_AllowGuests() {
        let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many, allowGuests: true)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndWithoutName_AllowGuests() {
        let message = cell(for: .newConversation, fillUsers: .many, allowGuests: true)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCellWithoutParticipants_AllowGuests() {
        let message = cell(for: .newConversation, text: "Italy Trip", allowGuests: true)
        verify(message: message)
    }
    
    func testThatItRendersNewConversationCell_SelfIsGuest_AllowGuests() {
        selfUserInTeam = false
        let message = cell(for: .newConversation, text: "Italy Trip", allowGuests: true, numberOfGuests: 1)
        verify(message: message)
    }
    
    // MARK: - Helper

    private func cell(for type: ZMSystemMessageType, text: String? = nil, fromSelf: Bool = false, fillUsers: Users = .one, allowGuests: Bool = false, allTeamUsers: Bool = false, numberOfGuests: Int16 = 0) -> ZMConversationMessage {
        let message = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.sender = fromSelf ? selfUser : otherUser
        message.systemMessageType = type
        message.text = text
        message.numberOfGuestsAdded = numberOfGuests
        message.allTeamUsersAdded = allTeamUsers

        message.users = {
            // We add the sender to ensure it is removed
            let users = usernames.map(createUser)
            let additionalUsers = [selfUser as ZMUser, otherUser as ZMUser]
            switch fillUsers {
            case .none: return []
            case .sender: return [message.sender!]
            case .justYou: return Set([selfUser])
            case .youAndAnother: return Set(users[0..<1] + [selfUser])
            case .one: return Set(users[0...1] + additionalUsers)
            case .some: return Set(users[0...4] + additionalUsers)
            case .many: return Set(users[0..<11] + additionalUsers)
            case .overflow: return Set(users + additionalUsers)
            }
        }()
        
        var team: Team? = nil
        
        if selfUserInTeam {
            uiMOC.markAsSyncContext()
            team = Team.fetchOrCreate(with: .create(), create: true, in: uiMOC, created: nil)
            uiMOC.markAsUIContext()
            let member = Member.getOrCreateMember(for: selfUser, in: team!, context: uiMOC)
            member.permissions = .member
        }
        
        let users = Array(message.users).filter { $0 != selfUser }
        let conversation = ZMConversation.insertGroupConversation(into: uiMOC, withParticipants: users, in: team)
        conversation?.allowGuests = allowGuests
        conversation?.teamRemoteIdentifier = .create()
        conversation?.remoteIdentifier = .create()
        message.visibleInConversation = conversation
        
        return message
    }

}

private enum Users {
    case none, sender, one, some, many, justYou, youAndAnother, overflow
}

