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

final class StartedConversationCellTests: XCTestCase {

    var mockSelfUser: MockUserType!
    var mockOtherUser: MockUserType!

    override func setUp() {
        super.setUp()

        UIColor.setAccentOverride(.vividRed)
        SelfUser.setupMockSelfUser(inTeam: UUID())
        
        mockSelfUser = SelfUser.current as? MockUserType
        mockSelfUser.accentColorValue = .strongBlue

        mockOtherUser = MockUserType.createDefaultOtherUser()
    }

    override func tearDown() {
        mockSelfUser = nil
        mockOtherUser = nil
        
        super.tearDown()
    }

    // MARK: - Started a Conversation

    func testThatItRendersParticipantsCellStartedConversationSelfUser() {
            let message = cell(for: .newConversation, fromSelf: true)
            verify(message: message)
    }

    func testThatItRendersParticipantsCellStartedConversationOtherUser() {
//        teamTest {
            let message = cell(for: .newConversation, fromSelf: false)
            verify(message: message)
//        }
    }

    func testThatItRendersParticipantsCellStartedConversation_ManyUsers() {
//        teamTest {
            let message = cell(for: .newConversation, fromSelf: false, fillUsers: .many)
            verify(message: message)
//        }
    }

    // MARK: - New Conversation

    func testThatItRendersNewConversationCellWithNoParticipantsAndName() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fromSelf: true, fillUsers: .none)
            verify(message: message)
//        }
    }

    ///TODO
    func testThatItRendersNewConversationCellWithOneParticipantAndName() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .justYou)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithTwoParticipantsAndName() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .youAndAnother)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithParticipantsAndName() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithParticipantsAndNameWithOverflow() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .overflow)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithParticipantsAndNameWithoutOverflow() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsers() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .overflow, allTeamUsers: true)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersWithGuests() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many, allTeamUsers: true, numberOfGuests: 5)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersFromSmallTeam() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .some, allTeamUsers: true)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersFromSmallTeamWithManyGuests() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .some, allTeamUsers: true, numberOfGuests: 10)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithParticipantsAndNameFromSelfUser() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fromSelf: true, fillUsers: .many)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithOneParticipantAndWithoutName() {
//        teamTest {
            let message = cell(for: .newConversation, fillUsers: .justYou)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellStartedFromSelfWithOneParticipantAndWithoutName() {
//        teamTest {
            let message = cell(for: .newConversation, fromSelf: true, fillUsers: .youAndAnother)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithParticipantsAndWithoutName() {
//        teamTest {
            let message = cell(for: .newConversation, fillUsers: .many)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithoutParticipants() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip")
            verify(message: message)
//        }
    }

    // MARK: - Invite Guests

    func testThatItRendersNewConversationCellWithParticipantsAndName_AllowGuests() {
//        teamTest {
        
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many, allowGuests: true)
//            createARoleForSelfUserWith(["add_conversation_member"], conversation: message.conversation!)
            verify(message: message)
//        }
    }

    /*func testThatItRendersNewConversationCellWithParticipantsAndWithoutName_AllowGuests() {
//        teamTest {
            let message = cell(for: .newConversation, fillUsers: .many, allowGuests: true)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCellWithoutParticipants_AllowGuests() {
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", allowGuests: true)
            createARoleForSelfUserWith(["add_conversation_member"], conversation: message.conversation!)
            verify(message: message)
//        }
    }*/
/*
    func testThatItRendersNewConversationCell_SelfIsCollaborator_AllowGuests() {///TODO: crash?
//        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .youAndAnother, allowGuests: true)
            mockSelfUser.membership!.setTeamRole(.partner)
            createARoleForSelfUserWith(["modify_conversation_access"], conversation: message.conversation!)
            verify(message: message)
//        }
    }

    func testThatItRendersNewConversationCell_SelfIsGuest_AllowGuests() {
//        nonTeamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", allowGuests: true, numberOfGuests: 1)
            message.conversation?.teamRemoteIdentifier = .create()
            createARoleForSelfUserWith(["modify_conversation_access"], conversation: message.conversation!)
            verify(message: message)
//        }
    }*/

    // MARK: - Helper

    private func cell(for type: ZMSystemMessageType,
                      text: String? = nil,
                      fromSelf: Bool = false,
                      fillUsers: Users = .one,
                      allowGuests: Bool = false,
                      allTeamUsers: Bool = false,
                      numberOfGuests: Int16 = 0) -> ZMConversationMessage {
        let message = MockMessageFactory.systemMessage(with: type)!
        message.senderUser = fromSelf ? mockSelfUser : mockOtherUser
//        message.text = text
//        message.numberOfGuestsAdded = numberOfGuests
//        message.allTeamUsersAdded = allTeamUsers

//        let messageS = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        ///TODO: ZMSystemMessage.userTypes
        
        let data = message.systemMessageData as! MockSystemMessageData
        data.text = text
        data.userTypes = {
//        message.users = {
            // We add the sender to ensure it is removed
            let users: [MockUserType] = XCTestCase.usernames.map{MockUserType.createUser(name: $0)}
            
            let additionalUsers: [MockUserType] = [mockSelfUser, mockOtherUser]
            switch fillUsers {
            case .none: return []
            case .sender: return [message.sender!]
            case .justYou: return Set([mockSelfUser])
            case .youAndAnother: return Set(users[0..<1] + [mockSelfUser])
            case .one: return Set(users[0...1] + additionalUsers)
            case .some: return Set(users[0...4] + additionalUsers)
            case .many: return Set(users[0..<11] + additionalUsers)
            case .overflow: return Set(users + additionalUsers)
            }
        }()

        
//        let users = Array(message.users).filter { $0 != mockSelfUser }
//        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: users, team: team)
//        conversation?.remoteIdentifier = .create()
//        conversation?.teamRemoteIdentifier = team?.remoteIdentifier
//        createARoleForSelfUserWith(["add_conversation_member", "modify_conversation_access"], conversation: conversation!)
        let conversation = SwiftMockConversation()
        conversation.allowGuests = allowGuests
        message.conversationLike = conversation
//        message.visibleInConversation = conversation

        return message
    }

    private func createARoleForSelfUserWith(_ actionNames: [String], conversation: ZMConversation) {
//        let participantRole = ParticipantRole.insertNewObject(in: uiMOC)
//        participantRole.conversation = conversation
//        participantRole.user = selfUser
//
        var actions: [Action] = []
//        actionNames.forEach { (actionName) in
//            let action = Action.insertNewObject(in: uiMOC)
//            action.name = actionName
//            actions.append(action)
//        }
//
//        let adminRole = Role.insertNewObject(in: uiMOC)
//        adminRole.name = "wire_admin"
//        adminRole.actions = Set(actions)
//        participantRole.role = adminRole
//
//        mockSelfUser.participantRoles = Set([participantRole])
    }

}

private enum Users {
    case none, sender, one, some, many, justYou, youAndAnother, overflow
}
