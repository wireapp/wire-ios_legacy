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


private let tolerance: Float = 2


class ParticipantsCellTests: CoreDataSnapshotTestCase {

    // MARK: - Started a Conversation

    func testThatItRendersParticipantsCellStartedConversationSelfUser() {
        let sut = cell(for: .newConversation, fromSelf: true)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    func testThatItRendersParticipantsCellStartedConversationOtherUser() {
        let sut = cell(for: .newConversation, fromSelf: false)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    func testThatItRendersParticipantsCellStartedConversation_ManyUsers() {
        let sut = cell(for: .newConversation, fromSelf: false, fillUsers: .many)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    // MARK: - Added Users

    func testThatItRendersParticipantsCellAddedParticipantsSelfUser() {
        let sut = cell(for: .participantsAdded, fromSelf: true)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    func testThatItRendersParticipantsCellAddedParticipantsHerself() {
        let sut = cell(for: .participantsAdded, fromSelf: false, fillUsers: .sender)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    func testThatItRendersParticipantsCellAddedParticipantsOtherUser() {
        let sut = cell(for: .participantsAdded, fromSelf: false)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    func testThatItRendersParticipantsCellAddedParticipants_ManyUsers() {
        let sut = cell(for: .participantsAdded, fromSelf: false, fillUsers: .many)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    // MARK: - Removed Users

    func testThatItRendersParticipantsCellRemovedParticipantsSelfUser() {
        let sut = cell(for: .participantsRemoved, fromSelf: true)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    func testThatItRendersParticipantsCellRemovedParticipantsOtherUser() {
        let sut = cell(for: .participantsRemoved, fromSelf: false)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    func testThatItRendersParticipantsCellRemovedFromTeam() {
        let sut = cell(for: .teamMemberLeave, fromSelf: false)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    // MARK: - Left Users

    func testThatItRendersParticipantsCellLeftParticipant() {
        let sut = cell(for: .participantsRemoved, fromSelf: false, fillUsers: .sender)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }
    
    // MARK: - New Conversation
    
    func testThatItRendersNewConversationCellWithParticipantsAndName() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndWithoutName() {
        let sut = cell(for: .newConversation, fillUsers: .many)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }
    
    func testThatItRendersNewConversationCellWithoutParticipants() {
        let sut = cell(for: .newConversation, text: "Italy Trip")
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }
    
    // MARK: - Invite Guests
    
    func testThatItRendersNewConversationCellWithParticipantsAndName_AllowGuests() {
        let sut = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many, allowGuests: true)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndWithoutName_AllowGuests() {
        let sut = cell(for: .newConversation, fillUsers: .many, allowGuests: true)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }
    
    func testThatItRendersNewConversationCellWithoutParticipants_AllowGuests() {
        let sut = cell(for: .newConversation, text: "Italy Trip", allowGuests: true)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    // MARK: - Helper

    private func cell(for type: ZMSystemMessageType, text: String? = nil, fromSelf: Bool = false, fillUsers: Users = .one, allowGuests: Bool = false) -> ConversationCell {
        let message = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.sender = fromSelf ? selfUser : otherUser
        message.systemMessageType = type
        message.text = text
        
        message.users = {
            // We add the sender to ensure it is removed
            let users = usernames.map(createUser) + [selfUser as ZMUser, otherUser as ZMUser]
            switch fillUsers {
            case .none: return []
            case .sender: return [message.sender!]
            case .one: return Set(users[0...1])
            case .many: return Set(users)
            }
        }()
        
        if allowGuests {
            uiMOC.markAsSyncContext()
            let team = Team.fetchOrCreate(with: .create(), create: true, in: uiMOC, created: nil)
            uiMOC.markAsUIContext()
            let member = Member.getOrCreateMember(for: selfUser, in: team!, context: uiMOC)
            member.permissions = .member
            MockUser.mockSelf().isTeamMember = true
            let users = Array(message.users).filter { $0 != selfUser }
            let conversation = ZMConversation.insertGroupConversation(into: uiMOC, withParticipants: users, in: team)
            conversation?.allowGuests = true
            message.visibleInConversation = conversation
        }

        let cell = ParticipantsCell(style: .default, reuseIdentifier: nil)
        let props = ConversationCellLayoutProperties()
        cell.configure(for: message, layoutProperties: props)
        cell.layer.speed = 0
        return cell
    }

}

private enum Users {
    case none, sender, one, many
}


private extension UITableViewCell {

    func prepareForSnapshots() -> UIView {
        setNeedsLayout()
        layoutIfNeeded()

        bounds.size = systemLayoutSizeFitting(
            CGSize(width: 375, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return wrapInTableView()
    }
    
}
