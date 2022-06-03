//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


class String_FilenameTests: XCTestCase {
    
    func testShortUserNameToFileName() {
        // GIVEN
        let username = "John Smith"
        let filename = username.normalizedFilename.trimmedFilename(numReservedChar: 0)
        
        // WHEN & THEN
        XCTAssertEqual(filename, "John-Smith")
    }

    func testEmojiUserNameWithUUIDPrefixAndExtensionToFileName() {
        // GIVEN
        let username = "🇭🇰🇭🇰🇭🇰🇭🇰🇭🇰🇭🇰🇭🇰"
        let filename = username.normalizedFilename.trimmedFilename(numReservedChar: 0)
        let uuidString = UUID.create().uuidString
        let exampleFileName = uuidString + "_" + filename + ".mp4"
        
        // WHEN & THEN
        XCTAssertEqual(exampleFileName.count, 255)
    }

    func testEmojiUserNameWithUUIDPrefixAndAndSubfixAndExtensionToFileName() {
        // GIVEN
        let username = "🇭🇰🇭🇰🇭🇰🇭🇰🇭🇰🇭🇰🇭🇰"
        let suffix = "_dummy_date_stamp"
        let filename = username.normalizedFilename.trimmedFilename(numReservedChar: suffix.count)
        let uuidString = UUID.create().uuidString
        let exampleFileName = uuidString + "_" + filename + suffix + ".mp4"
        
        // WHEN & THEN
        XCTAssertEqual(exampleFileName.count, 255)
    }

    func testChineseUserNameToLatinFileName() {
        // GIVEN
        let username = "使用者"
        let filename = username.normalizedFilename.trimmedFilename(numReservedChar: 0)
        
        // WHEN & THEN
        XCTAssertEqual(filename, "shi-yong-zhe")
    }

    func testArabicToFileName() {
        // GIVEN
        let username = "الأشخاص المفضلين"

        let filename = username.normalizedFilename.trimmedFilename(numReservedChar: 0)
        
        // WHEN & THEN
        XCTAssertEqual(filename, "alashkhas-almfdlyn")
    }

}
