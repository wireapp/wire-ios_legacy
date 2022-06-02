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

class LinkPreviewTests: ConversationTestsBase {

    var mockLinkPreviewDetector: MockLinkPreviewDetector!

    override func setUp() {
        super.setUp()

        mockLinkPreviewDetector = MockLinkPreviewDetector()

        LinkPreviewDetectorHelper.setTest_debug_linkPreviewDetector(mockLinkPreviewDetector)
    }

    override func tearDown() {
        mockLinkPreviewDetector = nil

        LinkPreviewDetectorHelper.setTest_debug_linkPreviewDetector(nil)

        super.tearDown()
    }

    func assertMessageContainsLinkPreview(_ message: ZMClientMessage, linkPreviewURL: MockLinkPreviewDetector.LinkPreviewURL, file: StaticString = #file, line: UInt = #line) {
        if let linkPreview = message.underlyingMessage?.linkPreviews.first {
            let expectedLinkPreview = LinkPreview(mockLinkPreviewDetector.linkMetaData(linkPreviewURL))
            switch linkPreviewURL {
            case .articleWithPicture, .tweetWithPicture:
                XCTAssertTrue(linkPreview.image.hasUploaded, "Link preview with image didn't contain uploaded asset", file: file, line: line)

                // We don't compare the whole proto buffer since the mock one won't have the uploaded image
                XCTAssertEqual(linkPreview.urlOffset, expectedLinkPreview.urlOffset)
                XCTAssertEqual(linkPreview.title, expectedLinkPreview.title)
                XCTAssertEqual(linkPreview.summary, expectedLinkPreview.summary)
            case .article:
                XCTAssertEqual(linkPreview.urlOffset, expectedLinkPreview.urlOffset)
                XCTAssertEqual(linkPreview.title, expectedLinkPreview.title)
                XCTAssertEqual(linkPreview.summary, expectedLinkPreview.summary)
            case .tweet:
                XCTAssertEqual(linkPreview.urlOffset, expectedLinkPreview.urlOffset)
                XCTAssertEqual(linkPreview.title, expectedLinkPreview.title)
                XCTAssertEqual(linkPreview.summary, expectedLinkPreview.summary)
                XCTAssertEqual(linkPreview.tweet, expectedLinkPreview.tweet)
            }
        } else {
            XCTFail("Message didn't contain a link preview", file: file, line: line)
        }
    }

    func testThatItInsertsCorrectLinkPreviewMessage_ArticleWithoutImage() {
        // given
        XCTAssertTrue(login())
        let conversation = self.conversation(for: selfToUser1Conversation)

        // when
        userSession?.perform {
            try! conversation?.appendText(content: MockLinkPreviewDetector.LinkPreviewURL.article.rawValue)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let message = conversation?.lastMessage as! ZMClientMessage
        assertMessageContainsLinkPreview(message, linkPreviewURL: .article)
    }

    func testThatItInsertCorrectLinkPreviewMessage_ArticleWithoutImage_ForEphemeral() {
        // given
        XCTAssertTrue(login())
        let conversation = self.conversation(for: selfToUser1Conversation)
        conversation?.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)

        // when
        userSession?.perform {
            try! conversation?.appendText(content: MockLinkPreviewDetector.LinkPreviewURL.article.rawValue)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let message = conversation?.lastMessage as! ZMClientMessage
        assertMessageContainsLinkPreview(message, linkPreviewURL: .article)
    }

    func testThatItInsertsCorrectLinkPreviewMessage_ArticleWithImage() {
        // given
        XCTAssertTrue(login())
        let conversation = self.conversation(for: selfToUser1Conversation)

        // when
        userSession?.perform {
            try! conversation?.appendText(content: MockLinkPreviewDetector.LinkPreviewURL.articleWithPicture.rawValue)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let message = conversation?.lastMessage as! ZMClientMessage
        assertMessageContainsLinkPreview(message, linkPreviewURL: .articleWithPicture)
    }

    func testThatItInsertsCorrectLinkPreviewMessage_TwitterStatus() {
        // given
        XCTAssertTrue(login())
        let conversation = self.conversation(for: selfToUser1Conversation)

        // when
        userSession?.perform {
            try! conversation?.appendText(content: MockLinkPreviewDetector.LinkPreviewURL.tweet.rawValue)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let message = conversation?.lastMessage as! ZMClientMessage
        assertMessageContainsLinkPreview(message, linkPreviewURL: .tweet)
    }

    func testThatItInsertsCorrectLinkPreviewMessage_TwitterStatusWithImage() {
        // given
        XCTAssertTrue(login())
        let conversation = self.conversation(for: selfToUser1Conversation)

        // when
        userSession?.perform {
            try! conversation?.appendText(content: MockLinkPreviewDetector.LinkPreviewURL.tweetWithPicture.rawValue)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let message = conversation?.lastMessage as! ZMClientMessage
        assertMessageContainsLinkPreview(message, linkPreviewURL: .tweetWithPicture)
    }

    func testThatItUpdatesMessageWhenReceivingLinkPreviewUpdate() {
        // given
        XCTAssertTrue(login())

        let mockConversation = selfToUser1Conversation!
        let conversation = self.conversation(for: mockConversation)

        establishSession(with: user1)
        let selfClient = selfUser.clients.anyObject() as! MockUserClient
        let senderClient = user1.clients.anyObject() as! MockUserClient

        let nonce = UUID.create()
        let messageText = MockLinkPreviewDetector.LinkPreviewURL.article.rawValue
        let messageWithoutLinkPreview = GenericMessage(content: Text(content: messageText), nonce: nonce)

        // when - receiving initial message without the link preview
        mockTransportSession.performRemoteChanges { _ in
            do {
                mockConversation.encryptAndInsertData(from: senderClient, to: selfClient, data: try messageWithoutLinkPreview.serializedData())
            } catch {
                XCTFail()
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let linkMetaData = mockLinkPreviewDetector.linkMetaData(.article)
        let messageWithLinkPreview = GenericMessage(content: Text(content: messageText, linkPreviews: [linkMetaData]), nonce: nonce)

        // when - receiving update message with the link preview
        mockTransportSession.performRemoteChanges { _ in
            do {
                mockConversation.encryptAndInsertData(from: senderClient, to: selfClient, data: try messageWithLinkPreview.serializedData())
            } catch {
                XCTFail()
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let message = conversation?.lastMessage as! ZMClientMessage
        assertMessageContainsLinkPreview(message, linkPreviewURL: .article)
    }

}
