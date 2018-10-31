//
//  MessageReplyPreviewViewTests.swift
//  Wire-iOS-Tests
//
//  Created by Mihail Gerasimenko on 10/31/18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
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
        snapshotBackgroundColor = UIColor(scheme: .contentBackground)
    }
    
    override func tearDown() {
        ColorScheme.default.variant = .light
        super.tearDown()
    }
    
    func activateDarkColorScheme() {
        ColorScheme.default.variant = .dark
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
        
        snapshotBackgroundColor = UIColor(scheme: .contentBackground)
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
        let message = MockMessageFactory.linkMessage()!
        let article = Article(
            originalURLString: "https://www.example.com/article/1",
            permanentURLString: "https://www.example.com/article/1",
            resolvedURLString: "https://www.example.com/article/1",
            offset: 0
        )
        
        article.title = "You won't believe what happened next!"
        let textMessageData = MockTextMessageData()
        textMessageData.linkPreview = article
        textMessageData.linkPreviewImageCacheKey = "image-id-unsplash_matterhorn.jpg"
        textMessageData.imageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9)
        textMessageData.linkPreviewHasImage = true
        message.backingTextMessageData = textMessageData
        
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
}
