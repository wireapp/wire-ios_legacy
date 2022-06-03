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

final class UnownedObjectTests: XCTestCase {

    
    func testThatCreatingAnUnownedObjectWithALocallyScopedObjectIsValid() {
        let nsnumber = 10 as AnyObject
        let unown = UnownedObject(nsnumber)
        XCTAssertTrue(unown.isValid)
        XCTAssertEqual(10, unown.unbox! as! Int)
    }
    
    
    func testThatUnownedObjectIsInvalidIfValueDoesNotExistAnymore() {
        
        var array : Array<NSObject>? = [NSObject()]
        let unownedObject = UnownedObject(array![0] as AnyObject)
        array = nil
        XCTAssertFalse(unownedObject.isValid)
        XCTAssertNil(unownedObject.unbox)
    }
}
