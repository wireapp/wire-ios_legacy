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
        let sut = cell(for: .newConversation, fromSelf: false, userCount: .many)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    // MARK: - Added Users

    func testThatItRendersParticipantsCellAddedParticipantsSelfUser() {
        let sut = cell(for: .participantsAdded, fromSelf: true)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    func testThatItRendersParticipantsCellAddedParticipantsOtherUser() {
        let sut = cell(for: .participantsAdded, fromSelf: false)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    func testThatItRendersParticipantsCellAddedParticipants_ManyUsers() {
        let sut = cell(for: .participantsAdded, fromSelf: false, userCount: .many)
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

    // MARK: - Left Users

    func testThatItRendersParticipantsCellLeftParticipant() {
        let sut = cell(for: .participantsRemoved, fromSelf: false, left: true)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }
    
    // MARK: - New Conversation
    
    func testThatItRendersNewConversationCellWithParticipantsAndName() {
        let sut = cell(for: .newConversation, text: "Italy Trip", userCount: .many)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndWithoutName() {
        let sut = cell(for: .newConversation, userCount: .many)
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }
    
    func testThatItRendersNewConversationCellWithoutParticipants() {
        let sut = cell(for: .newConversation, text: "Italy Trip")
        verify(view: sut.prepareForSnapshots(), tolerance: tolerance)
    }

    // MARK: - Helper

    private func cell(for type: ZMSystemMessageType, text: String? = nil, fromSelf: Bool = false, userCount: UserCount = .one, left: Bool = false) -> ConversationCell {
        let message = ZMSystemMessage.insertNewObject(in: uiMOC)
        message.sender = fromSelf ? selfUser : otherUser
        message.systemMessageType = type
        message.text = text

        if !left {
            message.users = {
                // We add the sender to ensure it is removed
                let users = usernames.map(createUser) + [selfUser as ZMUser, otherUser as ZMUser]
                switch userCount {
                case .none: return []
                case .one: return Set(users[0...1])
                case .many: return Set(users)
                }
            }()
        } else {
            message.users = [message.sender!]
        }

        let cell = ParticipantsCell(style: .default, reuseIdentifier: nil)
        let props = ConversationCellLayoutProperties()
        cell.configure(for: message, layoutProperties: props)
        cell.layer.speed = 0
        return cell
    }

}

private enum UserCount {
    case none, one, many
}


private extension UITableViewCell {

    func prepareForSnapshots() -> UIView {
        setNeedsLayout()
        layoutIfNeeded()

        bounds.size = systemLayoutSizeFitting(
            CGSize(width: 375, height: 0),
            withHorizontalFittingPriority: UILayoutPriorityRequired,
            verticalFittingPriority: UILayoutPriorityFittingSizeLevel
        )

        return wrapInTableView()
    }
    
}
