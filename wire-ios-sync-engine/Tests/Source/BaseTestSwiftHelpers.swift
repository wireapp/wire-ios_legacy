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
import WireTesting
import WireDataModel

func AssertKeyPathDictionaryHasOptionalValue<T: NSObject>(_ dictionary: @autoclosure () -> [WireDataModel.StringKeyPath: T?], key: @autoclosure () -> WireDataModel.StringKeyPath, expected: @autoclosure () -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if let v = dictionary()[key()] {
        AssertOptionalEqual(v, expression2: expected(), message, file: file, line: line)
    } else {
        XCTFail("No value for \(key()). \(message)", file: file, line: line)
    }
}

func AssertKeyPathDictionaryHasOptionalNilValue<T: NSObject>(_ dictionary: @autoclosure () -> [WireDataModel.StringKeyPath: T?], key: @autoclosure () -> WireDataModel.StringKeyPath, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if let v = dictionary()[key()] {
        AssertOptionalNil(v, message, file: file, line: line)
    } else {
        XCTFail("No value for \(key()). \(message)", file: file, line: line)
    }
}
