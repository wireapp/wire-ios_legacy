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

import Foundation
import XCTest
@testable import Wire
import WireLinkPreview

extension UIView {
    fileprivate func prepareForSnapshot(_ size: CGSize = CGSize(width: 320, height: 216)) -> UIView {
        let container = ReplyRoundCornersView(containedView: self)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        container.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        
        container.setNeedsLayout()
        container.layoutIfNeeded()
        return container
    }
}

class MessageReplyPreviewViewTests: ZMSnapshotTestCase {
    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = UIColor.from(scheme: .contentBackground)
    }
    
    override func tearDown() {
        disableDarkColorScheme()
        super.tearDown()
    }
    
    func activateDarkColorScheme() {
        ColorScheme.default.variant = .dark
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
        
        snapshotBackgroundColor = UIColor.from(scheme: .contentBackground)
    }

    func disableDarkColorScheme() {
        ColorScheme.default.variant = .light
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }
    
    func testThatItRendersTextMessagePreview() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")!
        verify(view: message.replyPreview()!.prepareForSnapshot())
    }
    
    func testThatItRendersTextMessagePreview_dark() {
        activateDarkColorScheme()
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")!
        verify(view: message.replyPreview()!.prepareForSnapshot())
    }
    
    func testThatItRendersEmojiOnly() {
        let message = MockMessageFactory.textMessage(withText: "😀🌮")!
        verify(view: message.replyPreview()!.prepareForSnapshot())
    }
    
    func testThatItRendersEmojiOnly_dark() {
        activateDarkColorScheme()

        let message = MockMessageFactory.textMessage(withText: "😀🌮")!
        verify(view: message.replyPreview()!.prepareForSnapshot())
    }
    
    func mentionMessage() -> MockMessage {
        let message = MockMessageFactory.messageTemplate()
        
        let textMessageData = MockTextMessageData()
        textMessageData.messageText = "Hello @user"
        let mockUser = MockUser.mockUsers()[0]
        let mention = Mention(range: NSRange(location: 6, length: 5), user: mockUser)
        textMessageData.mentions = [mention]
        message.backingTextMessageData = textMessageData
        
        return message
    }
    
    func testThatItRendersMention() {
        verify(view: mentionMessage().replyPreview()!.prepareForSnapshot())
    }
    
    func testThatItRendersMention_dark() {
        activateDarkColorScheme()
        verify(view: mentionMessage().replyPreview()!.prepareForSnapshot())
    }
    
    func testThatItRendersTextMessagePreview_LongText() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed.")!
        verify(view: message.replyPreview()!.prepareForSnapshot())
    }
    
    func testThatItRendersTextMessagePreview_LongText_dark() {
        activateDarkColorScheme()
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed.")!
        verify(view: message.replyPreview()!.prepareForSnapshot())
    }
    
    func testThatItRendersFileMessagePreview() {
        let message = MockMessageFactory.fileTransferMessage()!
        verify(view: message.replyPreview()!.prepareForSnapshot())
    }
    
    func testThatItRendersFileMessagePreview_dark() {
        activateDarkColorScheme()
        let message = MockMessageFactory.fileTransferMessage()!
        verify(view: message.replyPreview()!.prepareForSnapshot())
    }
    
    func testThatItRendersLocationMessagePreview() {
        let message = MockMessageFactory.locationMessage()!
        verify(view: message.replyPreview()!.prepareForSnapshot())
    }
    
    func testThatItRendersLocationMessagePreview_dark() {
        activateDarkColorScheme()
        let message = MockMessageFactory.locationMessage()!
        verify(view: message.replyPreview()!.prepareForSnapshot())
    }
    
    func testThatItRendersLinkPreviewMessagePreview() {
        let url = "https://www.example.com/article/1"
        let article = ArticleMetadata(originalURLString: url, permanentURLString: url, resolvedURLString: url, offset: 0)
        article.title = "You won't believe what happened next!"

        let message = MockMessageFactory.textMessage(withText: "https://www.example.com/article/1")!
        message.backingTextMessageData.linkPreview = article
        message.backingTextMessageData.linkPreviewImageCacheKey = "image-id-unsplash_matterhorn.jpg"
        message.backingTextMessageData.imageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9)
        message.backingTextMessageData.linkPreviewHasImage = true
        
        let previewView = message.replyPreview()!
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        
        verify(view: previewView.prepareForSnapshot())
    }

    func testThatItRendersImageMessagePreview() {
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let message = MockMessageFactory.imageMessage(with: image)!

        let previewView = message.replyPreview()!
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))

        verify(view: previewView.prepareForSnapshot())
    }

    func testThatItRendersVideoMessagePreview() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.mimeType = "video/mp4"
        message.backingFileMessageData.filename = "vacation.mp4"
        message.backingFileMessageData.previewData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9)
        
        let previewView = message.replyPreview()!
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        
        verify(view: previewView.prepareForSnapshot())
    }
    
    func testThatItRendersAudioMessagePreview() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.mimeType = "audio/x-m4a"
        message.backingFileMessageData.filename = "vacation.m4a"
        
        let previewView = message.replyPreview()!
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        
        verify(view: previewView.prepareForSnapshot())
    }
    
    func testDeallocation() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")!
        self.verifyDeallocation {
            return message.replyPreview()!
        }
    }
}
