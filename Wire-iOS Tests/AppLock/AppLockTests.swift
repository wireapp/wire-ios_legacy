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
import LocalAuthentication

final class AppLockTests: XCTestCase {

    let decoder = JSONDecoder()
    
    override func tearDown() {
        super.tearDown()
        
        AppLock.isActive = false
    }
    
    func testThatForcedAppLockDoesntAffectSettings() {
        
        //given
        AppLock.rules = AppLockRules(useBiometricsOrAccountPassword: false,
                                     useCustomCodeInsteadOfAccountPassword: false,
                                     forceAppLock: true,
                                     appLockTimeout: 900)
        
        //when
        XCTAssertFalse(AppLock.rules.useBiometricsOrAccountPassword)
        XCTAssertTrue(AppLock.rules.forceAppLock)
        XCTAssertEqual(AppLock.rules.appLockTimeout, 900)
        
        //then
        XCTAssertTrue(AppLock.isActive)
        AppLock.isActive = false
        XCTAssertTrue(AppLock.isActive)
        AppLock.isActive = true
        XCTAssertTrue(AppLock.isActive)
    }
    
    func testThatAppLockAffectsSettings() {
        
        //given
        AppLock.rules = AppLockRules(useBiometricsOrAccountPassword: false, useCustomCodeInsteadOfAccountPassword: false, forceAppLock: false, appLockTimeout: 10)

        //when
        XCTAssertFalse(AppLock.rules.useBiometricsOrAccountPassword)
        XCTAssertFalse(AppLock.rules.forceAppLock)
        XCTAssertEqual(AppLock.rules.appLockTimeout, 10)
        
        //then
        AppLock.isActive = false
        XCTAssertFalse(AppLock.isActive)
        AppLock.isActive = true
        XCTAssertTrue(AppLock.isActive)
    }
    
    func testThatAppLockRulesObjectIsDecodedCorrectly() {
        //given
        let json = "{\"forceAppLock\":true,\"appLockTimeout\":900,\"useBiometricsOrAccountPassword\":true,\"useCustomCodeInsteadOfAccountPassword\":false}"

        //when
        let sut = AppLockRules.fromData(json.data(using: .utf8)!)
        //then
        XCTAssertTrue(sut.forceAppLock)
        XCTAssertTrue(sut.useBiometricsOrAccountPassword)
        XCTAssertEqual(sut.appLockTimeout, 900)
    }

    func testThatBiometricsChangedIsTrueIfDomainStatesDiffer() {
        //given
        UserDefaults.standard.set(Data(), forKey: "DomainStateKey")
        
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error)
        
        //when/then
        XCTAssertTrue(BiometricsState.biometricsChanged(in: context))
    }
    
    func testThatBiometricsChangedIsFalseIfDomainStatesDontDiffer() {
        //given
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error)
        UserDefaults.standard.set(context.evaluatedPolicyDomainState, forKey: "DomainStateKey")
        
        //when/then
        XCTAssertFalse(BiometricsState.biometricsChanged(in: context))
    }
    
    func testThatBiometricsStatePersistsState() {
        //given
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error)
        _ = BiometricsState.biometricsChanged(in: context)
        
        //when
        BiometricsState.persist()
        
        //then
        XCTAssertEqual(context.evaluatedPolicyDomainState, UserDefaults.standard.object(forKey: "DomainStateKey") as? Data)
    }
}
