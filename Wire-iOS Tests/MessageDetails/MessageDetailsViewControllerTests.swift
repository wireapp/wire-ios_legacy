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

class MessageDetailsViewControllerTests: CoreDataSnapshotTestCase {

    override func setUp() {
        super.setUp()
        recordMode = true
    }

    // MARK: - Seen

    // MARK: - Empty State

    func testThatItShowsNoLikesEmptyState_14() {
        teamTest {
            // GIVEN
            let conversation = self.createGroupConversation()
            conversation.hasReadReceiptsEnabled = true

            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.sender = selfUser
            message.conversation = conversation

            let users = Set(usernames.prefix(upTo: 5).map(self.createUser))
            let receipts = users.map(MockReadReceipt.init)

            conversation.internalAddParticipants(users)
            message.readReceipts = receipts

            // WHEN
            let detailsViewController = MessageDetailsViewController(message: message)
            detailsViewController.container.selectIndex(1, animated: false)

            // THEN
            verify(view: detailsViewController.view)
        }
    }

    func testThatItShowsNoReceiptsEmptyState_DisabledInConversation_15() {
        teamTest {
            // GIVEN
            let conversation = self.createGroupConversation()
            conversation.hasReadReceiptsEnabled = false

            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.sender = selfUser
            message.conversation = conversation
            message.readReceipts = []

            // WHEN
            let detailsViewController = MessageDetailsViewController(message: message)
            detailsViewController.container.selectIndex(0, animated: false)

            // THEN
            verify(view: detailsViewController.view)
        }
    }

    func testThatItShowsNoReceiptsEmptyState_EnabledInConversation_16() {
        teamTest {
            // GIVEN
            let conversation = self.createGroupConversation()
            conversation.hasReadReceiptsEnabled = true

            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.sender = selfUser
            message.conversation = conversation
            message.readReceipts = []

            // WHEN
            let detailsViewController = MessageDetailsViewController(message: message)
            detailsViewController.container.selectIndex(0, animated: false)

            // THEN
            verify(view: detailsViewController.view)
        }
    }

    func testThatItUpdatesPlaceholderWhenReceiptsAreEnabledInConversation() {
        teamTest {
            // GIVEN
            let conversation = self.createGroupConversation()
            conversation.hasReadReceiptsEnabled = false

            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.sender = selfUser
            message.conversation = conversation
            message.readReceipts = []

            // WHEN: creating the controller
            let detailsViewController = MessageDetailsViewController(message: message)
            detailsViewController.container.selectIndex(0, animated: false)

            // WHEN: updating the conversation settings
            conversation.hasReadReceiptsEnabled = true

            let changeInfo = ConversationChangeInfo(object: conversation)
            changeInfo.changedKeys = [#keyPath(ZMConversation.hasReadReceiptsEnabled)]
            detailsViewController.dataSource.conversationDidChange(changeInfo)

            // THEN
            verify(view: detailsViewController.view)
        }
    }

    func testThatItUpdatesPlaceholderWhenReceiptsAreDisabledInConversation() {
        teamTest {
            // GIVEN
            let conversation = self.createGroupConversation()
            conversation.hasReadReceiptsEnabled = true

            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.sender = selfUser
            message.conversation = conversation
            message.readReceipts = []

            // WHEN: creating the controller
            let detailsViewController = MessageDetailsViewController(message: message)
            detailsViewController.container.selectIndex(0, animated: false)

            // WHEN: updating the conversation settings
            conversation.hasReadReceiptsEnabled = false

            let changeInfo = ConversationChangeInfo(object: conversation)
            changeInfo.changedKeys = [#keyPath(ZMConversation.hasReadReceiptsEnabled)]
            detailsViewController.dataSource.conversationDidChange(changeInfo)

            // THEN
            verify(view: detailsViewController.view)
        }
    }

    // MARK: - Non-Combined Scenarios

    func testThatItShowsReceiptsOnly_Ephemeral() {
        teamTest {
            // GIVEN
            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.sender = selfUser
            message.conversation = self.createGroupConversation()
            message.isEphemeral = true
            message.backingUsersReaction = [MessageReaction.like.unicodeValue: [otherUser]]

            // WHEN
            let detailsViewController = MessageDetailsViewController(message: message)

            // THEN
            verify(view: detailsViewController.view)
        }
    }

    func testThatItShowsLikesOnly_FromSelf_Consumer_17() {
        nonTeamTest {
            // GIVEN
            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.sender = otherUser
            message.conversation = self.createGroupConversation()

            // WHEN
            let detailsViewController = MessageDetailsViewController(message: message)

            // THEN
            verify(view: detailsViewController.view)
        }
    }

    func testThatItShowsLikesOnly_FromOther_Team_17() {
        teamTest {
            // GIVEN
            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.sender = otherUser
            message.conversation = self.createGroupConversation()

            // WHEN
            let detailsViewController = MessageDetailsViewController(message: message)

            // THEN
            verify(view: detailsViewController.view)
        }
    }

}
