//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class UIColorMixingTests: XCTestCase {
    func testThatBlackAndWhiteIsMixedToGrey() {
        ///GIVEN
        let whiteColor = UIColor.white
        let blackColor = UIColor.black

        ///WHEN
        let sut = whiteColor.mix(blackColor, amount: 0.5).components
        
        ///THEN
        XCTAssertEqual(sut.red, 0.5)
        XCTAssertEqual(sut.green, 0.5)
        XCTAssertEqual(sut.blue, 0.5)
        XCTAssertEqual(sut.alpha, 1)
    }

    func testThatBlackAndWhiteWithAlphaIsMixedToGreyWithNoAlpha() {
        ///GIVEN
        let alphaWhiteColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        let alphaBlackColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        ///WHEN
        let sut = alphaWhiteColor.removeAlphaByBlending(with: alphaBlackColor).components
        
        ///THEN
        XCTAssertEqual(sut.red, 0.5)
        XCTAssertEqual(sut.green, 0.5)
        XCTAssertEqual(sut.blue, 0.5)
        XCTAssertEqual(sut.alpha, 1)
    }
}
