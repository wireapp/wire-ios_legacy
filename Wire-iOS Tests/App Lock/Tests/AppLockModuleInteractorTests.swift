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

    // MARK: - Initiate authentication

    func test_NeedsToCreatePasscode_IfNoneIsSet_AndBiometricsIsRequired() {
        // Given
        appLock.isCustomPasscodeSet = false
        appLock.requireCustomPasscode = true

        // When
        sut.execute(.initiateAuthentication)

        // Then
        XCTAssertEqual(presenter.results, [.customPasscodeCreationNeeded(shouldInform: false)])
    }

    func test_NeedsToCreatePasscode_IfNoneIsSet_AndNoAuthenticationTypeIsAvailable() {
        // Given
        appLock.isCustomPasscodeSet = false
        authenticationType.current = .unavailable

        // When
        sut.execute(.initiateAuthentication)

        // Then
        XCTAssertEqual(presenter.results, [.customPasscodeCreationNeeded(shouldInform: false)])
    }

    func test_NeedsToCreatePasscode_InformingUserOfConfigChange() {
        // Given
        appLock.isCustomPasscodeSet = false
        appLock.requireCustomPasscode = true
        appLock.needsToNotifyUser = true

        // When
        sut.execute(.initiateAuthentication)

        // Then
        XCTAssertEqual(presenter.results, [.customPasscodeCreationNeeded(shouldInform: true)])
    }

    func test_NeedsToCreatePasscode_WithoutInformingUserOfConfigChange() {
        // Given
        appLock.isCustomPasscodeSet = false
        appLock.requireCustomPasscode = true
        appLock.needsToNotifyUser = false

        // When
        sut.execute(.initiateAuthentication)

        // Then
        XCTAssertEqual(presenter.results, [.customPasscodeCreationNeeded(shouldInform: false)])
    }

    func test_ProceedWithAuthentication_WhenCustomPasscodeIsNotNeeded() {
        // Given
        appLock.isCustomPasscodeSet = false
        appLock.requireCustomPasscode = false
        authenticationType.current = .passcode

        // When
        sut.execute(.initiateAuthentication)

        // Then
        XCTAssertEqual(presenter.results, [.readyForAuthentication(shouldInform: false)])
    }

    func test_ProceedWithAuthentication_WithCustomPasscode() {
        // Given
        appLock.isCustomPasscodeSet = true

        // When
        sut.execute(.initiateAuthentication)

        // Then
        XCTAssertEqual(presenter.results, [.readyForAuthentication(shouldInform: false)])
    }

    func test_ProceedWithAuthentication_InformingUserOfConfigChange() {
        // Given
        appLock.isCustomPasscodeSet = true
        appLock.needsToNotifyUser = true

        // When
        sut.execute(.initiateAuthentication)

        // Then
        XCTAssertEqual(presenter.results, [.readyForAuthentication(shouldInform: true)])
    }

    func test_ProceedWithAuthentication_WithoutInformingUserOfConfigChange() {
        // Given
        appLock.isCustomPasscodeSet = true
        appLock.needsToNotifyUser = false

        // When
        sut.execute(.initiateAuthentication)

        // Then
        XCTAssertEqual(presenter.results, [.readyForAuthentication(shouldInform: false)])
    }
    
    // MARK: - Evaluate authentication

    func test_AuthenticationIsSuccessful_IfSessionIsAlreadyUnlocked() {
        // Given
        session.lock = .none

        // When
        sut.execute(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 0)
        XCTAssertEqual(appLock.methodCalls.open.count, 1)
    }

    func test_EvalutesWithScreenLockScenario_IfSessionHasScreenLock() {
        // Given
        session.lock = .screen
        appLock.requireCustomPasscode = false

        // When
        sut.execute(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 1)

        let preference = appLock.methodCalls.evaluateAuthentication[0].preference
        XCTAssertEqual(preference, .deviceThenCustom)
    }

    func test_EvalutesWithBiometricsScreenLockScenario_IfSessionHasScreenLock_AndBiometricsRequired() {
        // Given
        session.lock = .screen
        appLock.requireCustomPasscode = true

        // When
        sut.execute(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 1)

        let preference = appLock.methodCalls.evaluateAuthentication[0].preference
        XCTAssertEqual(preference, .customOnly)
    }

    func test_EvalutesWithDatabaseScenario_IfSessionHasDatabaseLock() {
        // Given
        session.lock = .database

        // When
        sut.execute(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

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
        sut.execute(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))
        
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
            sut.execute(.evaluateAuthentication)
            XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))
        }

        // Then
        XCTAssertEqual(session.methodCalls.unlockDatabase.count, 0)
    }

    func test_PresenterIsInformed_OfAllUnsuccessfulAuthenticationResults() {
        // Given
        session.lock = .screen

        let authenticationResults: [AppLockModule.AuthenticationResult] = [
            .denied,
            .needCustomPasscode,
            .unavailable
        ]

        // When
        for result in authenticationResults {
            appLock._authenticationResult = result
            sut.execute(.evaluateAuthentication)
            XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))
        }

        // Then
        XCTAssertEqual(presenter.results, [.authenticationDenied, .customPasscodeNeeded, .authenticationUnavailable])
    }

    // MARK: - Open app lock

    func test_ItOpensAppLock() {
        // When
        sut.execute(.openAppLock)

        // Then
        XCTAssertEqual(appLock.methodCalls.open.count, 1)
    }

}
