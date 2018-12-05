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
        message.conversation?.conversationType = .oneOnOne
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
        message.conversation?.conversationType = .group
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
        message.conversation?.conversationType = .oneOnOne
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
        let selfUser = (MockUser.mockSelf() as Any) as! ZMUser
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: false, animated: false)

        // THEN
        verify(view: sut)
    }

    // MARK: - Tap Gesture

    func testThatItOpensReceipts_NoLikers() {
        teamTest {
            // WHEN
            sut.configureForMessage(message, forceShowTimestamp: false, animated: false)

            // THEN
            XCTAssertEqual(sut.preferredDetailsDisplayMode(), .receipts)
        }
    }

    func testThatItOpensReceipts_WithLikers_ShowingTimestamp() {
        teamTest {
            // GIVEN
            let selfUser = (MockUser.mockSelf() as Any) as! ZMUser
            message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]

            // WHEN
            sut.configureForMessage(message, forceShowTimestamp: true, animated: false)

            // THEN
            XCTAssertEqual(sut.preferredDetailsDisplayMode(), .receipts)
        }
    }

    func testThatItOpensLikesWhenTapped_ReceiptsEnabled() {
        teamTest {
            // GIVEN
            let selfUser = (MockUser.mockSelf() as Any) as! ZMUser
            message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]

            // WHEN
            sut.configureForMessage(message, forceShowTimestamp: false, animated: false)

            // THEN
            XCTAssertEqual(sut.preferredDetailsDisplayMode(), .reactions)
        }
    }

    func testThatItOpensLikesWhenTapped_ReceiptsDisabled() {
        // GIVEN
        let selfUser = (MockUser.mockSelf() as Any) as! ZMUser
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: false, animated: false)

        // THEN
        XCTAssertEqual(sut.preferredDetailsDisplayMode(), .reactions)
    }

    func testThatItDoesNotShowLikes_ReceiptsDisabled_ShowingTimestamp() {
        // GIVEN
        let selfUser = (MockUser.mockSelf() as Any) as! ZMUser
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: true, animated: false)

        // THEN
        XCTAssertNil(sut.preferredDetailsDisplayMode())
    }

}
