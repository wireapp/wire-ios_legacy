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

import Foundation
import XCTest
@testable import WireSystem

class ReferenceAllocationTests: XCTestCase {
    func testThatExistingObjectIsMarkedAsValid() {
        // GIVEN
        let object = TestClass()
        let sut = ReferenceAllocation(object: object, pointerAddress:"2", file:"some", line: 10)
        
        // THEN
        XCTAssertTrue(sut.isValid)
    }
    
    func testThatNilObjectIsMarkedAsNotValid() {
        // GIVEN
        let object: AnyObject? = nil
        let sut = ReferenceAllocation(object: object, pointerAddress:"2", file:"some", line: 10)
        
        // THEN
        XCTAssertFalse(sut.isValid)
    }
    
    func testItTracksObjectLifetime() {
        // GIVEN
        var object: TestClass? = TestClass()
        let sut = ReferenceAllocation(object: object, pointerAddress:"2", file:"some", line: 10)
        XCTAssertTrue(sut.isValid)

        // WHEN
        object = nil
        
        // THEN
        XCTAssertFalse(sut.isValid)
    }
}

class MemoryReferenceDebuggerTests: XCTestCase {
    
    func testThatItDoesNotTrackNils() {
        // WHEN
        MemoryReferenceDebugger.register(nil)
        
        // THEN
        XCTAssertTrue(MemoryReferenceDebugger.aliveObjects.isEmpty)
    }
    
    func testThatItDetectsObjectsThatAreStillAlive() {
        
        // GIVEN
        let sut = TestClass()
        
        // WHEN
        MemoryReferenceDebugger.register(sut)
        
        // THEN
        XCTAssertFalse(MemoryReferenceDebugger.aliveObjects.isEmpty)
    }
    
    func testThatItFiltersOutObjectsThatAreNotAlive() {
        
        // GIVEN
        var sut: TestClass? = TestClass()
        
        // WHEN
        MemoryReferenceDebugger.register(sut)
        sut = nil
        
        // THEN
        XCTAssertTrue(MemoryReferenceDebugger.aliveObjects.isEmpty)
    }
    
    func testThatItResetsListOfReferences() {
        
        // GIVEN
        let sut = TestClass()
        
        // WHEN
        MemoryReferenceDebugger.register(sut)
        MemoryReferenceDebugger.reset()
        
        // THEN
        XCTAssertTrue(MemoryReferenceDebugger.aliveObjects.isEmpty)
    }
    
    func testErrorDescription() {
        // GIVEN
        let sut = NSURL(fileURLWithPath: "Path")
        let file: StaticString = "File"
        let line: UInt = 10
        
        // WHEN
        MemoryReferenceDebugger.register(sut, line: line, file: file)
        
        // THEN
        let description = MemoryReferenceDebugger.aliveObjectsDescription
        XCTAssertTrue(description.contains("\(file):\(line)"))
        XCTAssertTrue(description.contains("\(type(of: sut))"))
    }
}


private class TestClass {
    
}
