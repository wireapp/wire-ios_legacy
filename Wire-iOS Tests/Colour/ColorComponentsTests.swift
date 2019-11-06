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
@testable import Wire

final class ColorComponentsTests: XCTestCase {
    func testThatWhiteColorComponentsAreCorrect() {
        ///GIVEN
        let whiteColor = UIColor.white
        
        ///WHEN
        let sut = UIColor.Components(color: whiteColor)
        
        ///THEN
        XCTAssertEqual(sut.r, 1)
        XCTAssertEqual(sut.g, 1)
        XCTAssertEqual(sut.b, 1)
        XCTAssertEqual(sut.a, 1)
    }
    
    func testThatRedColorComponentsAreCorrect() {
        ///GIVEN
        let redColor = UIColor.red
        
        ///WHEN
        let sut = UIColor.Components(color: redColor)
        
        ///THEN
        XCTAssertEqual(sut, redColor.components)
    }

    func testThatColorCanNotBeCompareDirectly() {
        XCTAssertNotEqual(UIColor.black, UIColor(red: 0, green: 0, blue: 0, alpha: 1))
    }

    func testThatColorCanBeCompareWithColorComponents() {
        XCTAssertEqual(UIColor.black.components, UIColor(red: 0, green: 0, blue: 0, alpha: 1).components)
    }
}
