////
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

import Foundation


import XCTest
@testable import WireSystem

struct Item {
    var name: String
    var age: Int
}

extension Item: SafeForLoggingStringConvertible {
    static var redacted = "<redacted>"
    
    var safeForLoggingDescription: String {
        return Item.redacted
    }
}


class SanitizedStringTests: XCTestCase {
    
    var item: Item!
    
    override func setUp() {
        super.setUp()
        item = Item(name: "top-secret", age: 99)
    }
    
    override func tearDown() {
        item = nil
        super.tearDown()
    }
    
    func testInterpolation() {
        let interpolated: SanitizedString = "\(item)"
        let redacted: SanitizedString = "<redacted>"
        XCTAssertEqual(redacted, interpolated)
    }
    
    func testInterpolationWithLiterals() {
        let interpolated: SanitizedString = "some \(item) item"
        let result = SanitizedString(stringLiteral: "some \(Item.redacted) item")
        XCTAssertEqual(result, interpolated)
    }
    
    func testAddition() {
        XCTAssertEqual(
            SanitizedString(value: "<redacted>foo"),
            SanitizedString("\(item)") + SanitizedString(value: "foo")
        )
        XCTAssertEqual(
            SanitizedString(value: "<redacted><redacted>"),
            SanitizedString("\(item)") + item
        )
        XCTAssertEqual(
            SanitizedString(value: "<redacted>nil"),
            SanitizedString("\(item)") + Optional<Item>(nil)
        )
    }
}

extension SanitizedStringTests {
    func testString() {
        let sut = "some"
        let value = SafeValueForLogging(sut)
        let result: SanitizedString = "\(value)"
        XCTAssertEqual(sut, result.value)
    }
    
    func testSanitizedString() {
        let sut = SanitizedString("some")
        let value = SafeValueForLogging(sut)
        let result: SanitizedString = "\(value)"
        XCTAssertEqual(sut, result)
    }
    
    func testInt() {
        let sut = 12
        let value = SafeValueForLogging(sut)
        let result: SanitizedString = "\(value)"
        XCTAssertEqual(String(sut), result.value)
    }
    
    func testFloat() {
        let sut: Float = 12.1
        let value = SafeValueForLogging(sut)
        let result: SanitizedString = "\(value)"
        XCTAssertEqual(String(sut), result.value)
    }
    
    func testDouble() {
        let sut: Double = 12.1
        let value = SafeValueForLogging(sut)
        let result: SanitizedString = "\(value)"
        XCTAssertEqual(String(sut), result.value)
    }
    
    func testArray() {
        let sut = [1, 2, 3]
        let value = SafeValueForLogging(sut)
        let result: SanitizedString = "\(value)"
        XCTAssertEqual(String(describing: sut), result.value)
    }
    
    func testDictionary() {
        let sut = ["some" : 2]
        let value = SafeValueForLogging(sut)
        let result: SanitizedString = "\(value)"
        
        XCTAssertEqual(String(describing: sut), result.value)
    }
    
    func testOptional_nil() {
        let value: SafeValueForLogging<String>? = nil
        let result: SanitizedString = "\(value)"
        XCTAssertEqual("nil", result.value)
    }
    
    func testOptional_notNil() {
        let sut = "something"
        let value: SafeValueForLogging<String>? = SafeValueForLogging(sut)
        let result: SanitizedString = "\(value)"
        
        XCTAssertEqual(String(describing: sut), result.value)
    }
}
