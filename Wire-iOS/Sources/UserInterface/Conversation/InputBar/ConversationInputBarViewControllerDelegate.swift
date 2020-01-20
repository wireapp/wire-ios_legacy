
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import Foundation

@objc protocol ConversationInputBarViewControllerDelegate: NSObjectProtocol {
    ///TODO: rm conversationInputBarViewController
    func conversationInputBarViewControllerDidComposeText(_ text: String?, mentions: [Mention]?, replyingTo message: ZMConversationMessage?)
    
    /*@objc optional*/ func conversationInputBarViewControllerShouldBeginEditing(_ controller: ConversationInputBarViewController) -> Bool
    /*@objc optional*/ func conversationInputBarViewControllerShouldEndEditing(_ controller: ConversationInputBarViewController) -> Bool
    /*@objc optional*/ func conversationInputBarViewControllerDidFinishEditing(_ message: ZMConversationMessage, withText newText: String?, mentions: [Mention])
    /*@objc optional*/ func conversationInputBarViewControllerDidCancelEditing(_ message: ZMConversationMessage)
    /*@objc optional*/ func conversationInputBarViewControllerWants(toShow message: ZMConversationMessage)
    /*@objc optional*/ func conversationInputBarViewControllerEditLastMessage()
}
