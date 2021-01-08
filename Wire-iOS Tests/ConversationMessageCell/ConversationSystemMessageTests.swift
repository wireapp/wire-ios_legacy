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

final class ConversationSystemMessageTests: ConversationCellSnapshotTestCase {

    func testConversationIsSecure() {
        let message = MockMessageFactory.systemMessage(with: .conversationIsSecure)!

        verify(message: message)
    }

    func testRenameConversation() {
        let message = MockMessageFactory.systemMessage(with: .conversationNameChanged, users: 0, clients: 0)!
        message.backingSystemMessageData.text = "Blue room"
        message.senderUser = SwiftMockLoader.mockUsers().first

        verify(message: message)
    }

    func testAddParticipant() {
        let message = MockMessageFactory.systemMessage(with: .participantsAdded, users: 1, clients: 0)!
        message.senderUser = SwiftMockLoader.mockUsers().last

        verify(message: message)
    }

    func testAddParticipant_Service() {
        let message = MockMessageFactory.systemMessage(with: .participantsAdded, users: 1, clients: 0)!
        message.senderUser = SwiftMockLoader.mockUsers().last
        message.backingSystemMessageData?.userTypes = Set<AnyHashable>([MockServiceUserType .createServiceUser(name: "GitHub")])

        verify(message: message)
    }

    func testAddManyParticipants() {
        let message = MockMessageFactory.systemMessage(with: .participantsAdded, users: 10, clients: 0)!
        message.senderUser = SwiftMockLoader.mockUsers().last

        verify(message: message)
    }

    func testRemoveParticipant() {
        let message = MockMessageFactory.systemMessage(with: .participantsRemoved, users: 1, clients: 0)!
        message.senderUser = SwiftMockLoader.mockUsers().last

        verify(message: message, allColorSchemes: true)
    }

    func testTeamMemberLeave() {
        let message = MockMessageFactory.systemMessage(with: .teamMemberLeave, users: 1, clients: 0)!
        message.senderUser = SwiftMockLoader.mockUsers().last

        verify(message: message)
    }

    func testDecryptionFailed() {
        let message = MockMessageFactory.systemMessage(with: .decryptionFailed, users: 0, clients: 0)!

        verify(message: message)
    }

    func testNewClient_oneUser_oneClient() {
        let message = MockMessageFactory.systemMessage(with: .newClient, users: 1, clients: 1)!

        verify(message: message)
    }

    func testNewClient_selfUser_oneClient() {
        let message = MockMessageFactory.systemMessage(with: .newClient, users: 1, clients: 1)!
        message.backingSystemMessageData?.userTypes = Set<AnyHashable>([MockUserType.createSelfUser(name: "")])

        verify(message: message)
    }

    func testNewClient_selfUser_manyClients() {
        let message = MockMessageFactory.systemMessage(with: .newClient, users: 1, clients: 2)!
        message.backingSystemMessageData?.userTypes = Set<AnyHashable>([MockUserType.createSelfUser(name: "")])

        verify(message: message)
    }

    func testNewClient_oneUser_manyClients() {
        let message = MockMessageFactory.systemMessage(with: .newClient, users: 1, clients: 3)!

        verify(message: message)
    }

    func testNewClient_manyUsers_manyClients() {
        let message = MockMessageFactory.systemMessage(with: .newClient, users: 3, clients: 4)!

        verify(message: message)
    }

    func testUsingNewDevice() {
        let message = MockMessageFactory.systemMessage(with: .usingNewDevice, users: 1, clients: 1)!
        message.backingSystemMessageData?.userTypes = Set<AnyHashable>([MockUserType.createSelfUser(name: "")])

        verify(message: message)
    }

    func testReactivatedDevice() {
        let message = MockMessageFactory.systemMessage(with: .reactivatedDevice)!

        verify(message: message)
    }

    // MARK: - read receipt

    func testReadReceiptIsOn() {
        let message = MockMessageFactory.systemMessage(with: .readReceiptsOn)!

        verify(message: message)
    }

    func testReadReceiptIsOnByThirdPerson() {
        let message = MockMessageFactory.systemMessage(with: .readReceiptsEnabled)!
        message.senderUser = SwiftMockLoader.mockUsers().first

        verify(message: message)
    }

    func testReadReceiptIsOffByYou() {
        let message = MockMessageFactory.systemMessage(with: .readReceiptsDisabled)!

        verify(message: message)
    }

    // MARK: - ignored client

    func testIgnoredClient_self() {
        let message = MockMessageFactory.systemMessage(with: .ignoredClient)!
        message.backingSystemMessageData?.userTypes = Set<AnyHashable>([MockUserType.createSelfUser(name: "")])

        verify(message: message)
    }

    func testIgnoredClient_other() {
        let message = MockMessageFactory.systemMessage(with: .ignoredClient)!
        message.backingSystemMessageData?.userTypes = Set<AnyHashable>([SwiftMockLoader.mockUsers().last])

        verify(message: message)
    }

    // MARK: - Legal Hold

    func testThatItRendersLegalHoldEnabledInConversation() {
        let mockUser = MockUserType.createSelfUser(name: "John Doe", inTeam: nil)
        mockUser.isUnderLegalHold = true
        let message = MockMessageFactory.systemMessage(with: .legalHoldEnabled, users: 2, clients: 2, sender: mockUser)!
        XCTAssertTrue(message.senderUser?.isUnderLegalHold ?? false)
        verify(message: message)
    }

    func testThatItRendersLegalHoldDisabledInConversation() {
        let message = MockMessageFactory.systemMessage(with: .legalHoldDisabled)!
        XCTAssertFalse(message.senderUser?.isUnderLegalHold ?? false)
        verify(message: message)
    }

    // MARK: - potential gap

    func testPotentialGap() {
        let message = MockMessageFactory.systemMessage(with: .potentialGap)!

        verify(message: message)
    }

    func testPotentialGap_addedUsers() {
        let message = MockMessageFactory.systemMessage(with: .potentialGap)!

        message.assignMockAddedUser()

        verify(message: message)
    }

    func testPotentialGap_removedUsers() {
        let message = MockMessageFactory.systemMessage(with: .potentialGap)!

        message.assignMockRemovedUsers(users: SwiftMockLoader.mockUsers().prefix(1))

        verify(message: message)
    }

    func testPotentialGap_addedAndRemovedUsers() {
        let message = MockMessageFactory.systemMessage(with: .potentialGap)!

        message.assignMockAddedUser()
        message.assignMockRemovedUsers(users: SwiftMockLoader.mockUsers().suffix(1))

        verify(message: message)
    }

}

extension MockMessage {
    func assignMockAddedUser() {
        backingSystemMessageData?.addedUserTypes = Set<AnyHashable>(Array(SwiftMockLoader.mockUsers().prefix(1)))
    }

    func assignMockRemovedUsers(users: ArraySlice<MockUserType>) {
        backingSystemMessageData?.removedUserTypes = Set<MockUserType>(users)
    }
}
