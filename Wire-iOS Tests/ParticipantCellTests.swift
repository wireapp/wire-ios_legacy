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
        let sut = cell(for: .newConversation, fromSelf: false, manyUsers: true)
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
        let sut = cell(for: .participantsAdded, fromSelf: false, manyUsers: true)
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

    // MARK: - Helper

    private func cell(for type: ZMSystemMessageType, fromSelf: Bool, manyUsers: Bool = false) -> IconSystemCell {
        let message = ZMSystemMessage.insertNewObject(in: moc)
        message.sender = fromSelf ? selfUser : otherUser
        message.systemMessageType = type

        let users = ["Anna", "Bruno", "Claire", "Dean", "Erik", "Frank", "Gregor", "Hanna", "Inge", "James", "Laura", "Klaus"].map(createUser)
        message.users = manyUsers ? Set(users) : Set(users[0...1])

        let cell = ParticipantsCell(style: .default, reuseIdentifier: nil)
        let props = ConversationCellLayoutProperties()
        cell.configure(for: message, layoutProperties: props)
        cell.layer.speed = 0
        return cell
    }

    private func createUser(name: String) -> ZMUser {
        let user = ZMUser.insertNewObject(in: moc)
        user.name = name
        user.remoteIdentifier = UUID()
        return user
    }

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
