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

class AnyClassTupleTests: ZMBaseManagedObjectTest {

    func testThatTwoTuplesAreEqual() {

        // given
        let classOfObject: AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")

        // then
        XCTAssertEqual(tuple1, tuple2)

    }

    func testThatTwoTuplesHaveTheSameHash() {

        // given
        let classOfObject: AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")

        // then
        XCTAssertEqual(tuple1.hashValue, tuple2.hashValue)

    }

    func testThatTwoTuplesAreNotEqualOnString() {

        // given
        let classOfObject: AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Bar")

        // then
        XCTAssertNotEqual(tuple1, tuple2)

    }

    func testThatTwoTuplesDoNotHaveTheSameHashOnString() {

        // given
        let classOfObject: AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Bar")

        // then
        XCTAssertNotEqual(tuple1.hashValue, tuple2.hashValue)

    }

    func testThatTwoTuplesAreNotEqualOnClass() {

        // given
        let classOfObject: AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: NSArray.self, secondElement: "Foo")

        // then
        XCTAssertNotEqual(tuple1, tuple2)

    }

    func testThatTwoTuplesDoNotHaveTheSameHashOnClass() {

        // given
        let classOfObject: AnyClass = AnyClassTupleTests.self
        let tuple1 = AnyClassTuple<String>(classOfObject: classOfObject, secondElement: "Foo")
        let tuple2 = AnyClassTuple<String>(classOfObject: NSArray.self, secondElement: "Foo")

        // then
        XCTAssertNotEqual(tuple1.hashValue, tuple2.hashValue)

    }
}
