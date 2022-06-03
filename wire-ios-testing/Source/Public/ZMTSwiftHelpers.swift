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


public func AssertOptionalNil<T>(_ condition: @autoclosure () -> T?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if let value = condition() {
        XCTFail("\(value) is not nil: \(message)", file: file, line: line)
    }
}

public func AssertOptionalEqual<T : Equatable>(_ expression1: @autoclosure () -> T?, expression2: @autoclosure () -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if let v = expression1() {
        XCTAssertEqual(v, expression2(), message, file: file, line: line)
    } else {
        XCTFail("Value is nil. \(message)", file: file, line: line)
    }
}

public func AssertOptionalNotNil<T>(_ expression: @autoclosure () -> T?, _ message: String = "", file: StaticString = #file, line: UInt = #line, block: (T) -> () = {_ in}) {
    if let v = expression() {
        block(v)
    } else {
        XCTFail("Value is nil. \(message)", file: file, line: line)
    }
}

public func AssertDictionaryHasOptionalValue<T: NSObject>(_ dictionary: @autoclosure () -> [String: T?], key: @autoclosure () -> String, expected: @autoclosure () -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if let v = dictionary()[key()] {
        AssertOptionalEqual(v, expression2: expected(), message, file: file, line: line)
    } else {
        XCTFail("No value for \(key()). \(message)", file: file, line: line)
    }
}


public func AssertDictionaryHasOptionalNilValue<T: NSObject>(_ dictionary: @autoclosure () -> [String: T?], key: @autoclosure () -> String, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if let v = dictionary()[key()] {
        AssertOptionalNil(v, message , file: file, line: line)
    } else {
        XCTFail("No value for \(key()). \(message)", file: file, line: line)
    }
}

