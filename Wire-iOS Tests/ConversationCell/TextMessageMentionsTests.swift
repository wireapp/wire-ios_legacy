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

final class TextMessageMentionsTests: CoreDataSnapshotTestCase {

    var sut: TextMessageCell!
    
    /// "Saturday, February 14, 2009 at 12:20:30 AM Central European Standard Time"
    static let dummyServerTimestamp = Date(timeIntervalSince1970: 1234567230)
    
    var layoutProperties: ConversationCellLayoutProperties {
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false
        return layoutProperties
    }
    
    override func setUp() {
        super.setUp()
        NSAttributedString.invalidateParagraphStyle()

        resetDayFormatter()
        
        [Message.shortVersionDateFormatter(), Message.longVersionTimeFormatter()].forEach {
            $0.locale = Locale(identifier: "en_US")
            $0.timeZone = TimeZone(abbreviation: "CET")
        }
    }
    
    func createSUT(for variant: ColorSchemeVariant) {
        ColorScheme.default.variant = variant
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()

        snapshotBackgroundColor = UIColor.from(scheme: .contentBackground)
        accentColor = .strongBlue
        sut = TextMessageCell(style: .default, reuseIdentifier: name)
        sut.layer.speed = 0
    }
    
    override func tearDown() {
        resetDayFormatter()
        sut = nil
        ColorScheme.default.variant = .light
        super.tearDown()
    }
    
    func testThatItRendersMentions_OnlyMention() {
        createSUT(for: .light)
        let messageText = "@Bruno"
        let mention = Mention(range: NSRange(location: 0, length: 6), user: otherUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions() {
        createSUT(for: .light)
        let messageText = "Hello @Bruno! I had some questions about your program. I think I found the bug 🐛."
        let mention = Mention(range: NSRange(location: 6, length: 6), user: otherUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_DifferentLength() {
        createSUT(for: .light)
        let messageText = "Hello @Br @Br @Br"
        let mention1 = Mention(range: NSRange(location: 6, length: 3), user: otherUser)
        let mention2 = Mention(range: NSRange(location: 10, length: 3), user: otherUser)
        let mention3 = Mention(range: NSRange(location: 14, length: 3), user: otherUser)
        
        let message = otherUserConversation.append(text: messageText, mentions: [mention1, mention2, mention3],
                                                          fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_SelfMention() {
        createSUT(for: .light)
        let messageText = "Hello @Me! I had some questions about my program. I think I found the bug 🐛."
        let mention = Mention(range: NSRange(location: 6, length: 3), user: selfUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersMentionWithEmoji_MultipleMention() {
        createSUT(for: .light)
        let messageText = "Hello @Bill 👨‍👩‍👧‍👦 & @🏴󠁧󠁢󠁷󠁬󠁳󠁿🀄︎🧘🏿‍♀️其他人! I had some questions about your program. I think I found the bug 🐛."
        let mention1 = Mention(range: NSRange(location: 6, length: 17), user: selfUser)
        let mention2 = Mention(range: NSRange(location: 26, length: 28), user: otherUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention1, mention2], fetchLinkPreview: false)

        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    
    func testThatItRendersMentions_SelfMention_LongText() {
        createSUT(for: .light)
        let messageText =
"""
She was a liar. She had no diseases at all. I had seen her at Free and Clear, my blood parasites group Thursdays. Then at Hope, my bimonthly sickle cell circle. And again at Seize the Day, my tuberculosis Friday night. @Marla, the big tourist. Her lie reflected my lie, and suddenly, I felt nothing.
"""
        selfUser.name = "Tyler Durden"
        let mention = Mention(range: NSRange(location: 219, length: 6), user: selfUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_SelfMention_LongText_Dark() {
        createSUT(for: .dark)
        let messageText =
        """
She was a liar. She had no diseases at all. I had seen her at Free and Clear, my blood parasites group Thursdays. Then at Hope, my bimonthly sickle cell circle. And again at Seize the Day, my tuberculosis Friday night. @Marla, the big tourist. Her lie reflected my lie, and suddenly, I felt nothing.
"""
        selfUser.name = "Tyler Durden"
        let mention = Mention(range: NSRange(location: 219, length: 6), user: selfUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_InMarkdown() {
        createSUT(for: .light)
        let messageText = "# Hello @Bruno"
        let mention = Mention(range: NSRange(location: 8, length: 6), user: otherUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_MarkdownInMention_Code() {
        createSUT(for: .light)
        let messageText = "# Hello @`Bruno`"
        let mention = Mention(range: NSRange(location: 8, length: 8), user: otherUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_MarkdownInMention_Link() {
        createSUT(for: .light)
        let messageText = "# Hello @[Bruno](http://google.com)"
        let mention = Mention(range: NSRange(location: 8, length: 27), user: otherUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_MarkdownInUserName() {
        createSUT(for: .light)
        otherUser.name = "[Hello](http://google.com)"
        let messageText = "# Hello @Bruno"
        let mention = Mention(range: NSRange(location: 8, length: 6), user: otherUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testDarkMode() {
        createSUT(for: .dark)
        let messageText = "@Bruno"
        let mention = Mention(range: NSRange(location: 0, length: 6), user: otherUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
        
    }
    
    func testDarkModeSelf() {
        createSUT(for: .dark)
        let messageText = "@current"
        let mention = Mention(range: NSRange(location: 0, length: 8), user: selfUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
        
    }
}

