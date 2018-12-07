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


class ParticipantsCellTests: CoreDataSnapshotTestCase {
    
    override func setUp() {
        super.setUp()

        selfUserInTeam = true
        MockUser.mockSelf()?.accentColorValue = .strongBlue
    }

    // MARK: - Started a Conversation

    func testThatItRendersParticipantsCellStartedConversationSelfUser() {
        let sut = cell(for: .newConversation, fromSelf: true)
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersParticipantsCellStartedConversationOtherUser() {
        let sut = cell(for: .newConversation, fromSelf: false)
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersParticipantsCellStartedConversation_ManyUsers() {
        let sut = cell(for: .newConversation, fromSelf: false, fillUsers: .many)
        verify(view: sut.prepareForSnapshots())
    }

    // MARK: - Added Users

    func testThatItRendersParticipantsCellAddedParticipantsSelfUser() {
        let sut = cell(for: .participantsAdded, fromSelf: true)
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersParticipantsCellAddedParticipantsOtherUser() {
        let sut = cell(for: .participantsAdded, fromSelf: false)
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersParticipantsCellAddedParticipants_ManyUsers() {
        let sut = cell(for: .participantsAdded, fromSelf: false, fillUsers: .many)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersParticipantsCellAddedParticipants_Overflow() {
        let sut = cell(for: .participantsAdded, fromSelf: false, fillUsers: .overflow)
        verify(view: sut.prepareForSnapshots())
    }
    
    // MARK: - Joined Users
    
    func testThatItRendersParticipantsCellAddedParticipantsHerself() {
        let sut = cell(for: .participantsAdded, fromSelf: false, fillUsers: .sender)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersParticipantsCellAddedParticipantsSelfUserOnly() {
        let sut = cell(for: .participantsAdded, fromSelf: true, fillUsers: .sender)
        verify(view: sut.prepareForSnapshots())
    }

    // MARK: - Removed Users

    func testThatItRendersParticipantsCellRemovedParticipantsSelfUser() {
        let sut = cell(for: .participantsRemoved, fromSelf: true)
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersParticipantsCellRemovedParticipantsOtherUser() {
        let sut = cell(for: .participantsRemoved, fromSelf: false)
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersParticipantsCellRemovedFromTeam() {
        let sut = cell(for: .teamMemberLeave, fromSelf: false)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersParticipantsCellRemovedWithOverflow() {
        let sut = cell(for: .participantsRemoved, fromSelf: false, fillUsers: .overflow)
        verify(view: sut.prepareForSnapshots())
    }

    // MARK: - Left Users

    func testThatItRendersParticipantsCellLeftParticipant() {
        let sut = cell(for: .participantsRemoved, fromSelf: false, fillUsers: .sender)
        verify(view: sut.prepareForSnapshots())
    }
    
    // MARK: - New Conversation
    
    func testThatItRendersNewConversationCellWithNoParticipantsAndName() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fromSelf: true, fillUsers: .none)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithOneParticipantAndName() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .justYou)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithTwoParticipantsAndName() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .youAndAnother)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndName() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameWithOverflow() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .overflow)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameWithoutOverflow() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsers() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .overflow, allTeamUsers: true)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersWithGuests() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many, allTeamUsers: true, numberOfGuests: 5)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersFromSmallTeam() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .some, allTeamUsers: true)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersFromSmallTeamWithManyGuests() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .some, allTeamUsers: true, numberOfGuests: 10)
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersNewConversationCellWithParticipantsAndNameFromSelfUser() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fromSelf: true, fillUsers: .many)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndWithoutName() {
        let sut = cell(for: .newConversation, fillUsers: .many)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithoutParticipants() {
        let sut = cell(for: .newConversation, text: "Italy Trip")
        verify(view: sut.prepareForSnapshots())
    }
    
    // MARK: - Invite Guests
    
    func testThatItRendersNewConversationCellWithParticipantsAndName_AllowGuests() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many, allowGuests: true)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndWithoutName_AllowGuests() {
        let sut = cell(for: .newConversation, fillUsers: .many, allowGuests: true)
        verify(view: sut.prepareForSnapshots())
    }
    
    func testThatItRendersNewConversationCellWithoutParticipants_AllowGuests() {
        let sut = cell(for: .newConversation, text: "Italy Trip", allowGuests: true)
        verify(view: sut.prepareForSnapshots())
    }
    
    // MARK: - Helper

    private func cell(for type: ZMSystemMessageType, text: String? = nil, fromSelf: Bool = false, fillUsers: Users = .one, allowGuests: Bool = false, allTeamUsers: Bool = false, numberOfGuests: Int16 = 0) -> ConversationCell {
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
        
        uiMOC.markAsSyncContext()
        let team = Team.fetchOrCreate(with: .create(), create: true, in: uiMOC, created: nil)
        uiMOC.markAsUIContext()
        let member = Member.getOrCreateMember(for: selfUser, in: team!, context: uiMOC)
        member.permissions = .member
        let users = Array(message.users).filter { $0 != selfUser }
        let conversation = ZMConversation.insertGroupConversation(into: uiMOC, withParticipants: users, in: team)
        conversation?.allowGuests = allowGuests
        conversation?.teamRemoteIdentifier = .create()
        conversation?.remoteIdentifier = .create()
        message.visibleInConversation = conversation
        
        let cell = ParticipantsCell(style: .default, reuseIdentifier: nil)
        let props = ConversationCellLayoutProperties()
        cell.configure(for: message, layoutProperties: props)
        cell.layer.speed = 0
        return cell
    }

}

private enum Users {
    case none, sender, one, some, many, justYou, youAndAnother, overflow
}

