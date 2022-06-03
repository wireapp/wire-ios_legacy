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


import XCTest
import WireUtilities

class NSUUIDType1Tests: XCTestCase {

    /// type 1 sample UUID sorted by timestamp, and corresponding unix timestamp (with accuracy up to 0.01)
    static let sortedType1UUIDStrings : [(String, TimeInterval)] = [
        ("a6526b00-000a-11e5-a837-0800200c9a66", 1432248144.48),
        ("54ad3a24-be09-11e5-9912-ba0be0483c18", 1453138298.93),
        ("54ad3f92-be09-11e5-9912-ba0be0483c18", 1453138298.93),
        ("54ad415e-be09-11e5-9912-ba0be0483c18", 1453138298.93),
        ("54ad4672-be09-11e5-9912-ba0be0483c18", 1453138298.93),
        ("b892b180-be0a-11e5-a837-0800200c9a66", 1453138896.02),
        ("c7527b10-be0a-11e5-a837-0800200c9a66", 1453138920.77)
    ]

    func testThatItDetectsType1UUID() {
        // given
        let uuid = NSUUID(uuidString: NSUUIDType1Tests.sortedType1UUIDStrings[0].0)!
        
        // then
        XCTAssertTrue(uuid.isType1UUID)
    }
    
    func testThatItDetectsANonType1UUID() {
        // given
        let uuid = UUID() // this is guaranteed to generate a type 4
        
        // then
        XCTAssertFalse(uuid.isType1UUID)
    }
    
    func testThatItGetsTheRightTimestamps() {

        for (string, timestamp) in NSUUIDType1Tests.sortedType1UUIDStrings
        {
            let uuid = UUID.init(uuidString: string)!
            let date = Date(timeIntervalSince1970: timestamp)
            
            // the timestamps in the sample data have some rounding errors
            // so I can't test that they are equal, just that they are not too different
            let dateDiff = uuid.type1Timestamp!.timeIntervalSince1970 - date.timeIntervalSince1970
            XCTAssertLessThanOrEqual(abs(dateDiff), 0.01)
        }
    }
    
    func testThatItComparesTwoUUIDsByTime() {
        
        // given
        let earlierUUID = UUID.init(uuidString: NSUUIDType1Tests.sortedType1UUIDStrings[1].0)!
        let laterUUID = UUID.init(uuidString: NSUUIDType1Tests.sortedType1UUIDStrings[3].0)!
        let sameUUID = UUID.init(uuidString: NSUUIDType1Tests.sortedType1UUIDStrings[1].0)!
        
        // then
        XCTAssertEqual(earlierUUID.compare(withType1UUID: laterUUID as NSUUID), ComparisonResult.orderedAscending)
        XCTAssertEqual(laterUUID.compare(withType1UUID: earlierUUID as NSUUID), ComparisonResult.orderedDescending)
        XCTAssertEqual(earlierUUID.compare(withType1UUID: sameUUID as NSUUID), ComparisonResult.orderedSame)
    }
    
    func testThatItComparesType1UUIDsByTime() {
        
        var previous : UUID? = nil
        for uuid in NSUUIDType1Tests.sortedType1UUIDStrings.map({ UUID(uuidString: $0.0)! }) {
            defer {
                previous = uuid
            }
            
            guard let last = previous else {
                continue
            }
            XCTAssertEqual(last.compare(withType1UUID: uuid as NSUUID), ComparisonResult.orderedAscending)
            XCTAssertEqual(uuid.compare(withType1UUID: last as NSUUID), ComparisonResult.orderedDescending)
            XCTAssertEqual(uuid.compare(withType1UUID: uuid as NSUUID), ComparisonResult.orderedSame)

        }
    }
    
    func testThatGeneratedUUIDsAreOfType1(){
        let uuid = UUID.timeBasedUUID()
        
        XCTAssertTrue(uuid.isType1UUID)
    }
}
