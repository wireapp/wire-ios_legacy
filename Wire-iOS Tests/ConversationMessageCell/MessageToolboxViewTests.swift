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

final class MessageToolboxViewTests: CoreDataSnapshotTestCase {

    var message: MockMessage!
    var sut: MessageToolboxView!

    override func setUp() {
        super.setUp()
        message = MockMessageFactory.textMessage(withText: "Hello")
        message.deliveryState = .sent
        message.conversation = otherUserConversation

        sut = MessageToolboxView()
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 28)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItConfiguresWithFailedToSend() {
        // GIVEN
        message.deliveryState = .failedToSend

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: true, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItConfiguresWith1To1ConversationReadReceipt() {
        // GIVEN
        message.deliveryState = .read

        let readReceipt = MockReadReceipt(user: otherUser)
        readReceipt.serverTimestamp = Date(timeIntervalSince1970: 12345678564)
        message.readReceipts = [readReceipt]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: true, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItConfiguresWithGroupConversationReadReceipt() {
        // GIVEN
        message.conversation = createGroupConversation()
        message.deliveryState = .read

        let readReceipt = MockReadReceipt(user: otherUser)
        message.readReceipts = [readReceipt]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: true, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItConfiguresWithTimestamp() {
        // GIVEN
        let users = MockUser.mockUsers().filter { !$0.isSelfUser }
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: users]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: true, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItConfiguresWithTimestamp_Unselected_NoLikers() {
        // GIVEN
        message.backingUsersReaction = [:]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: false, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItConfiguresWithOtherLiker() {
        // GIVEN
        let users = MockUser.mockUsers().first(where: { !$0.isSelfUser })!
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [users]]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: false, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItConfiguresWithReadThenLiked() {
        // GIVEN
        message.deliveryState = .read

        let readReceipt = MockReadReceipt(user: otherUser)
        readReceipt.serverTimestamp = Date(timeIntervalSince1970: 12345678564)
        message.readReceipts = [readReceipt]

        ///liked after read
        let users = MockUser.mockUsers().first(where: { !$0.isSelfUser })!
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [users]]


        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: false, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItConfiguresWithOtherLikers() {
        // GIVEN
        let users = MockUser.mockUsers().filter { !$0.isSelfUser }
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: users]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: false, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItConfiguresWithSelfLiker() {
        // GIVEN
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: false, animated: false)

        // THEN
        verify(view: sut)
    }

    // MARK: - Tap Gesture

    func testThatItOpensReceipts_NoLikers() {
        // WHEN
        message.conversation = createTeamGroupConversation()
        sut.configureForMessage(message, forceShowTimestamp: false, animated: false)
        
        // THEN
        XCTAssertEqual(sut.preferredDetailsDisplayMode(), .receipts)
    }

    func testThatItOpensReceipts_WithLikers_ShowingTimestamp() {
        // GIVEN
        message.conversation = createTeamGroupConversation()
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]
        
        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: true, animated: false)
        
        // THEN
        XCTAssertEqual(sut.preferredDetailsDisplayMode(), .receipts)
    }

    func testThatItOpensLikesWhenTapped_ReceiptsEnabled() {
        // GIVEN
        message.conversation = createTeamGroupConversation()
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]
        
        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: false, animated: false)
        
        // THEN
        XCTAssertEqual(sut.preferredDetailsDisplayMode(), .reactions)
    }

    func testThatItOpensLikesWhenTapped_ReceiptsDisabled() {
        // GIVEN
        message.conversation = createGroupConversation()
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: false, animated: false)

        // THEN
        XCTAssertEqual(sut.preferredDetailsDisplayMode(), .reactions)
    }

    func testThatItDoesNotShowLikes_ReceiptsDisabled_ShowingTimestamp() {
        // GIVEN
        message.conversation = createGroupConversation()
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: true, animated: false)

        // THEN
        XCTAssertNil(sut.preferredDetailsDisplayMode())
    }

    func testThatItDisplaysTimestamp_Countdown_OtherUser() {
        // GIVEN
        message.conversation = createGroupConversation()
        message.senderUser = MockUserType.createUser(name: "Bruno")
        message.isEphemeral = true
        message.destructionDate = Date().addingTimeInterval(10)

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: true, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItDisplaysTimestamp_ReadReceipts_Countdown_SelfUser() {
        // GIVEN
        message.conversation = createGroupConversation()
        message.senderUser = MockUserType.createSelfUser(name: "Alice")
        message.readReceipts = [MockReadReceipt(user: otherUser)]
        message.deliveryState = .read
        message.isEphemeral = true
        message.destructionDate = Date().addingTimeInterval(10)

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: true, animated: false)

        // THEN
        verifyInAllPhoneWidths(view: sut)

    }

    func testThatItDisplaysLongListOfLikers() {
        // GIVEN
        let conversation = createGroupConversation()
        message.conversation = conversation
        message.senderUser = MockUserType.createSelfUser(name: "Alice")

        let remoteUser = createUser(name: "Esteban Julio Ricardo Montoya de la Rosa Ramírez")
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [otherUser, remoteUser]]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: false, animated: false)

        // THEN
        verify(view: sut)
    }

}
