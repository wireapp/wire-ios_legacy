//
//  TextMessageMentionsTests.swift
//  Wire-iOS-Tests
//
//  Created by Mihail Gerasimenko on 9/13/18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
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
        snapshotBackgroundColor = UIColor(scheme: .contentBackground)
        accentColor = .strongBlue
        sut = TextMessageCell(style: .default, reuseIdentifier: name)
        sut.layer.speed = 0
        
        resetDayFormatter()
        
        [Message.shortVersionDateFormatter(), Message.longVersionTimeFormatter()].forEach {
            $0.locale = Locale(identifier: "en_US")
            $0.timeZone = TimeZone(abbreviation: "CET")
        }
    }
    
    override func tearDown() {
        resetDayFormatter()
        sut = nil
        super.tearDown()
    }
    
    func testThatItRendersMentions_OnlyMention() {
        let messageText = "@Bruno"
        let mention = Mention(range: NSRange(location: 0, length: 6), user: otherUser)
        let message = otherUserConversation.appendMessage(withText: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions() {
        let messageText = "Hello @Bruno! I had some questions about your program. I think I found the bug 🐛."
        let mention = Mention(range: NSRange(location: 6, length: 6), user: otherUser)
        let message = otherUserConversation.appendMessage(withText: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_DifferentLength() {
        let messageText = "Hello @Br @Br @Br"
        let mention1 = Mention(range: NSRange(location: 6, length: 3), user: otherUser)
        let mention2 = Mention(range: NSRange(location: 10, length: 3), user: otherUser)
        let mention3 = Mention(range: NSRange(location: 14, length: 3), user: otherUser)
        
        let message = otherUserConversation.appendMessage(withText: messageText, mentions: [mention1, mention2, mention3],
                                                          fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_SelfMention() {
        let messageText = "Hello @Me! I had some questions about my program. I think I found the bug 🐛."
        let mention = Mention(range: NSRange(location: 6, length: 3), user: selfUser)
        let message = otherUserConversation.appendMessage(withText: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_SelfMention_LongText() {
        let messageText =
"""
She was a liar. She had no diseases at all. I had seen her at Free and Clear, my blood parasites group Thursdays. Then at Hope, my bimonthly sickle cell circle. And again at Seize the Day, my tuberculosis Friday night. @Marla, the big tourist. Her lie reflected my lie, and suddenly, I felt nothing.
"""
        selfUser.name = "Tyler Durden"
        let mention = Mention(range: NSRange(location: 219, length: 6), user: selfUser)
        let message = otherUserConversation.appendMessage(withText: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_InMarkdown() {
        let messageText = "# Hello @Bruno"
        let mention = Mention(range: NSRange(location: 8, length: 6), user: otherUser)
        let message = otherUserConversation.appendMessage(withText: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_MarkdownInMention_Code() {
        let messageText = "# Hello @`Bruno`"
        let mention = Mention(range: NSRange(location: 8, length: 8), user: otherUser)
        let message = otherUserConversation.appendMessage(withText: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_MarkdownInMention_Link() {
        let messageText = "# Hello @[Bruno](http://google.com)"
        let mention = Mention(range: NSRange(location: 8, length: 27), user: otherUser)
        let message = otherUserConversation.appendMessage(withText: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersMentions_MarkdownInUserName() {
        otherUser.name = "[Hello](http://google.com)"
        let messageText = "# Hello @Bruno"
        let mention = Mention(range: NSRange(location: 8, length: 6), user: otherUser)
        let message = otherUserConversation.appendMessage(withText: messageText, mentions: [mention], fetchLinkPreview: false)
        
        sut.configure(for: message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
}

