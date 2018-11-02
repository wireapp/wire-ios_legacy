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

@testable import Wire
import WireDataModel


// MARK: - Mentions

final class TextMessageMentionsTests: ConversationCellSnapshotTests {

//    /// "Saturday, February 14, 2009 at 12:20:30 AM Central European Standard Time"
//    static let dummyServerTimestamp = Date(timeIntervalSince1970: 1234567230)
//
//    override func setUp() {
//        super.setUp()
//        recordMode = true
//        NSAttributedString.invalidateParagraphStyle()
//        snapshotBackgroundColor = UIColor(scheme: .contentBackground)
//        accentColor = .strongBlue
//
//        resetDayFormatter()
//
//        [Message.shortVersionDateFormatter(), Message.longVersionTimeFormatter()].forEach {
//            $0.locale = Locale(identifier: "en_US")
//            $0.timeZone = TimeZone(abbreviation: "CET")
//        }
//    }
//
//    override func tearDown() {
//        resetDayFormatter()
//        ColorScheme.default.variant = .light
//        super.tearDown()
//    }
//
//    func verify(for message: ZMConversationMessage?) {
//        let context = ConversationMessageContext(isSameSenderAsPrevious: true, isLastMessageSentBySelfUser: true, isTimeIntervalSinceLastMessageSignificant: false, isFirstMessageOfTheDay: false, isFirstUnreadMessage: false)
//        ConversationMessageSectionBuilder.configure(section: section, for: message!, context: context, layoutProperties: ConversationCellLayoutProperties())
//        verifySectionSnapshots()
//    }
//
//    func testThatItRendersMentions_OnlyMention() {
//        let messageText = "@Bruno"
//        let mention = Mention(range: NSRange(location: 0, length: 6), user: otherUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//    func testThatItRendersMentions() {
//        let messageText = "Hello @Bruno! I had some questions about your program. I think I found the bug 🐛."
//        let mention = Mention(range: NSRange(location: 6, length: 6), user: otherUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//    func testThatItRendersMentions_DifferentLength() {
//        let messageText = "Hello @Br @Br @Br"
//        let mention1 = Mention(range: NSRange(location: 6, length: 3), user: otherUser)
//        let mention2 = Mention(range: NSRange(location: 10, length: 3), user: otherUser)
//        let mention3 = Mention(range: NSRange(location: 14, length: 3), user: otherUser)
//
//        let message = otherUserConversation.append(text: messageText, mentions: [mention1, mention2, mention3],
//                                                          fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//    func testThatItRendersMentions_SelfMention() {
//        let messageText = "Hello @Me! I had some questions about my program. I think I found the bug 🐛."
//        let mention = Mention(range: NSRange(location: 6, length: 3), user: selfUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//    func testThatItRendersMentionWithEmoji_MultipleMention() {
//        let messageText = "Hello @Bill 👨‍👩‍👧‍👦 & @🏴󠁧󠁢󠁷󠁬󠁳󠁿🀄︎🧘🏿‍♀️其他人! I had some questions about your program. I think I found the bug 🐛."
//        let mention1 = Mention(range: NSRange(location: 6, length: 17), user: selfUser)
//        let mention2 = Mention(range: NSRange(location: 26, length: 28), user: otherUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention1, mention2], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//
//    func testThatItRendersMentions_SelfMention_LongText() {
//        let messageText =
//"""
//She was a liar. She had no diseases at all. I had seen her at Free and Clear, my blood parasites group Thursdays. Then at Hope, my bimonthly sickle cell circle. And again at Seize the Day, my tuberculosis Friday night. @Marla, the big tourist. Her lie reflected my lie, and suddenly, I felt nothing.
//"""
//        selfUser.name = "Tyler Durden"
//        let mention = Mention(range: NSRange(location: 219, length: 6), user: selfUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//    func testThatItRendersMentions_SelfMention_LongText_Dark() {
//        // createSUT(for: .dark)
//        let messageText =
//        """
//She was a liar. She had no diseases at all. I had seen her at Free and Clear, my blood parasites group Thursdays. Then at Hope, my bimonthly sickle cell circle. And again at Seize the Day, my tuberculosis Friday night. @Marla, the big tourist. Her lie reflected my lie, and suddenly, I felt nothing.
//"""
//        selfUser.name = "Tyler Durden"
//        let mention = Mention(range: NSRange(location: 219, length: 6), user: selfUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//    func testThatItRendersMentions_InMarkdown() {
//        let messageText = "# Hello @Bruno"
//        let mention = Mention(range: NSRange(location: 8, length: 6), user: otherUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//    func testThatItRendersMentions_MarkdownInMention_Code() {
//        let messageText = "# Hello @`Bruno`"
//        let mention = Mention(range: NSRange(location: 8, length: 8), user: otherUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//    func testThatItRendersMentions_MarkdownInMention_Link() {
//        let messageText = "# Hello @[Bruno](http://google.com)"
//        let mention = Mention(range: NSRange(location: 8, length: 27), user: otherUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//    func testThatItRendersMentions_MarkdownInUserName() {
//        otherUser.name = "[Hello](http://google.com)"
//        let messageText = "# Hello @Bruno"
//        let mention = Mention(range: NSRange(location: 8, length: 6), user: otherUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//    func testDarkMode() {
//        // createSUT(for: .dark)
//        let messageText = "@Bruno"
//        let mention = Mention(range: NSRange(location: 0, length: 6), user: otherUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
//
//    func testDarkModeSelf() {
//        // createSUT(for: .dark)
//        let messageText = "@current"
//        let mention = Mention(range: NSRange(location: 0, length: 8), user: selfUser)
//        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
//
//        verify(for: message)
//    }
}

