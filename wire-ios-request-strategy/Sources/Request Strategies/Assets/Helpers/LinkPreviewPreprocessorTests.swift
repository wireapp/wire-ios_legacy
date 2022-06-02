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

import XCTest
import WireLinkPreview
import WireDataModel
import WireImages

@testable import WireRequestStrategy

final class MockLinkDetector: LinkPreviewDetectorType {

    var nextResult = [LinkMetadata]()
    var downloadLinkPreviewsCallCount: Int = 0
    var excludedRanges: [NSRange] = []

    func downloadLinkPreviews(inText text: String, excluding: [NSRange], completion: @escaping ([LinkMetadata]) -> Void) {
        downloadLinkPreviewsCallCount += 1
        excludedRanges = excluding
        completion(nextResult)
    }

}

class LinkPreviewPreprocessorTests: MessagingTestBase {

    var sut: LinkPreviewPreprocessor!
    var mockDetector: MockLinkDetector!

    override func setUp() {
        super.setUp()
        mockDetector = MockLinkDetector()
        sut = LinkPreviewPreprocessor(linkPreviewDetector: mockDetector, managedObjectContext: syncMOC)
    }

    override func tearDown() {
        mockDetector = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper

    func createMessage(text: String = "text message 123", mentions: [Mention] = [], state: ZMLinkPreviewState = .waitingToBeProcessed, isEphemeral: Bool = false) -> ZMClientMessage {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        if isEphemeral {
            conversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
        }
        let message = try! conversation.appendText(content: text, mentions: mentions) as! ZMClientMessage
        message.linkPreviewState = state
        return message
    }

    func assertThatItProcessesMessageWithLinkPreviewState(_ state: ZMLinkPreviewState, shouldProcess: Bool = false, line: UInt = #line) {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let message = self.createMessage(state: state)

            // WHEN
            self.sut.objectsDidChange([message])
        }

        self.syncMOC.performGroupedBlockAndWait {
            // THEN
            let callCount: Int = shouldProcess ? 1 : 0
            XCTAssertEqual(self.mockDetector.downloadLinkPreviewsCallCount, callCount, "Failure processing state \(state.rawValue)", line: line)
        }
    }
}

extension LinkPreviewPreprocessorTests {

    func testThatItOnlyProcessesMessagesWithLinkPreviewState_WaitingToBeProcessed() {
        [ZMLinkPreviewState.done, .downloaded, .processed, .uploaded, .waitingToBeProcessed].forEach {
            assertThatItProcessesMessageWithLinkPreviewState($0, shouldProcess: $0 == .waitingToBeProcessed)
        }
    }

    func testThatItStoresTheOriginalImageDataInTheCacheAndSetsTheStateToDownloadedWhenItReceivesAPreviewWithImage() {
        var message: ZMClientMessage!
        var preview: LinkMetadata!
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let URL = "http://www.example.com"
            preview = LinkMetadata(originalURLString: "example.com", permanentURLString: URL, resolvedURLString: URL, offset: 0)
            preview.imageData = [.secureRandomData(length: 256)]
            preview.imageURLs = [Foundation.URL(string: "http://www.example.com/image")!]
            self.mockDetector.nextResult = [preview]
            message = self.createMessage()

            // WHEN
            self.sut.objectsDidChange([message])
        }

