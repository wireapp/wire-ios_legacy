//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
@testable import WireCommonComponents

class AppLockTests: XCTestCase {

    let decoder = JSONDecoder()
    
    func testThatForcedAppLockDoesntAffectSettings() {

        //given
        let fileData = "{\"forceAppLock\":true,\"timeout\":900}".data(using: .utf8)!
        AppLockRules.shared = try! decoder.decode(AppLockRules.self, from: fileData)
        
        //when
        XCTAssertTrue(AppLockRules.shared.forceAppLock)
        XCTAssertEqual(AppLockRules.shared.timeout, 900)
        
        //then
        XCTAssertTrue(AppLock.isActive)
        AppLock.isActive = false
        XCTAssertTrue(AppLock.isActive)
        AppLock.isActive = true
        XCTAssertTrue(AppLock.isActive)
    }
    
    func testThatAppLockAffectsSettings() {
        
        //given
        let fileData = "{\"forceAppLock\":false,\"timeout\":10}".data(using: .utf8)!
        AppLockRules.shared = try! decoder.decode(AppLockRules.self, from: fileData)
        
        //when
        XCTAssertFalse(AppLockRules.shared.forceAppLock)
        XCTAssertEqual(AppLockRules.shared.timeout, 10)
        
        //then
        AppLock.isActive = false
        XCTAssertFalse(AppLock.isActive)
        AppLock.isActive = true
        XCTAssertTrue(AppLock.isActive)
    }
    
    
    func testThatCustomTimeoutRequiresAuthenticationAfterExpiration() {
        
        //given
        let fileData = "{\"forceAppLock\":false,\"timeout\":900}".data(using: .utf8)!
        AppLockRules.shared = try! decoder.decode(AppLockRules.self, from: fileData)
        AppLock.isActive = true
        AppLock.lastUnlockedDate = Date(timeIntervalSinceNow: -Double(AppLockRules.shared.timeout)-100)
        
        let appLockVC = AppLockViewController.shared
        
        //when
        let exp = expectation(description: "App lock authentication")
        exp.isInverted = true
        
        appLockVC.requireLocalAuthenticationIfNeeded { (result) in
            exp.fulfill()
        }
        
        //then
        // Authentication dialog presented, expectation should expire without result
        waitForExpectations(timeout: 2.0) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testThatCustomTimeoutDoesntRequireAuthenticationBeforeExpiration() {
        
        //given
        let fileData = "{\"forceAppLock\":false,\"timeout\":900}".data(using: .utf8)!
        AppLockRules.shared = try! decoder.decode(AppLockRules.self, from: fileData)
        AppLock.isActive = true
        AppLock.lastUnlockedDate = Date(timeIntervalSinceNow: -10)
        
        let appLockVC = AppLockViewController.shared
        
        //when
        let exp = expectation(description: "App lock authentication")
        appLockVC.requireLocalAuthenticationIfNeeded { (result) in
            guard let result = result else { XCTFail(); return }
            XCTAssertTrue(result)
            exp.fulfill()
        }
        
        //then
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
}
