//
//  NSData_ImageTypeTests.swift
//  Wire-iOS
//
//  Created by John Nguyen on 12.09.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
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
