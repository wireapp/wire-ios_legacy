//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireTesting
@testable import WireUtilities

final class NSManagedObjectContext_SwiftTests: XCTestCase {
    
    struct TestError: Error {}
    
    var sut: NSManagedObjectContext!
    
    override func setUp() {
      super.setUp()
        sut = ZMMockManagedObjectContextFactory.testManagedObjectContext(withConcurencyType: .privateQueueConcurrencyType)
        sut.createDispatchGroups()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testThatItWorksWithoutGroups() {
        // given
        let moc = ZMMockManagedObjectContextFactory.testManagedObjectContext(withConcurencyType: .privateQueueConcurrencyType)!
        // when & then
        moc.performGroupedAndWait { _ in }
    }
    
    func testThatItPassesSelfInTheClosure() {
        // when & then
        sut.performGroupedAndWait { [sut] moc in
            XCTAssertEqual(moc, sut)
        }
    }
    
    func testThatItReturnsNonOptionalValue() {
        // given
        let closure: () -> Int = {
            return 42
        }
        
        // when
        let result = sut.performGroupedAndWait { _ in
            closure()
        }
        
        // then
        XCTAssertEqual(result, 42)
    }
    
    func testThatItReturnsOptionalValue() {
        // given
        let closure: () -> Int? = {
            return nil
        }
        
        // when
        let result = sut.performGroupedAndWait { _ in
            closure()
        }
        
        // then
        XCTAssertNil(result)
    }
    
    func testThatItReturnsNonOptionalValue_Throwing() {
        // given
        let closure: () throws -> Int = {
            throw TestError()
        }
        
        do {
            // when
            try sut.performGroupedAndWait { _ in
                try closure()
            }
            XCTFail()
        } catch {
            // then
            XCTAssert(error is TestError)
        }
    }
    
    func testThatItReturnsOptionalValue_Throwing() {
        // given
        let closure: () throws -> Int? = {
            throw TestError()
        }
        
        do {
            // when
            try sut.performGroupedAndWait { _ in
                try closure()
            }
            XCTFail()
        } catch {
            // then
            XCTAssert(error is TestError)
        }
    }
}
