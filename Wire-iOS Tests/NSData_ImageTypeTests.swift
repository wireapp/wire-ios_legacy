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
@testable import Wire

class NSData_ImageTypeTests: XCTestCase {
        
    func testThatItIdentifiesJPEG() {
        
        // given
        guard let jpeg = UIImageJPEGRepresentation(#imageLiteral(resourceName: "wire-logo-shield"), 1.0) else {
            XCTFail()
            return
        }
        
        let sut = NSData(data: jpeg)
        
        // then
        XCTAssertTrue(sut.isJPEG)
    }
    
    func testThatItDoesNotIdentifyJPEG() {
        
        // given
        guard let png = UIImagePNGRepresentation(#imageLiteral(resourceName: "wire-logo-shield")) else {
            XCTFail()
            return
        }
        
        let sut = NSData(data: png)
        
        // then
        XCTAssertFalse(sut.isJPEG)
    }
}
