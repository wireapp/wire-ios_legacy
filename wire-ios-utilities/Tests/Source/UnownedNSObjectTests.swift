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

final class UnownedNSObjectTests: XCTestCase {

    func testThatCreatingAnUnownedNSObjectWithALocallyScopedObjectIsValid() {
        let unown = UnownedNSObject(NSNumber(value: 10))
        XCTAssertTrue(unown.isValid)
        XCTAssertEqual(NSNumber(value: 10), unown.unbox!)
    }
    
    
    func testThatUnownedNSObjectIsInvalidIfObjectDoesNotExistAnymore() {
        var array : Array<NSObject>? = [NSObject()]
        let unownedObject = UnownedNSObject(array![0] as NSObject)
        array = nil
        XCTAssertFalse(unownedObject.isValid)
        XCTAssertNil(unownedObject.unbox, "unownedObject.unbox = \(String(describing: unownedObject.unbox))")
    }
}