        self.syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertEqual(self.mockDetector.downloadLinkPreviewsCallCount, 1)
            XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewState.downloaded)
            let data = self.syncMOC.zm_fileAssetCache.assetData(message, format: .original, encrypted: false)
            XCTAssertEqual(data, preview.imageData.first!)
            guard let genericMessage = message.underlyingMessage else { return XCTFail("No generic message") }
            XCTAssertFalse(genericMessage.text.linkPreview.isEmpty)
        }
    }

    func testThatItSetsTheStateToUploadedWhenItReceivesAPreviewWithoutImage() {
        var message: ZMClientMessage!

        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let URL = "http://www.example.com"
            self.mockDetector.nextResult = [LinkMetadata(originalURLString: "example.com", permanentURLString: URL, resolvedURLString: URL, offset: 0)]
            message = self.createMessage()

            // WHEN
            self.sut.objectsDidChange([message])
        }

        self.syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertEqual(self.mockDetector.downloadLinkPreviewsCallCount, 1)
            XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewState.uploaded)
            let data = self.syncMOC.zm_fileAssetCache.assetData(message, format: .original, encrypted: false)
            XCTAssertNil(data)
            guard let genericMessage = message.underlyingMessage else { return XCTFail("No generic message") }
            XCTAssertFalse(genericMessage.text.linkPreview.isEmpty)
        }
    }

    func testThatItSetsTheStateToDoneIfNoPreviewsAreReturned() {
        var message: ZMClientMessage!
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            message = self.createMessage()

            // WHEN
            self.sut.objectsDidChange([message])
        }

        self.syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertEqual(self.mockDetector.downloadLinkPreviewsCallCount, 1)
            XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewState.done)
        }
    }

    func testThatItSetsTheStateToDoneIfTheMessageDoesNotHaveTextMessageData() {
        var message: ZMClientMessage!

        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()

            do {
                message = try conversation.appendKnock() as? ZMClientMessage
            } catch {
                XCTFail("Failed to append knock message")
            }

            // WHEN
            self.sut.objectsDidChange([message])
        }

        self.syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewState.done)
        }
    }

    func testThatItShouldExcludeMentionsFromLinkPreviewGeneration() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let text = "@john - www.sunet.se hello"
            let message = self.createMessage(text: text, mentions: [Mention(range: NSRange(location: 0, length: 20), user: self.otherUser)])

            // WHEN
            self.sut.processMessage(message)

            // THEN
            XCTAssertEqual(self.mockDetector.excludedRanges, [NSRange(location: 0, length: 20)])
        }
    }

    func testThatItShouldExcludeMarkdownLinksFromLinkPreviewGeneration() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let text = "[click me!](www.example.com) hello"
            let message = self.createMessage(text: text)

            // WHEN
            self.sut.processMessage(message)

            // THEN
            XCTAssertEqual(self.mockDetector.excludedRanges, [NSRange(location: 0, length: 28)])
        }
    }

    func testThatItShouldNotExcludeNonMarkdownLinksFromLinkPreviewGeneration() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let text = "click this: www.example.com"
            let message = self.createMessage(text: text)

            // WHEN
            self.sut.processMessage(message)

            // THEN
            XCTAssertTrue(self.mockDetector.excludedRanges.isEmpty)
        }
    }
}

// MARK: - Ephemeral
extension LinkPreviewPreprocessorTests {

    func testThatItReturnsAnEphemeralMessageAfterPreProcessingAnEphemeral() {
        var message: ZMClientMessage!
        var preview: LinkMetadata!
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let URL = "http://www.example.com"
            preview = LinkMetadata(originalURLString: "example.com", permanentURLString: URL, resolvedURLString: URL, offset: 0)
            preview.imageData = [.secureRandomData(length: 256)]
            preview.imageURLs = [Foundation.URL(string: "http://www.example.com/image")!]
            self.mockDetector.nextResult = [preview]
            message = self.createMessage(isEphemeral: true)
            XCTAssertTrue(message.isEphemeral)

            // WHEN
            self.sut.objectsDidChange([message])
        }

        self.syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertEqual(self.mockDetector.downloadLinkPreviewsCallCount, 1)
            XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewState.downloaded)
            let data = self.syncMOC.zm_fileAssetCache.assetData(message, format: .original, encrypted: false)
            XCTAssertEqual(data, preview.imageData.first!)
            guard let genericMessage = message.underlyingMessage else { return XCTFail("No generic message") }
            guard case .ephemeral? = genericMessage.content else {
                return XCTFail("No ephemeral content found")
            }
            XCTAssertFalse(genericMessage.ephemeral.text.linkPreview.isEmpty)
        }
    }

    func testThatItDoesNotUpdateMessageWhenMessageHasBeenObfuscatedAndSetsPreviewStateToDone() {
        var message: ZMClientMessage!
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let URL = "http://www.example.com"
            let preview = LinkMetadata(originalURLString: "example.com", permanentURLString: URL, resolvedURLString: URL, offset: 0)
            preview.imageData = [.secureRandomData(length: 256)]
            preview.imageURLs = [Foundation.URL(string: "http://www.example.com/image")!]
            self.mockDetector.nextResult = [preview]
            message = self.createMessage(isEphemeral: true)
            XCTAssertTrue(message.isEphemeral)
            message.obfuscate()

            // WHEN
            self.sut.objectsDidChange([message])
        }

        self.syncMOC.performGroupedBlockAndWait {
            // THEN
            guard let genericMessage = message.underlyingMessage else { return XCTFail("No generic message") }
            if case .ephemeral? = genericMessage.content {
                return XCTFail("No ephemeral content found")
            }
            XCTAssertEqual(genericMessage.linkPreviews.count, 0)
            XCTAssertEqual(message.linkPreviewState, .done)
        }
    }

}
