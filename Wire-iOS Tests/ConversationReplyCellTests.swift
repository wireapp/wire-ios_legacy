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

class ConversationReplyCellTests: CoreDataSnapshotTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        defaultImageCache.cache.removeAllObjects()
    }

    // MARK: - Basic Layout

    func testThatItRendersShortMessage_30() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Message contents")!
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItRendersShortMessageWithOtherMention_31() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "@Bruno is the annual report ready to go?")!
        message.backingTextMessageData?.mentions = [Mention(range: NSRange(location: 0, length: 6), user: otherUser)]
        message.sender = selfUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItRendersShortMessageWithSelfMention_31() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "@selfUser is the annual report ready to go?")!
        message.backingTextMessageData?.mentions = [Mention(range: NSRange(location: 0, length: 9), user: selfUser)]
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItTruncatesTextAfterFourLines_31() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "@Bruno do we have the latest mockup files ready to go for the annual report? Once we have the copy finalized I would like to drop it in and get this out as quickly as possible. We can also add more lines to the test message if we need.")!
        message.backingTextMessageData?.mentions = [Mention(range: NSRange(location: 0, length: 6), user: otherUser)]
        message.sender = selfUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItRendersMarkdownWithoutFontChanges_32() {
        // GIVEN
        let markdownWithTitle = """
        # Summary of Today’s Meeting Upcoming due dates:
        - Jan 4, final copy in review
        - Jan 15, final layout with copy
        - Jan 20, release on website
        """

        let message = MockMessageFactory.textMessage(withText: markdownWithTitle)!
        message.sender = selfUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItRendersMarkdownWithoutFontChanges_NoHeaders_32() {
        // GIVEN
        let markdownNoHeaders = """
        1. Annual report status: We need to get the final copy finished before we can finalize a layout.
        2. Board meeting: Steph will begin brainstorming for the next project.
        """

        let message = MockMessageFactory.textMessage(withText: markdownNoHeaders)!
        message.sender = selfUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }


    func testThatItRendersEmojiInLargeFont_33() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "🌮🌮🌮")!
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItShowsEditBadgeWhenMessageIsEdited_34() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "@Bruno is the annual report ready to go?")!
        message.backingTextMessageData?.mentions = [Mention(range: NSRange(location: 0, length: 6), user: otherUser)]
        message.sender = selfUser
        message.conversation = otherUserConversation
        message.updatedAt = Date()

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    // MARK: - Rich content

    func testThatItDisplaysLinkPreviewAsText_51() {
        // GIVEN
        let url = "https://apple.com/de/apple-pay"
        let message = MockMessageFactory.textMessage(withText: "")!
        message.backingTextMessageData?.linkPreview = LinkPreview(originalURLString: url, permanentURLString: url, resolvedURLString: url, offset: 0)
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItDisplaysLinkPreviewAsText_WithText_51() {
        // GIVEN
        let url = "https://apple.com/de/apple-pay"
        let message = MockMessageFactory.textMessage(withText: "There you go!  ")!
        message.backingTextMessageData?.linkPreview = LinkPreview(originalURLString: url, permanentURLString: url, resolvedURLString: url, offset: 13)
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItDisplaysPortraitImage_52() {
        // GIVEN
        let image = self.image(inTestBundleNamed: "unsplash_vertical_pano.jpg")
        let message = MockMessageFactory.imageMessage(with: image)!
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItDisplaysSquareImage_52() {
        // GIVEN
        let image = self.image(inTestBundleNamed: "unsplash_square.jpg")
        let message = MockMessageFactory.imageMessage(with: image)!
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItDisplaysPanoImage_52() {
        // GIVEN
        let image = self.image(inTestBundleNamed: "unsplash_pano.jpg")
        let message = MockMessageFactory.imageMessage(with: image)!
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItDisplaysVideoMessage_53() {
        // GIVEN
        let image = self.image(inTestBundleNamed: "unsplash_square.jpg")
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData!.filename = "Video.mp4"
        message.backingFileMessageData!.mimeType = "video/mp4"
        message.backingFileMessageData!.previewData = image.jpegData(compressionQuality: 1)
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItDisplaysFileMessage_54() {
        // GIVEN
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData!.filename = "Annual Report.pdf"
        message.backingFileMessageData!.mimeType = "application/pdf"
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItDisplaysAudioMessage_55() {
        // GIVEN
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData!.filename = "ImportantMessage.m4a"
        message.backingFileMessageData!.mimeType = "audio/x-m4a"
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItDisplaysLocationMessage_56() {
        // GIVEN
        let message = MockMessageFactory.locationMessage()!
        message.backingLocationMessageData.name = "Rosenthaler Str. 40-41, 10178 Berlin"
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItDoesNotTruncateLongLocationMessage_56() {
        // GIVEN
        let message = MockMessageFactory.locationMessage()!
        message.backingLocationMessageData.name = "Hackesher Markt, Rosenthaler Str. 40-41, 10178 Berlin, Germany"
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItDisplaysErrorForUnsupportedMessageType_57() {
        // GIVEN
        let message = MockMessageFactory.pingMessage()!
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    func testThatItDisplaysErrorForDeletedMessage_57() {
        // GIVEN
        let message: ZMConversationMessage? = nil

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    // MARK: - Highlighting

    func testThatItHighlightsCellOnTouchInside_60() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Message contents")!
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)
        cell.contentView.touchesBegan([], with: nil)

        // THEN
        verifyInAllPhoneWidths(view: cell)
    }

    // MARK: - Helpers

    private func makeCell(for message: ZMConversationMessage?) -> ConversationReplyCell {
        let cellDescription = ConversationReplyCellDescription(quotedMessage: message)
        let cell = ConversationReplyCell()
        cell.configure(with: cellDescription.configuration)
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        return cell
    }

}
