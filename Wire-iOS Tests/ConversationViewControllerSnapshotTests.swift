//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class ConversationViewControllerSnapshotTests: CoreDataSnapshotTestCase {
    
    var sut: ConversationViewController!

    var mockConversation: ZMConversation!
    var mockZMUserSession: MockZMUserSession!
//    var mockMessage: MockMessage!

    override func setUp() {
        super.setUp()

        mockConversation = createTeamGroupConversation()

//        mockMessage = MockMessageFactory.textMessage(withText: "Message")!
//        mockMessage.sender = selfUser
//        mockMessage.conversation = mockConversation
//        mockMessage.deliveryState = .read
//        mockMessage.needsReadConfirmation = true

        mockZMUserSession = MockZMUserSession()

        sut = ConversationViewController()

        sut.conversation = mockConversation
        sut.session = mockZMUserSession

        sut.loadViewIfNeeded()

        ///injection after the viewDidLoad


        /// TODO: remove this after snapshot is created
        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForInitState(){
        verify(view: sut.view)
    }
}
