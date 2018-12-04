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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
    }

    func testThatItRendersTextMoreThan4Lines() {
        // GIVEN
        let markdownWithTitle = """
        In den alten Zeiten,
        wo das Wünschen noch geholfen hat,
        lebte ein König, dessen Töchter waren alle schön;
        aber die jüngste war so schön, daß die Sonne selber,
        die doch so vieles gesehen hat,
        """

        let message = MockMessageFactory.textMessage(withText: markdownWithTitle)!
        message.sender = selfUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
        verifyAccessibilityIdentifiers(cell, message)
    }

    func testThatItRendersMarkdownWithMoreThan4Lines() {
        // GIVEN
        let markdownWithTitle = """
        # Summary of Today’s Meeting Upcoming due dates:
        - Jan 4, final copy in review
        - Jan 15, final layout with copy
        - Jan 20, release on website
        - Jan 31, review
        """

        let message = MockMessageFactory.textMessage(withText: markdownWithTitle)!
        message.sender = selfUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
        verifyAccessibilityIdentifiers(cell, message)
    }

    func testThatItRendersMarkdownWithLastLineClipped() {
        // GIVEN
        let markdownWithTitle = """
        # Summary of Today’s Meeting Upcoming due dates:
        - Jan 4, final copy in review
        - Jan 15, final layout with copy
        - Jan 20, release on website for internal testers and QA teams
        - Jan 31, review
        """

        let message = MockMessageFactory.textMessage(withText: markdownWithTitle)!
        message.sender = selfUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
        verifyAccessibilityIdentifiers(cell, message)
    }

    func testThatItRendersMarkdownWith5LinesAndForthLineClipped() {
        // GIVEN
        let markdownWithTitle = """
        # Summary of Today’s Meeting Upcoming due dates:
        - Jan 4, final copy in review
        - Jan 15, final layout with copy
        - Jan 20, release on website for internal testers and QA teams
        - Jan 31, review
        """

        let message = MockMessageFactory.textMessage(withText: markdownWithTitle)!
        message.sender = selfUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
    }

    func testThatItRendersMarkdownListMoreThan4Line() {
        // GIVEN
        let markdownNoHeaders = """
        1. In den alten Zeiten, wo das Wünschen noch geholfen hat, lebte ein König, dessen Töchter waren alle schön;
        2. aber die jüngste war so schön, daß die Sonne selber, die doch so vieles gesehen hat, sich verwunderte, sooft sie ihr ins Gesicht schien.
        3. Nahe bei dem Schlosse des Königs lag ein großer dunkler Wald, und in dem Walde unter einer alten Linde war ein Brunnen;
        4. wenn nun der Tag recht heiß war, so ging das Königskind hinaus in den Wald und setzte sich an den Rand des kühlen Brunnens - und wenn sie Langeweile hatte, so nahm sie eine goldene Kugel, warf sie in die Höhe und fing sie wieder; und das war ihr liebstes Spielwerk.
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
    }

    // MARK: - Rich content

    func testThatItDisplaysLinkPreviewAsText_51() {
        // GIVEN
        let url = "https://apple.com/de/apple-pay"
        let message = MockMessageFactory.textMessage(withText: "https://apple.com/de/apple-pay")!
        message.backingTextMessageData?.linkPreview = LinkMetadata(originalURLString: url, permanentURLString: url, resolvedURLString: url, offset: 0)
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
        verifyAccessibilityIdentifiers(cell, message)
    }

    func testThatItDisplaysLinkPreviewAsText_WithText_51() {
        // GIVEN
        let url = "https://apple.com/de/apple-pay"
        let message = MockMessageFactory.textMessage(withText: "There you go! https://apple.com/de/apple-pay")!
        message.backingTextMessageData?.linkPreview = LinkMetadata(originalURLString: url, permanentURLString: url, resolvedURLString: url, offset: 14)
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
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
        verifyAccessibilityIdentifiers(cell, message)
    }

    func testThatItDisplaysErrorForDeletedMessage_57() {
        // GIVEN
        let message: ZMConversationMessage? = nil

        // WHEN
        let cell = makeCell(for: message)

        // THEN
        verifyInAllPhoneWidths(view: cell)
        verifyAccessibilityIdentifiers(cell, message)
    }

    // MARK: - Highlighting

    func testThatItHighlightsCellOnTouchInside_60() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Message contents")!
        message.sender = otherUser
        message.conversation = otherUserConversation

        // WHEN
        let cell = makeCell(for: message)
        cell.container.touchesBegan([], with: nil)

        // THEN
        verifyInAllPhoneWidths(view: cell)
        verifyAccessibilityIdentifiers(cell, message)
    }

    // MARK: - Helpers

    private func makeCell(for message: ZMConversationMessage?) -> ConversationReplyCell {
        let cellDescription = ConversationReplyCellDescription(quotedMessage: message)
        let cell = ConversationReplyCell()
        cell.configure(with: cellDescription.configuration, animated: false)
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        return cell
    }

    private func verifyAccessibilityIdentifiers(_ cell: ConversationReplyCell, _ message: ZMConversationMessage?, file: StaticString = #file, line: UInt = #line) {
        let contentView = cell.contentView

        // Structure
        XCTAssertEqual(contentView.senderComponent.label.accessibilityIdentifier, "original.sender", file: file, line: line)
        XCTAssertEqual(contentView.senderComponent.indicatorView.accessibilityIdentifier, "original.edit_icon", file: file, line: line)
        XCTAssertEqual(contentView.timestampLabel.accessibilityIdentifier, "original.timestamp", file: file, line: line)

        // Content
        switch message {
        case let message? where message.isText:
            XCTAssertEqual(contentView.contentTextView.accessibilityIdentifier, "quote.type.text", file: file, line: line)
            XCTAssertNil(contentView.assetThumbnail.accessibilityIdentifier, file: file, line: line)

        case let message? where message.isLocation:
            XCTAssertEqual(contentView.contentTextView.accessibilityIdentifier, "quote.type.location", file: file, line: line)
            XCTAssertNil(contentView.assetThumbnail.accessibilityIdentifier, file: file, line: line)

        case let message? where message.isAudio:
            XCTAssertEqual(contentView.contentTextView.accessibilityIdentifier, "quote.type.audio", file: file, line: line)
            XCTAssertNil(contentView.assetThumbnail.accessibilityIdentifier, file: file, line: line)

        case let message? where message.isImage:
            XCTAssertEqual(contentView.assetThumbnail.accessibilityIdentifier, "quote.type.image", file: file, line: line)
            XCTAssertNil(contentView.contentTextView.accessibilityIdentifier, file: file, line: line)

        case let message? where message.isVideo:
            XCTAssertEqual(contentView.assetThumbnail.accessibilityIdentifier, "quote.type.video", file: file, line: line)
            XCTAssertNil(contentView.contentTextView.accessibilityIdentifier, file: file, line: line)

        case let message? where message.isFile:
            XCTAssertEqual(contentView.contentTextView.accessibilityIdentifier, "quote.type.file", file: file, line: line)
            XCTAssertNil(contentView.assetThumbnail.accessibilityIdentifier, file: file, line: line)

        default:
            XCTAssertEqual(contentView.contentTextView.accessibilityIdentifier, "quote.type.unavailable", file: file, line: line)
            XCTAssertNil(contentView.assetThumbnail.accessibilityIdentifier, file: file, line: line)
        }
    }

}
