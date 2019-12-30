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


final class StartedConversationCellTests: ConversationCellSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        
        MockUser.mockSelf()?.accentColorValue = .strongBlue
    }

    // MARK: - Started a Conversation

    func testThatItRendersParticipantsCellStartedConversationSelfUser() {
        teamTest {
            let message = cell(for: .newConversation, fromSelf: true)
            verify(message: message)
        }
    }

    func testThatItRendersParticipantsCellStartedConversationOtherUser() {
        teamTest {
            let message = cell(for: .newConversation, fromSelf: false)
            verify(message: message)
        }
    }

    func testThatItRendersParticipantsCellStartedConversation_ManyUsers() {
        teamTest {
            let message = cell(for: .newConversation, fromSelf: false, fillUsers: .many)
            verify(message: message)
        }
    }
    
    // MARK: - New Conversation
    
    func testThatItRendersNewConversationCellWithNoParticipantsAndName() {
        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fromSelf: true, fillUsers: .none)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCellWithOneParticipantAndName() {
        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .justYou)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCellWithTwoParticipantsAndName() {
        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .youAndAnother)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndName() {
        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameWithOverflow() {
        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .overflow)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameWithoutOverflow() {
        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .many)
            verify(message: message)
        }
    }

    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsers() {
        teamTest {
            let message = cellForMockSystemMessage(for: .newConversation,
                                                   text: "Italy Trip",
                                                   fillUsers: .overflow,
                                                   allTeamUsers: true)
            
            let selfUser = SwiftMockUser()
            
            verify(message: message, selfUser: selfUser)
        }
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersWithGuests() {
        teamTest {
            let message = cellForMockSystemMessage(for: .newConversation,
                                                   text: "Italy Trip",
                                                   fillUsers: .many,
                                                   allTeamUsers: true,
                                                   numberOfGuests: 5)
            
            let selfUser = SwiftMockUser()
            
            verify(message: message, selfUser: selfUser)
        }
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersFromSmallTeam() {
        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .some, allTeamUsers: true)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndNameAllTeamUsersFromSmallTeamWithManyGuests() {
        teamTest {
            let message = cellForMockSystemMessage(for: .newConversation,
                                                   text: "Italy Trip",
                                                   fillUsers: .some,
                                                   allTeamUsers: true,
                                                   numberOfGuests: 10)
            
            let selfUser = SwiftMockUser()
            
            verify(message: message, selfUser: selfUser)
        }
    }

    func testThatItRendersNewConversationCellWithParticipantsAndNameFromSelfUser() {
        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fromSelf: true, fillUsers: .many)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCellWithOneParticipantAndWithoutName() {
        teamTest {
            let message = cell(for: .newConversation, fillUsers: .justYou)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCellStartedFromSelfWithOneParticipantAndWithoutName() {
        teamTest {
            let message = cell(for: .newConversation, fromSelf: true, fillUsers: .youAndAnother)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCellWithParticipantsAndWithoutName() {
        teamTest {
            let message = cell(for: .newConversation, fillUsers: .many)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCellWithoutParticipants() {
        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip")
            verify(message: message)
        }
    }
    
    // MARK: - Invite Guests
    
    func testThatItRendersNewConversationCellWithParticipantsAndName_AllowGuests() {
        recordMode = true
        teamTest {
            let message = cellForMockSystemMessage(for: .newConversation,
                                                   text: "Italy Trip",
                                                   fillUsers: .many,
                                                   allowGuests: true,
                                                   allTeamUsersAdded: false)
            
            let selfUser = SwiftMockUser()
            
            verify(message: message, selfUser: selfUser)

        }
    }
    
    func disable_testThatItRendersNewConversationCellWithParticipantsAndWithoutName_AllowGuests() {
        teamTest {
            let message = cell(for: .newConversation, fillUsers: .many, allowGuests: true)
            verify(message: message)
        }
    }
    
    func disable_testThatItRendersNewConversationCellWithoutParticipants_AllowGuests() {
        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", allowGuests: true)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCell_SelfIsCollaborator_AllowGuests() {
        teamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", fillUsers: .youAndAnother, allowGuests: true)
            selfUser.membership!.setTeamRole(.partner)
            verify(message: message)
        }
    }
    
    func testThatItRendersNewConversationCell_SelfIsGuest_AllowGuests() {
        nonTeamTest {
            let message = cell(for: .newConversation, text: "Italy Trip", allowGuests: true, numberOfGuests: 1)
            message.conversation?.teamRemoteIdentifier = .create()
            verify(message: message)
        }
    }
    
    // MARK: - Helper
    private func cellForMockSystemMessage(for type: ZMSystemMessageType,
                      text: String? = nil,
                      fillUsers: Users = .one,
                      allowGuests: Bool = false,
                      allTeamUsers: Bool = false,
                      allTeamUsersAdded: Bool = true,
                      numberOfGuests: Int16 = 0) -> ZMConversationMessage {
        let message = MockSystemMessage()
        
        let mockSystemMessageData = MockSystemMessageData(systemMessageType: .newConversation)
        mockSystemMessageData.text = text
        let otherUsers = usernames.map(createUser)
        mockSystemMessageData.users = Set(otherUsers)
        
        mockSystemMessageData.users = {
            // We add the sender to ensure it is removed
            let users = usernames.map(createUser)
            let additionalUsers: [ZMUser]
            additionalUsers = [selfUser as ZMUser]

            switch fillUsers {
            case .none: return []
            case .sender: return []
            case .justYou: return Set([selfUser])
            case .youAndAnother: return Set(users[0..<1] + [selfUser])
            case .one: return Set(users[0...1] + additionalUsers)
            case .some: return Set(users[0...4] + additionalUsers)
            case .many: return Set(users[0..<11] + additionalUsers)
            case .overflow: return Set(users + additionalUsers)
            }
        }()

        message.numberOfGuestsAdded = numberOfGuests
        message.systemMessageData = mockSystemMessageData
        message.allTeamUsersAdded = allTeamUsersAdded
        
        let sender = SwiftMockUser()
        sender.displayNameInConversation = "Bruno"
        sender.isSelfUser = false
        
        message.sender = sender
        message.systemMessageType = type
        
        let users = Array(message.users).filter { $0 != selfUser }
        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: users, team: team)
        conversation?.allowGuests = allowGuests
        conversation?.remoteIdentifier = .create()
        conversation?.teamRemoteIdentifier = team?.remoteIdentifier
        
        message.conversation = conversation

        return message
    }

    private func cell(for type: ZMSystemMessageType,
                      text: String? = nil,
                      fromSelf: Bool = false,
                      fillUsers: Users = .one,
                      allowGuests: Bool = false,
                      allTeamUsers: Bool = false,
                      numberOfGuests: Int16 = 0) -> ZMConversationMessage {
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
            case .sender: return [message.sender as! ZMUser]
            case .justYou: return Set([selfUser])
            case .youAndAnother: return Set(users[0..<1] + [selfUser])
            case .one: return Set(users[0...1] + additionalUsers)
            case .some: return Set(users[0...4] + additionalUsers)
            case .many: return Set(users[0..<11] + additionalUsers)
            case .overflow: return Set(users + additionalUsers)
            }
        }()
        
        let users = Array(message.users).filter { $0 != selfUser }
        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: users, team: team)
        conversation?.allowGuests = allowGuests
        conversation?.remoteIdentifier = .create()
        conversation?.teamRemoteIdentifier = team?.remoteIdentifier
        message.visibleInConversation = conversation
        
        return message
    }

}

private enum Users {
    case none, sender, one, some, many, justYou, youAndAnother, overflow
}

