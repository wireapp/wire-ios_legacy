//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


@testable import Wire
import Cartography


class ReactionsListViewControllerTests: ZMSnapshotTestCase {
    

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .whiteColor()
    }
    
    func testThatItRendersReactionsListViewController() {
        let sut = ReactionsListViewController(message: message)
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        verify(view: sut.view)
    }
    
    var message: ZMConversationMessage {
        let message = MockMessageFactory.textMessageWithText("Hello")
        message.deliveryState = .Sent
        
        let users = MockUser.mockUsers().map { $0 as! ZMUser }
        message.backingUsersReaction = [
            ZMMessageReaction.Like.rawValue: users
        ]

        return message
    }
    
}
