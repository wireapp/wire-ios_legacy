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

final class ConversationListFilteringTests: XCTestCase {

    let sut = ConversationListPinnedItemView()
    
    var conversations = [MockConversation]()
    
    override func setUp() {
        for _ in 0...10 { conversations.append(MockConversation()) }
    }
    
    func testThatOneConversationIsCalling() {
        conversations.first?.canJoinCall = true
        verify(pinned: 1)
    }
    
    func testThatNoConversationIsCalling() {
        verify(pinned: 0)
    }
    
    func testThatThreeConversationsAreCalling() {
        for i in 0...3 { conversations[i].canJoinCall = true }
        verify(pinned: conversations.count)
    }
    
    func testThatOneConversationIsCallingAndHangsUp() {
        conversations.first?.canJoinCall = true
        verify(pinned: 1)
        conversations.first?.canJoinCall = false
        verify(pinned: 0)
    }
    
    func testThatAllConversationsAreCalling() {
        conversations.forEach { $0.canJoinCall = true }
        verify(pinned: conversations.count)
    }
    
    private func verify(pinned: Int) {
        let incomingCalls = conversations.filterIncomingCalls(active: true).count
        let pinnedConversations = conversations.listWithIncomingCalls(true).count
        let otherConversations = conversations.listWithIncomingCalls(false).count
        
        if incomingCalls > 3 {
            XCTAssertTrue(pinnedConversations == 0)
            XCTAssertTrue(otherConversations == conversations.count)
        } else {
            XCTAssertTrue(pinnedConversations == pinned)
            XCTAssertTrue(otherConversations == conversations.count - pinned)
        }
    }
}
