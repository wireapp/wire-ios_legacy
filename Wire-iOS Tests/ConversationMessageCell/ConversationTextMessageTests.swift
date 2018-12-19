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
import WireLinkPreview
@testable import Wire


import XCTest

class ConversationTextMessageTests: ConversationCellSnapshotTestCase {

    override func setUp() {
        super.setUp()
    }
    
    func testPlainText() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. ")!
        message.sender = otherUser
        
        // THEN
        verify(message: message)
    }
    
    func testLinkPreview() {
        // GIVEN
        let linkURL = "http://www.example.com"
        let article = ArticleMetadata(protocolBuffer: ZMLinkPreview.linkPreview(withOriginalURL: linkURL, permanentURL: linkURL, offset: 0, title: "Biggest catastrophe in history", summary: "", imageAsset: nil))
        let message = MockMessageFactory.textMessage(withText: "http://www.example.com")!
        message.sender = otherUser
        message.backingTextMessageData.linkPreview = article
        
        // THEN
        verify(message: message)
    }
    
    func testTextWithLinkPreview() {
        // GIVEN
        let linkURL = "http://www.example.com"
        let article = ArticleMetadata(protocolBuffer: ZMLinkPreview.linkPreview(withOriginalURL: linkURL, permanentURL: linkURL, offset: 30, title: "Biggest catastrophe in history", summary: "", imageAsset: nil))
        let message = MockMessageFactory.textMessage(withText: "What do you think about this http://www.example.com")!
        message.sender = otherUser
        message.backingTextMessageData.linkPreview = article
        
        // THEN
        verify(message: message)
    }
    
    func testTextWithQuote() {
        // GIVEN
        let conversation = createGroupConversation()
        let quote = conversation.append(text: "Who is responsible for this!")
        (quote as? ZMMessage)?.serverTimestamp = Date.distantPast
        let message = MockMessageFactory.textMessage(withText: "I am")!
        message.sender = otherUser
        message.backingTextMessageData.hasQuote = true
        message.backingTextMessageData.quote = (quote as Any as! ZMMessage)
        
        // THEN
        verify(message: message)
    }
    
    func testTextWithLinkPreviewAndQuote() {
        // GIVEN
        let linkURL = "http://www.example.com"
        let article = ArticleMetadata(protocolBuffer: ZMLinkPreview.linkPreview(withOriginalURL: linkURL, permanentURL: linkURL, offset: 5, title: "Biggest catastrophe in history", summary: "", imageAsset: nil))
        let conversation = createGroupConversation()
        let quote = conversation.append(text: "Who is responsible for this!")
        (quote as? ZMMessage)?.serverTimestamp = Date.distantPast
        let message = MockMessageFactory.textMessage(withText: "I am http://www.example.com")!
        message.sender = otherUser
        message.backingTextMessageData.linkPreview = article
        message.backingTextMessageData.hasQuote = true
        message.backingTextMessageData.quote = (quote as Any as! ZMMessage)
        
        // THEN
        verify(message: message)
    }
    
    func testMediaPreviewAttachment() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "https://www.youtube.com/watch?v=l7aqpSTa234")!
        message.sender = otherUser
        
        // THEN
        verify(message: message)
    }
    
}
