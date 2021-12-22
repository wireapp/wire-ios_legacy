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
import XCTest

// MARK: - Mentions

final class TextMessageMentionsTests: XCTestCase {
    var otherUser: MockUserType!
    var selfUser: MockUserType!

    /// "Saturday, February 14, 2009 at 12:20:30 AM Central European Standard Time"
    static let dummyServerTimestamp = Date(timeIntervalSince1970: 1234567230)

    override func setUp() {
        super.setUp()

        otherUser = MockUserType.createUser(name: "Bruno")
        selfUser = MockUserType.createDefaultSelfUser()

        UIColor.setAccentOverride(.vividRed)
    }

    override func tearDown() {
        otherUser = nil
        selfUser = nil

        resetColorScheme()
        super.tearDown()
    }

    private func createMessage(messageText: String, mentions: [Mention]) -> MockMessage {
        let message = MockMessageFactory.messageTemplate(sender: selfUser)
        let textMessageData = MockTextMessageData()
        textMessageData.messageText = messageText
        message.backingTextMessageData = textMessageData

        textMessageData.mentions = mentions

        return message
    }

    func testThatItRendersMentions_OnlyMention() {
        let messageText = "@Bruno"
        let mention = Mention(range: NSRange(location: 0, length: 6), user: otherUser)

        verify(message: createMessage(messageText: messageText, mentions: [mention]),
               allColorSchemes: true)
    }

    func testThatItRendersMentions() {
        let messageText = "Hello @Bruno! I had some questions about your program. I think I found the bug 🐛."
        let mention = Mention(range: NSRange(location: 6, length: 6), user: otherUser)

        verify(message: createMessage(messageText: messageText, mentions: [mention]))
    }

    func testThatItRendersMentions_DifferentLength() {
        let messageText = "Hello @Br @Br @Br"
        let mention1 = Mention(range: NSRange(location: 6, length: 3), user: otherUser)
        let mention2 = Mention(range: NSRange(location: 10, length: 3), user: otherUser)
        let mention3 = Mention(range: NSRange(location: 14, length: 3), user: otherUser)

        verify(message: createMessage(messageText: messageText, mentions: [mention1, mention2, mention3]))
    }

    func testThatItRendersMentions_SelfMention() {
        let messageText = "Hello @Me! I had some questions about my program. I think I found the bug 🐛."
        let mention = Mention(range: NSRange(location: 6, length: 3), user: selfUser)

        verify(message: createMessage(messageText: messageText, mentions: [mention]))
    }

    func testThatItRendersMentionWithEmoji_MultipleMention() {
        let messageText = "Hello @Bill 👨‍👩‍👧‍👦 & @🏴󠁧󠁢󠁷󠁬󠁳󠁿🀄︎🧘🏿‍♀️其他人! I had some questions about your program. I think I found the bug 🐛."
        let mention1 = Mention(range: NSRange(location: 6, length: 17), user: selfUser)
        let mention2 = Mention(range: NSRange(location: 26, length: 28), user: otherUser)

        /// The emoji 🀄︎ may be rendered on its corner on differnt versions of iOS, set tolerance to 0.01
        verify(message: createMessage(messageText: messageText, mentions: [mention1, mention2]))
    }

    func testThatItRendersMentions_SelfMention_LongText() {
        // swiftlint:disable line_length
        let messageText =
        """
        She was a liar. She had no diseases at all. I had seen her at Free and Clear, my blood parasites group Thursdays. Then at Hope, my bimonthly sickle cell circle. And again at Seize the Day, my tuberculosis Friday night. @Marla, the big tourist. Her lie reflected my lie, and suddenly, I felt nothing.
        """
        // swiftlint:enable line_length

        selfUser.name = "Tyler Durden"
        selfUser.initials = "TD"
        let mention = Mention(range: NSRange(location: 219, length: 6), user: selfUser)
        verify(message: createMessage(messageText: messageText, mentions: [mention]), waitForTextViewToLoad: true)
    }

    func testThatItRendersMentions_SelfMention_LongText_Dark() {
        setColorScheme(.dark)

        // swiftlint:disable line_length
        let messageText =
        """
        She was a liar. She had no diseases at all. I had seen her at Free and Clear, my blood parasites group Thursdays. Then at Hope, my bimonthly sickle cell circle. And again at Seize the Day, my tuberculosis Friday night. @Marla, the big tourist. Her lie reflected my lie, and suddenly, I felt nothing.
        """
        // swiftlint:enable line_length

        selfUser.name = "Tyler Durden"
        selfUser.initials = "TD"
        let mention = Mention(range: NSRange(location: 219, length: 6), user: selfUser)
        verify(message: createMessage(messageText: messageText,
                                      mentions: [mention]),
                                      waitForTextViewToLoad: true,
                                      snapshotBackgroundColor: .black)
    }

    func testThatItRendersMentions_InMarkdown() {
        let messageText = "# Hello @Bruno"
        let mention = Mention(range: NSRange(location: 8, length: 6), user: otherUser)
        verify(message: createMessage(messageText: messageText, mentions: [mention]))
    }

    func testThatItRendersMentions_MarkdownInMention_Code() {
        let messageText = "# Hello @`Bruno`"
        let mention = Mention(range: NSRange(location: 8, length: 8), user: otherUser)
        verify(message: createMessage(messageText: messageText, mentions: [mention]))
    }

    func testThatItRendersMentions_MarkdownInMention_Link() {
        let messageText = "# Hello @[Bruno](http://google.com)"
        let mention = Mention(range: NSRange(location: 8, length: 27), user: otherUser)
        verify(message: createMessage(messageText: messageText, mentions: [mention]))
    }

    func testThatItRendersMentions_MarkdownInUserName() {
        otherUser.name = "[Hello](http://google.com)"
        let messageText = "# Hello @Bruno"
        let mention = Mention(range: NSRange(location: 8, length: 6), user: otherUser)
        verify(message: createMessage(messageText: messageText, mentions: [mention]))
    }

    func testDarkModeSelf() {
        setColorScheme(.dark)

        let messageText = "@current"
        let mention = Mention(range: NSRange(location: 0, length: 8), user: selfUser)
        verify(message: createMessage(messageText: messageText, mentions: [mention]))
    }
}
