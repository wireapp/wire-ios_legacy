//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
@testable import Wire

final class AppLockModuleInteractorTests: XCTestCase {
    
    private var sut: AppLockModule.Interactor!
    private var presenter: AppLockModule.MockPresenter!
    private var session: AppLockModule.MockSession!
    private var appLock: AppLockModule.MockAppLockController!
    private var authenticationType: AppLockModule.MockAuthenticationTypeDetector!
    
    override func setUp() {
        super.setUp()
        presenter = .init()
        session = .init()
        appLock = .init()
        authenticationType = .init()

        session.appLockController = appLock

        sut = .init(session: session, authenticationType: authenticationType)
        sut.presenter = presenter
    }
    
    override func tearDown() {
        sut = nil
        presenter = nil
        session = nil
        appLock = nil
        authenticationType = nil
        super.tearDown()
    }

    // MARK: - Needs to create passcode

    func test_NeedsToCreatePasscode_IfNoneIsSet_AndBiometricsIsRequired() {
        // Given
        appLock.isCustomPasscodeNotSet = true
        appLock.requiresBiometrics = true

        // Then
        XCTAssertTrue(sut.needsToCreateCustomPasscode)
    }

    func test_NeedsToCreatePasscode_IfNoneIsSet_AndNoAuthenticationTypeIsAvailable() {
        // Given
        appLock.isCustomPasscodeNotSet = true
        authenticationType.current = .unavailable

        // Then
        XCTAssertTrue(sut.needsToCreateCustomPasscode)
    }

    func test_NoNeedToCreateCustomPasscode_IfOneIsSet() {
        // Given
        appLock.isCustomPasscodeNotSet = false

        // Then
        XCTAssertFalse(sut.needsToCreateCustomPasscode)
    }

    func test_NoNeedToCreatePasscode_IfNoneIsSet_BiometricsIsNotRequired_DevicePasscodeIsSet() {
        // Given
        appLock.isCustomPasscodeNotSet = true
        appLock.requiresBiometrics = false
        authenticationType.current = .passcode

        // Then
        XCTAssertFalse(sut.needsToCreateCustomPasscode)
    }
    
    // MARK: - Evaluate authentication

    func test_AuthenticationIsSuccessful_IfSessionIsAlreadyUnlocked() {
        // Given
        session.lock = .none

        // When
        sut.evaluateAuthentication()

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 0)
        XCTAssertEqual(presenter.methodCalls.authenticationEvaluated, [.granted])
    }

    func test_EvalutesWithScreenLockScenario_IfSessionHasScreenLock() {
        // Given
        session.lock = .screen
        appLock.requiresBiometrics = false

        // When
        sut.evaluateAuthentication()

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 1)

        let preference = appLock.methodCalls.evaluateAuthentication[0].preference
        XCTAssertEqual(preference, .deviceThenCustom)
    }

    func test_EvalutesWithBiometricsScreenLockScenario_IfSessionHasScreenLock_AndBiometricsRequired() {
        // Given
        session.lock = .screen
        appLock.requiresBiometrics = true

        // When
        sut.evaluateAuthentication()

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 1)

        let preference = appLock.methodCalls.evaluateAuthentication[0].preference
        XCTAssertEqual(preference, .customOnly)
    }

    func test_EvalutesWithDatabaseScenario_IfSessionHasDatabaseLock() {
        // Given
        session.lock = .database

        // When
        sut.evaluateAuthentication()

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 1)

        let preference = appLock.methodCalls.evaluateAuthentication[0].preference
        XCTAssertEqual(preference, .deviceOnly)
    }
    
    func test_DatabaseIsUnlocked_IfAuthenticationIsSuccessful() {
        // Given
        session.lock = .database
        appLock._authenticationResult = .granted

        // When
        sut.evaluateAuthentication()
        
        // Then
        XCTAssertEqual(session.methodCalls.unlockDatabase.count, 1)
    }
    
    func test_DatabaseIsNotUnlocked_IfAuthenticationIsNotSuccessful() {
        // Given
        session.lock = .database

        let authenticationResults: [AppLockModule.AuthenticationResult] = [
            .denied,
            .needCustomPasscode,
            .unavailable
        ]
        
        // When
        for result in authenticationResults {
            appLock._authenticationResult = result
            sut.evaluateAuthentication()
        }

        // Then
        XCTAssertEqual(session.methodCalls.unlockDatabase.count, 0)
    }

    func test_PresenterIsInformed_OfAllAuthenticationResults() {
        // Given
        session.lock = .screen

        let authenticationResults: [AppLockModule.AuthenticationResult] = [
            .granted,
            .denied,
            .needCustomPasscode,
            .unavailable
        ]

        // When
        for result in authenticationResults {
            appLock._authenticationResult = result
            sut.evaluateAuthentication()
        }

        // Then
        XCTAssertEqual(presenter.methodCalls.authenticationEvaluated, authenticationResults)
    }

    // MARK: - Open app lock

    func test_ItOpensAppLock() {
        // When
        sut.openAppLock()

        // Then
        XCTAssertEqual(appLock.methodCalls.open.count, 1)
    }

}
