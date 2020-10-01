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

final class ConversationTextMessageTests: ConversationCellSnapshotTestCase {

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
        let linkPreview = LinkPreview.with {
            $0.url = linkURL
            $0.permanentURL = linkURL
            $0.urlOffset = 0
            $0.title = "Biggest catastrophe in history"
            $0.summary = ""
        }
        let article = ArticleMetadata(protocolBuffer: linkPreview)
        let message = MockMessageFactory.textMessage(withText: "http://www.example.com")!
        message.sender = otherUser
        message.backingTextMessageData.backingLinkPreview = article
        
        // THEN
        verify(message: message)
    }
    
    func testTextWithLinkPreview() {
        // GIVEN
        let linkURL = "http://www.example.com"
        let linkPreview = LinkPreview.with {
            $0.url = linkURL
            $0.permanentURL = linkURL
            $0.urlOffset = 0
            $0.title = "Biggest catastrophe in history"
            $0.summary = ""
        }
        let article = ArticleMetadata(protocolBuffer: linkPreview)
        let message = MockMessageFactory.textMessage(withText: "What do you think about this http://www.example.com")!
        message.sender = otherUser
        message.backingTextMessageData.backingLinkPreview = article
        
        // THEN
        verify(message: message)
    }
    
    func testTextWithQuote() {
        // GIVEN
        let conversation = createGroupConversation()
        let quote = try! conversation.appendText(content: "Who is responsible for this!")
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
        let linkPreview = LinkPreview.with {
            $0.url = linkURL
            $0.permanentURL = linkURL
            $0.urlOffset = 5
            $0.title = "Biggest catastrophe in history"
            $0.summary = ""
        }
        let article = ArticleMetadata(protocolBuffer: linkPreview)
        let conversation = createGroupConversation()
        let quote = try! conversation.appendText(content: "Who is responsible for this!")
        (quote as? ZMMessage)?.serverTimestamp = Date.distantPast
        let message = MockMessageFactory.textMessage(withText: "I am http://www.example.com")!
        message.sender = otherUser
        message.backingTextMessageData.backingLinkPreview = article
        message.backingTextMessageData.hasQuote = true
        message.backingTextMessageData.quote = (quote as Any as! ZMMessage)
        
        // THEN
        verify(message: message)
    }
    
    func testMediaPreviewAttachment() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "https://www.youtube.com/watch?v=l7aqpSTa234")!
        message.sender = otherUser
        message.linkAttachments = [
            LinkAttachment(type: .youTubeVideo, title: "Lagar mat med Fernando Di Luca",
                           permalink: URL(string: "https://www.youtube.com/watch?v=l7aqpSTa234")!,
                           thumbnails: [], originalRange: NSRange(location: 0, length: 43))
        ]
        
        // THEN
        verify(message: message, waitForTextViewToLoad: true)
    }

    func testSoundCloudMediaPreviewAttachment() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "https://soundcloud.com/bridgitmendler/bridgit-mendler-atlantis-feat-kaiydo")!
        message.sender = otherUser
        message.linkAttachments = [
            LinkAttachment(type: .soundCloudTrack, title: "Bridgit Mendler - Atlantis feat. Kaiydo",
                           permalink: URL(string: "https://soundcloud.com/bridgitmendler/bridgit-mendler-atlantis-feat-kaiydo")!,
                           thumbnails: [], originalRange: NSRange(location: 0, length: 74))
        ]

        // THEN
        verify(message: message, waitForTextViewToLoad: true)
    }

    func testSoundCloudSetMediaPreviewAttachment() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "https://soundcloud.com/playback/sets/2019-artists-to-watch")!
        message.sender = otherUser
        message.linkAttachments = [
            LinkAttachment(type: .soundCloudPlaylist, title: "Artists To Watch 2019",
                           permalink: URL(string: "https://soundcloud.com/playback/sets/2019-artists-to-watch")!,
                           thumbnails: [], originalRange: NSRange(location: 0, length: 58))
        ]

        // THEN
        verify(message: message, waitForTextViewToLoad: true)
    }

    func testBlacklistedLinkPreview_YouTube() {
        // GIVEN
        let linkURL = "https://youtube.com/watch"
        let linkPreview = LinkPreview.with {
            $0.url = linkURL
            $0.permanentURL = linkURL
            $0.urlOffset = 14
            $0.title = "Lagar mat med Fernando Di Luca"
            $0.summary = ""
        }
        let article = ArticleMetadata(protocolBuffer: linkPreview)
        let message = MockMessageFactory.textMessage(withText: "Look at this! https://www.youtube.com/watch?v=l7aqpSTa234")!
        message.sender = otherUser
        message.backingTextMessageData.backingLinkPreview = article
        message.linkAttachments = [
            LinkAttachment(type: .youTubeVideo, title: "Lagar mat med Fernando Di Luca",
                           permalink: URL(string: "https://www.youtube.com/watch?v=l7aqpSTa234")!,
                           thumbnails: [], originalRange: NSRange(location: 14, length: 43))
        ]
        
        // THEN
        verify(message: message)
    }

}
