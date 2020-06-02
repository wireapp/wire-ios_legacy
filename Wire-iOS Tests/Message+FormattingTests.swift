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
@testable import Wire

class Message_FormattingTests: XCTestCase {
    
    let previewURL = "http://www.example.com/1"
    let regularURL = "http://www.example.com/2"
    let giphyURL = "giphy.com"

    func createTextMessageData(withMessageTemplate messageTemplate: String) -> MockTextMessageData {
        var text = messageTemplate
        text = text.replacingOccurrences(of: "{preview-url}", with: previewURL)
        text = text.replacingOccurrences(of: "{regular-url}", with: regularURL)
        text = text.replacingOccurrences(of: "{giphy-preview-url}", with: giphyURL)

        let textMessageData = MockTextMessageData()
        textMessageData.messageText = text
        
        if (messageTemplate.contains("{preview-url}")) {
            let url = messageTemplate.contains("giphy") ? giphyURL : previewURL
            let range = textMessageData.messageText!.range(of: url)!
            let offset = textMessageData.messageText!.distance(from: textMessageData.messageText!.startIndex, to: range.lowerBound)
            
            textMessageData.backingLinkPreview = ArticleMetadata(originalURLString: url, permanentURLString: url, resolvedURLString: url, offset: offset)
        }
        
        return textMessageData
    }
    
    func testTextWithTrailingLinkPreviewURL() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "text text {preview-url}")
        
        // when
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "text text")
    }

    func testTextWithTrailingLinkPreviewURL_Giphy() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "text text {giphy-preview-url}")

        // when
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)

        // then
        XCTAssertEqual(formattedText.string, "text text \(giphyURL)")
    }

    func testTextWithTrailingLinkPreviewURL_GiphyAlone() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "{giphy-preview-url}")

        // when
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)

        // then
        XCTAssertEqual(formattedText.string, giphyURL)
    }
    
    func testTextWithTrailingLinkPreviewURL_Variation1() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "text text {regular-url} {preview-url}")
        
        // when
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "text text \(regularURL)")
    }
    
    func testTextWithTrailingLinkPreviewURL_Variation2() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "text text {preview-url} {regular-url}")
        
        // when
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "text text \(previewURL) \(regularURL)")
    }
    
    func testTextWithLeadingLinkPreviewURL() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "{preview-url} text text")
        
        // when
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "\(previewURL) text text")
    }
    
    func testTextWithLeadingLinkPreviewURL_Variation1() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "{preview-url} {regular-url} text text")
        
        // when
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "\(previewURL) \(regularURL) text text")
    }
    
    func testTextWithLeadingLinkPreviewURL_Variation2() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "{regular-url} {preview-url} text text")
        
        // when
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "\(regularURL) \(previewURL) text text")
    }
    
    func testTextWithOnlyLinkPreviewURL() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "{preview-url}")
        
        // when
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "")
    }
    
    func testTextWithInvalidLinkAttachment() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "hello:{preview-url}") // NSDataDetector gets confused by this text
        
        // when
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "hello:")
    }

    func testMentionLinkOverridesDetectedLink() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "{preview-url}@mention")
        
        // when
        let mockUser = SwiftMockLoader.mockUsers()[0]

        let mention = Mention(range: (textMessageData.messageText! as NSString).range(of: "@mention"), user: mockUser)
        textMessageData.mentions = [mention]
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "\(previewURL)@mention")
        XCTAssertEqual(formattedText.attributes(at: mention.range.location + 1, effectiveRange: nil)[.link] as! URL, mention.link)
    }
    
    func failing_testMentionLinkOverridesDetectedLink_mentionBefore() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "@mention{preview-url} lala")
        
        // when
        let mockUser = SwiftMockLoader.mockUsers()[0]

        let mention = Mention(range: (textMessageData.messageText! as NSString).range(of: "@mention"), user: mockUser)
        textMessageData.mentions = [mention]
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "@mention\(previewURL) lala")
        XCTAssertEqual(formattedText.attributes(at: 0, effectiveRange: nil)[.link] as! URL, mention.link)
        let linkDetected = formattedText.attributes(at: mention.range.location + mention.range.length + 1, effectiveRange: nil)[.link] as! URL
        XCTAssertEqual(linkDetected.absoluteString, previewURL)
    }
    
    func testThatItUsesCorrectUTF16OffsetForMention() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "Z͉̬͎̞̙ͅA̻̹͉̪̰͐̂ͯ̈̔L̵̝͍̒̇̄͋̂ͬG̴͈̬̝̝̙̺̀̌̎ͭ̇̚O̿̔ͪ̓̋ͭ҉̘̻̗̜̗͎̗@͍ͣͯ́ͨ̄̆̐Z̾ͪ̾ͥ̎Ả͖̫͔̮ͪͧ̔ͨ̀L̰͖̹͚̲̈́ͩ͋͒̅G̴͆Ö̬̬̰̱̦̱͛̅̔ͩ̇̔")
        
        // when
        let mockUser = SwiftMockLoader.mockUsers()[0]

        let mention = Mention(range: NSRange(location: 57, length: 54), user: mockUser)
        textMessageData.mentions = [mention]
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.attributes(at: mention.range.location + 1, effectiveRange: nil)[.link] as! URL, mention.link)
    }
    
    func testThatItUsesCorrectUTF16OffsetForMention_Emoji() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "Hello 👩‍❤️‍💋‍👩! @👨‍👨‍👧‍👦")
        
        // when
        let mockUser = SwiftMockLoader.mockUsers()[0]

        let mention = Mention(range: NSRange(location: 19, length: 12), user: mockUser)
        textMessageData.mentions = [mention]
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.attributes(at: mention.range.location + 1, effectiveRange: nil)[.link] as! URL, mention.link)
    }
    
    func testThatEmojiAreNotRenderedInsideCodeBlock() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "`:(`")
        
        // when
        let formattedText = NSAttributedString.format(message: textMessageData, isObfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, ":(")
    }
}
