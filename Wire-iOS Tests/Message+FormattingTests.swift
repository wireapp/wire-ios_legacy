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

    func createTextMessageData(withMessageTemplate messageTemplate: String) -> MockTextMessageData {
        var text = messageTemplate
        text = text.replacingOccurrences(of: "{preview-url}", with: previewURL)
        text = text.replacingOccurrences(of: "{regular-url}", with: regularURL)

        let textMessageData = MockTextMessageData()
        textMessageData.messageText = text
        let range = textMessageData.messageText.range(of: previewURL)!
        let offset = textMessageData.messageText.distance(from: textMessageData.messageText.startIndex, to: range.lowerBound)
        
        if (messageTemplate.contains("{preview-url}")) {
            textMessageData.linkPreview = Article(originalURLString: previewURL, permanentURLString: previewURL, resolvedURLString: previewURL, offset: offset)
        }
        
        return textMessageData
    }
    
    func testTextWithTrailingLinkPreviewURL() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "text text {preview-url}")
        
        // when
        let formattedText = NSAttributedString.formattedString(with: Message.linkAttachments(textMessageData), forMessage: textMessageData, isGiphy: false, obfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "text text")
    }

    func testTextWithTrailingLinkPreviewURL_Giphy() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "text text {preview-url}")

        // when
        let formattedText = NSAttributedString.formattedString(with: Message.linkAttachments(textMessageData), forMessage: textMessageData, isGiphy: true, obfuscated: false)

        // then
        XCTAssertEqual(formattedText.string, "text text \(previewURL)")
    }

    func testTextWithTrailingLinkPreviewURL_GiphyAlone() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "{preview-url}")

        // when
        let formattedText = NSAttributedString.formattedString(with: Message.linkAttachments(textMessageData), forMessage: textMessageData, isGiphy: true, obfuscated: false)

        // then
        XCTAssertEqual(formattedText.string, previewURL)
    }
    
    func testTextWithTrailingLinkPreviewURL_Variation1() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "text text {regular-url} {preview-url}")
        
        // when
        let formattedText = NSAttributedString.formattedString(with: Message.linkAttachments(textMessageData), forMessage: textMessageData, isGiphy: false, obfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "text text \(regularURL)")
    }
    
    func testTextWithTrailingLinkPreviewURL_Variation2() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "text text {preview-url} {regular-url}")
        
        // when
        let formattedText = NSAttributedString.formattedString(with: Message.linkAttachments(textMessageData), forMessage: textMessageData, isGiphy: false, obfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "text text \(previewURL) \(regularURL)")
    }
    
    func testTextWithLeadingLinkPreviewURL() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "{preview-url} text text")
        
        // when
        let formattedText = NSAttributedString.formattedString(with: Message.linkAttachments(textMessageData), forMessage: textMessageData, isGiphy: false, obfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "\(previewURL) text text")
    }
    
    func testTextWithLeadingLinkPreviewURL_Variation1() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "{preview-url} {regular-url} text text")
        
        // when
        let formattedText = NSAttributedString.formattedString(with: Message.linkAttachments(textMessageData), forMessage: textMessageData, isGiphy: false, obfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "\(previewURL) \(regularURL) text text")
    }
    
    func testTextWithLeadingLinkPreviewURL_Variation2() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "{regular-url} {preview-url} text text")
        
        // when
        let formattedText = NSAttributedString.formattedString(with: Message.linkAttachments(textMessageData), forMessage: textMessageData, isGiphy: false, obfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "\(regularURL) \(previewURL) text text")
    }
    
    func testTextWithOnlyLinkPreviewURL() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "{preview-url}")
        
        // when
        let formattedText = NSAttributedString.formattedString(with: Message.linkAttachments(textMessageData), forMessage: textMessageData, isGiphy: false, obfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "")
    }
    
    func testTextWithInvalidLinkAttachment() {
        // given
        let textMessageData = createTextMessageData(withMessageTemplate: "hello:{preview-url}") // NSDataDetector gets confused by this text
        
        // when
        let formattedText = NSAttributedString.formattedString(with: Message.linkAttachments(textMessageData), forMessage: textMessageData, isGiphy: false, obfuscated: false)
        
        // then
        XCTAssertEqual(formattedText.string, "hello:")
    }

}
