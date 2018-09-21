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


import Foundation
import XCTest
@testable import Wire

class EmojiOnlyStringTests: XCTestCase {
    
    func testThatCommonEmojisAreDetected() {
        // given
        let commonEmoji = ["©️", "ℹ️", "☘️", "⏰️", "➰️", "♥️", "🀄️", "🇨🇭",
                           "😜", "🙏", "🌝", "😘", "👍", "💩", "😂", "😍", "😁",
                           "❤︎", "❤️", "🈚︎",  "🀄︎", //emoji variation
                           "👩", "👩🏻", "👩🏼", "👩🏽", "👩🏾", "👩🏿", //Fitzpatrick modifiers
                           "👨‍👩‍👧", "🏳️‍🌈", // Joining
                           "🧘🏿‍♀️", "🧡", "🦒", "🧦", "🏴󠁧󠁢󠁷󠁬󠁳󠁿", "🧟‍♂️" ///Emoji 5.0
        ]
        
        // then
        commonEmoji.forEach {
            XCTAssert($0.containsOnlyEmojiWithSpaces, "Failed: \($0)")
            XCTAssert($0.containsEmoji, "Failed: \($0)")
        }
    }
    
    func testThatSeveralEmojisAreDetected() {
        // given
        let commonEmojiGroups = ["😜🙏🌝😘", "👍💩😂😍", "😁💁🙌", "👯😻"]
        // then
        commonEmojiGroups.forEach {
            XCTAssertTrue($0.wr_containsOnlyEmojiWithSpaces())
        }
    }
    
    func testThatSeveralEmojisWithSpacesAreDetected() {
        // given
        let commonEmojiGroups = ["😜      🙏 🌝 😘", "    👍💩😂😍", "😁💁🙌 ", "👯 😻"]
        // then
        commonEmojiGroups.forEach {
            XCTAssertTrue($0.wr_containsOnlyEmojiWithSpaces(), "Failed: \($0)")
        }
    }
    
    func testThatNewEmojisAreDetected() {
        // given
        let newEmoji = ["💪🏾", "🤘🏼", "👶🏼", "💅🏼"]
        // then
        newEmoji.forEach {
            XCTAssertTrue($0.wr_containsOnlyEmojiWithSpaces(), "Failed: \($0)")
        }
    }
    
    func testThatSeveralNewEmojisAreDetected() {
        // given
        let newEmojiGroups = ["💪🏾🤘🏼", "👶🏼💅🏼🤘🏼"]
        // then
        newEmojiGroups.forEach {
            XCTAssertTrue($0.wr_containsOnlyEmojiWithSpaces(), "Failed: \($0)")
        }
    }
    
    func testThatSeveralNewEmojisWithSpacesAreDetected() {
        // given
        let newEmojiGroupsWithSpaces = [" 💪🏾🤘🏼", "👶🏼 💅🏼    🤘🏼 "]
        // then
        newEmojiGroupsWithSpaces.forEach {
            XCTAssertTrue($0.wr_containsOnlyEmojiWithSpaces(), "Failed: \($0)")
        }
    }
    
    func testThatLangaugeStringIsNotDetected() {
        // given
        let langaugeStrings = ["ḀẀẶỳ", "ठःअठी३", "勺卉善爨", "Ёжик"]
        // then
        langaugeStrings.forEach {
            XCTAssertFalse($0.wr_containsOnlyEmojiWithSpaces())
            XCTAssertFalse($0.containsEmoji)
        }
    }
    
    func testThatRTLStringIsNotDetected() {
        // given
        let rtlStrings = ["  באמת!‏"]
        // then
        rtlStrings.forEach {
            XCTAssertFalse($0.wr_containsOnlyEmojiWithSpaces())
        }
    }
    
    func testThatLanguageStringWithEmojiNotDetected() {
        // given
        let languageEmojiStrings = ["😜ḀẀẶỳ", "👯ठःअठी३", "👯勺卉善爨", "👯Ёжик"]
        // then
        languageEmojiStrings.forEach {
            XCTAssertFalse($0.wr_containsOnlyEmojiWithSpaces(), "Failed: \($0)")
            XCTAssert($0.containsEmoji)
        }
    }
    
    func testThatEmptyStringIsNotDetected() {
        XCTAssertFalse("".wr_containsOnlyEmojiWithSpaces())
    }
}
