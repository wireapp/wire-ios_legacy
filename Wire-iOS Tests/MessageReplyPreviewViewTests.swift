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

		container.backgroundColor = UIColor.from(scheme: .contentBackground)

        return container
    }
}

final class MessageReplyPreviewViewTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        disableDarkColorScheme()
        super.tearDown()
    }

    func activateDarkColorScheme() {
        ColorScheme.default.variant = .dark
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }

    func disableDarkColorScheme() {
        ColorScheme.default.variant = .light
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }

    private func verify(message: MockMessage,
                        file: StaticString = #file,
                        testName: String = #function,
                        line: UInt = #line) {
		verifyInAllColorSchemes(createSut: {
			message.replyPreview()!.prepareForSnapshot()
		}, file: file, testName: testName, line: line)
	}

    func testThatItRendersTextMessagePreview() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")

		verify(message: message)
    }

    func testThatItRendersEmojiOnly() {
        let message = MockMessageFactory.textMessage(withText: "😀🌮")

		verify(message: message)
    }

    private func mentionMessage() -> MockMessage {
        let message = MockMessageFactory.messageTemplate()

        let textMessageData = MockTextMessageData()
        textMessageData.messageText = "Hello @user"
        let mockUser = SwiftMockLoader.mockUsers().first!
        let mention = Mention(range: NSRange(location: 6, length: 5), user: mockUser)
        textMessageData.mentions = [mention]
        message.backingTextMessageData = textMessageData

        return message
    }

    func testThatItRendersMention() {
		verify(message: mentionMessage())
    }

    func testThatItRendersTextMessagePreview_LongText() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed.")
		verify(message: message)
    }

    func testThatItRendersFileMessagePreview() {
        let message = MockMessageFactory.fileTransferMessage()
		verify(message: message)
    }

    func testThatItRendersLocationMessagePreview() {
        let message = MockMessageFactory.locationMessage()
		verify(message: message)
    }

    func testThatItRendersLinkPreviewMessagePreview() {
        let url = "https://www.example.com/article/1"
        let article = ArticleMetadata(originalURLString: url, permanentURLString: url, resolvedURLString: url, offset: 0)
        article.title = "You won't believe what happened next!"

        let message = MockMessageFactory.textMessage(withText: "https://www.example.com/article/1")
        message.backingTextMessageData.backingLinkPreview = article
        message.backingTextMessageData.linkPreviewImageCacheKey = "image-id-unsplash_matterhorn.jpg"
        message.backingTextMessageData.imageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9)
        message.backingTextMessageData.linkPreviewHasImage = true

        let previewView = message.replyPreview()!
        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verify(matching: previewView.prepareForSnapshot())
    }

    func testThatItRendersImageMessagePreview() {
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let message = MockMessageFactory.imageMessage(with: image)

        let previewView = message.replyPreview()!
        XCTAssert(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verify(matching: previewView.prepareForSnapshot())
    }

    func disable_testThatItRendersVideoMessagePreview() {
        let message = MockMessageFactory.fileTransferMessage()
        message.backingFileMessageData.mimeType = "video/mp4"
        message.backingFileMessageData.filename = "vacation.mp4"
        message.backingFileMessageData.previewData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9)

        let previewView = message.replyPreview()!
        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verify(matching: previewView.prepareForSnapshot())
    }

    func testThatItRendersAudioMessagePreview() {
        let message = MockMessageFactory.fileTransferMessage()
        message.backingFileMessageData.mimeType = "audio/x-m4a"
        message.backingFileMessageData.filename = "vacation.m4a"

        let previewView = message.replyPreview()!
        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verify(matching: previewView.prepareForSnapshot())
    }

    func testDeallocation() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")
        verifyDeallocation {
            return message.replyPreview()!
        }
    }
}
