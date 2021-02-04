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

final class MessageDetailsViewControllerTests: XCTestCase {
    
    var conversation: SwiftMockConversation!
    var mockSelfUser: MockUserType!
    var otherUser: MockUserType!

    override func setUp() {
        super.setUp()
        
        mockSelfUser = MockUserType.createSelfUser(name: "Alice")
        otherUser = MockUserType.createDefaultOtherUser()
        SelfUser.provider = SelfProvider(selfUser: mockSelfUser)
    }
    
    override func tearDown() {
        SelfUser.provider = nil
        conversation = nil
        
        super.tearDown()
    }
    
    // MARK: - Seen
    func testThatItShowsReceipts_ShortList_11() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation(inTeam: true)
        
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.current
        message.conversationLike = conversation
        message.deliveryState = .read
        message.needsReadConfirmation = true
        
        let users = XCTestCase.usernames.prefix(upTo: 5).map({
            MockUserType.createUser(name: $0)
        })
        ///TODO: refactor this after ReadReceipt added UserType property
        let receipts = users.map(MockReadReceipt.init)
        
        message.readReceipts = receipts
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: Array(users.prefix(upTo: 4))]
        
        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message)
        detailsViewController.container.selectIndex(0, animated: false)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    func testThatItShowsReceipts_ShortList_Edited_11() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation(inTeam: true)
        
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.current
        message.conversationLike = conversation
        message.updatedAt = Date(timeIntervalSince1970: 69)
        message.deliveryState = .read
        message.needsReadConfirmation = true
        
        let users = XCTestCase.usernames.prefix(upTo: 5).map({
            MockUserType.createUser(name: $0)
        })
        let receipts = users.map(MockReadReceipt.init)
        
        message.readReceipts = receipts
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: Array(users.prefix(upTo: 4))]
        
        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message)
        detailsViewController.container.selectIndex(0, animated: false)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    func testThatItShowsReceipts_LongList_12() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation(inTeam: true)
        
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.current
        message.conversationLike = conversation
        message.updatedAt = Date(timeIntervalSince1970: 69)
        message.deliveryState = .read
        message.needsReadConfirmation = true
        
        let users = XCTestCase.usernames.prefix(upTo: 20).map({
            MockUserType.createUser(name: $0)
        })
        let receipts = users.map(MockReadReceipt.init)
        
        message.readReceipts = receipts
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: Array(users.prefix(upTo: 4))]
        
        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message)
        detailsViewController.container.selectIndex(0, animated: false)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    func testThatItShowsLikes_13() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation(inTeam: true)
        
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.current
        message.conversationLike = conversation
        message.deliveryState = .read
        message.needsReadConfirmation = true
        
        let users = XCTestCase.usernames.prefix(upTo: 6).map({
            MockUserType.createUser(name: $0)
        })
//        users.forEach {
            ///TODO: handle gen
//            $0.setHandle($0.name)
//        }
        
        message.readReceipts =  users.map(MockReadReceipt.init)
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: Array(users.prefix(upTo: 4))]
        
        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message)
        detailsViewController.container.selectIndex(1, animated: false)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    // MARK: - Empty State
    
    func testThatItShowsNoLikesEmptyState_14() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation(inTeam: true)
        
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.current
        message.conversationLike = conversation
        message.deliveryState = .sent
        message.needsReadConfirmation = true
        
        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message)
        detailsViewController.container.selectIndex(1, animated: false)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    func testThatItShowsNoReceiptsEmptyState_DisabledInConversation_15() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation(inTeam: true)
        
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.current
        message.conversationLike = conversation
        message.readReceipts = []
        message.deliveryState = .sent
        message.needsReadConfirmation = false
        
        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message)
        detailsViewController.container.selectIndex(0, animated: false)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    func testThatItShowsNoReceiptsEmptyState_EnabledInConversation_16() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation(inTeam: true)
        
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.current
        message.conversationLike = conversation
        message.readReceipts = []
        message.deliveryState = .sent
        message.needsReadConfirmation = true
        
        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message)
        detailsViewController.container.selectIndex(0, animated: false)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    func testThatItShowsBothTabs_WhenMessageIsSeenButNotLiked() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation(inTeam: true)
        
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.current
        message.conversationLike = conversation
        message.readReceipts = [MockReadReceipt(user: otherUser)]
        message.deliveryState = .read
        message.needsReadConfirmation = true
        
        // WHEN: creating the controller
        let detailsViewController = MessageDetailsViewController(message: message)
        detailsViewController.container.selectIndex(0, animated: false)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    // MARK: - Non-Combined Scenarios
    
    func testThatItShowsReceiptsOnly_Ephemeral() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation(inTeam: true)
        
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.current
        message.conversationLike = conversation
        message.isEphemeral = true
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [otherUser]]
        message.needsReadConfirmation = true
        
        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    func testThatItShowsLikesOnly_FromSelf_Consumer_17() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation()
        
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = MockUserType.createUser(name: "Bruno")
        message.conversationLike = conversation
        message.needsReadConfirmation = false
        
        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    func testThatItShowsLikesOnly_FromOther_Team_17() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation(inTeam: true)
        
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = MockUserType.createUser(name: "Bruno")
        message.conversationLike = conversation
        message.needsReadConfirmation = false
        
        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    func testThatItShowsReceiptsOnly_Pings() {
        // GIVEN
        conversation = SwiftMockConversation.createMockGroupConversation(inTeam: true)
        
        let message = MockMessageFactory.pingMessage()!
        message.senderUser = SelfUser.current
        message.conversationLike = conversation
        message.needsReadConfirmation = true
        
        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message)
        
        // THEN
        snapshot(detailsViewController)
    }
    
    // MARK: - Deallocation
    
    /*func testThatItDeallocates() {
        conversation = SwiftMockConversation.createMockGroupConversation()
        verifyDeallocation { () -> MessageDetailsViewController in
            // GIVEN
            let message = MockMessageFactory.textMessage(withText: "Message", mockConversation: conversation)
            message.senderUser = SelfUser.current
            message.conversationLike = conversation
            
            //            let users = usernames.prefix(upTo: 5).map({
            MockUserType.createUser(name: $0)
        })
            //            let receipts = users.map(MockReadReceipt.init)
            
            //                message.readReceipts = receipts
            //            message.backingUsersReaction = [MessageReaction.like.unicodeValue: Array(users.prefix(upTo: 4))]
            
            // WHEN
            let detailsViewController = MessageDetailsViewController(message: message)
            detailsViewController.container.selectIndex(0, animated: false)
            return detailsViewController
        }
    }*/
    
    // MARK: - Helpers
    
    private func snapshot(_ detailsViewController: MessageDetailsViewController, configuration: ((MessageDetailsViewController) -> Void)? = nil,
                          file: StaticString = #file,
                          testName: String = #function,
                          line: UInt = #line) {
        detailsViewController.reloadData()
        configuration?(detailsViewController)
        verify(matching: detailsViewController,
               file: file,
               testName: testName,
               line: line)
    }
    
}
