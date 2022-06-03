//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

final class NSDataImageTests: XCTestCase {
    func testThatNonAnimateGifIsIdentified() {
        // given
        let sut: NSData = self.data(forResource: "not_animated", extension: "gif")! as NSData
        
        // when & then
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isDataAnimatedGIF())
    }

    func testThatAnimateGifIsIdentified() {
        // given
        let sut: NSData = self.data(forResource: "animated", extension: "gif")! as NSData
        
        // when & then
        XCTAssertNotNil(sut)
        XCTAssert(sut.isDataAnimatedGIF())
    }
    
    func testThatGifmimeTypeIsResolved() {
        // given
        let sut: Data = self.data(forResource: "animated", extension: "gif")!

        // when & then
        XCTAssertEqual(sut.mimeType, "image/gif")
    }
    
    func testThatTxtmimeTypeIsNotResolved() {
        // given
        let sut: Data = self.data(forResource: "excessive_diacritics", extension: "txt")!

        // when & then
        XCTAssertNil(sut.mimeType)
    }
}
