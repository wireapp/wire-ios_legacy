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
    private var applicationStateProvider: AppLockModule.MockApplicationStateProvider!

    override func setUp() {
        super.setUp()
        presenter = .init()
        session = .init()
        appLock = .init()
        authenticationType = .init()
        applicationStateProvider = .init()

        session.appLockController = appLock

        sut = .init(session: session,
                    authenticationType: authenticationType,
                    applicationStateProvider: applicationStateProvider)

        sut.presenter = presenter
    }

    override func tearDown() {
        sut = nil
        presenter = nil
        session = nil
        appLock = nil
        authenticationType = nil
        applicationStateProvider = nil
        super.tearDown()
    }

    // MARK: - Initiate authentication

    func test_InitiateAuthentication_NeedsToCreateCustomPasscode_Required() {
        // Given
        appLock.isCustomPasscodeSet = false
        appLock.requireCustomPasscode = true

        // When
        sut.executeRequest(.initiateAuthentication(requireActiveApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.customPasscodeCreationNeeded(shouldInform: false)])
    }

    // @SF.Locking @TSFI.UserInterface @S0.1
    func test_InitiaAuthentication_NeedsToCreateCustomPasscode_NotRequired() {
        // Given
        appLock.isCustomPasscodeSet = false
        appLock.requireCustomPasscode = false
        authenticationType.current = .unavailable

        // When
        sut.executeRequest(.initiateAuthentication(requireActiveApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.customPasscodeCreationNeeded(shouldInform: false)])
    }

    func test_InitiaAuthentication_NeedsToCreatePasscode_InformingUserOfConfigChange() {
        // Given
        appLock.isCustomPasscodeSet = false
        appLock.requireCustomPasscode = true
        appLock.needsToNotifyUser = true

        // When
        sut.executeRequest(.initiateAuthentication(requireActiveApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.customPasscodeCreationNeeded(shouldInform: true)])
    }

    // @SF.Locking @TSFI.UserInterface @S0.1
    func test_InitiateAuthentication_DoesNotNeedToCreateCustomPasscode() {
        // Given
        appLock.isCustomPasscodeSet = true

        // When
        sut.executeRequest(.initiateAuthentication(requireActiveApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.readyForAuthentication(shouldInform: false)])
    }

    func test_InitiateAuthentication_DoesNotNeedToCreateCustomPasscode_InformingUserOfConfigChange() {
        // Given
        appLock.isCustomPasscodeSet = true
        appLock.needsToNotifyUser = true

        // When
        sut.executeRequest(.initiateAuthentication(requireActiveApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.readyForAuthentication(shouldInform: true)])
    }

    // @SF.Locking @SF.Storage @TSFI.UserInterface @S0.1
    func test_InitiateAuthentication_DoesNotNeedToCreateCustomPasscode_WhenDatabaseIsLocked() {
        // Given
        session.lock = .database
        appLock.isCustomPasscodeSet = false
        authenticationType.current = .unavailable

        // When
        sut.executeRequest(.initiateAuthentication(requireActiveApp: false))

        // Then
        XCTAssertEqual(presenter.results, [.readyForAuthentication(shouldInform: false)])
    }

    // @SF.Locking @TSFI.UserInterface @S0.1
    func test_InitiateAuthentication_SessionIsAlreadyUnlocked() {
        // Given
        session.lock = .none

        // When
        sut.executeRequest(.initiateAuthentication(requireActiveApp: false))

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 0)
        XCTAssertEqual(appLock.methodCalls.open.count, 1)
    }

    // @SF.Locking @TSFI.UserInterface @S0.1
    func test_InitiateAuthentication_RequireActiveApp_ReturnsNothingIfAppIsInBackground() {
        // Given
        applicationStateProvider.applicationState = .background
        appLock.isCustomPasscodeSet = true

        // When
        sut.executeRequest(.initiateAuthentication(requireActiveApp: true))

        // Then
        XCTAssertEqual(presenter.results, [])
    }

    func test_InitiateAuthentication_NeedsToCreateCustomPasscodeAndRequireActiveApp_ReturnsNothingIfAppIsInBackground() {
        // Given
        applicationStateProvider.applicationState = .background
        appLock.isCustomPasscodeSet = false
        appLock.requireCustomPasscode = true

        // When
        sut.executeRequest(.initiateAuthentication(requireActiveApp: true))

        // Then
        XCTAssertEqual(presenter.results, [])
    }

    // MARK: - Evaluate authentication

    func test_EvaluateAuthentication_SessionIsAlreadyUnlocked() {
        // Given
        session.lock = .none

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 0)
        XCTAssertEqual(appLock.methodCalls.open.count, 1)
    }

    // @SF.Locking @TSFI.UserInterface @S0.1
    func test_EvaluateAuthentication_ScreenLock() {
        // Given
        session.lock = .screen
        appLock.requireCustomPasscode = false

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 1)

        let preference = appLock.methodCalls.evaluateAuthentication[0].preference
        XCTAssertEqual(preference, .deviceThenCustom)
    }

    func test_EvaluateAuthentication_ScreenLock_RequireCustomPasscode() {
        // Given
        session.lock = .screen
        appLock.requireCustomPasscode = true

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 1)

        let preference = appLock.methodCalls.evaluateAuthentication[0].preference
        XCTAssertEqual(preference, .customOnly)
    }

    // @SF.Locking @SF.Storage @TSFI.UserInterface @S0.1
    func test_EvaluateAuthentication_DatabaseLock() {
        // Given
        session.lock = .database

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(appLock.methodCalls.evaluateAuthentication.count, 1)

        let preference = appLock.methodCalls.evaluateAuthentication[0].preference
        XCTAssertEqual(preference, .deviceOnly)
    }

    // @SF.Locking @SF.Storage @TSFI.UserInterface @S0.1
    func test_EvaluateAuthentication_Granted() {
        // Given
        session.lock = .database
        appLock._authenticationResult = .granted

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.methodCalls.unlockDatabase.count, 1)
        XCTAssertEqual(appLock.methodCalls.open.count, 1)
    }

    // @SF.Locking @SF.Storage @TSFI.UserInterface @S0.1
    func test_EvaluateAuthentication_Denied() {
        // Given
        session.lock = .database
        appLock._authenticationResult = .denied
        authenticationType.current = .faceID

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.methodCalls.unlockDatabase.count, 0)
        XCTAssertEqual(appLock.methodCalls.open.count, 0)
        XCTAssertEqual(presenter.results, [.authenticationDenied(.faceID)])
    }

    // @SF.Locking @SF.Storage @TSFI.UserInterface @S0.1
    func test_EvaluateAuthentication_NeedCustomPasscode() {
        // Given
        session.lock = .screen
        appLock._authenticationResult = .needCustomPasscode

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.methodCalls.unlockDatabase.count, 0)
        XCTAssertEqual(appLock.methodCalls.open.count, 0)
        XCTAssertEqual(presenter.results, [.customPasscodeNeeded])
    }

    // @SF.Locking @SF.Storage @TSFI.UserInterface @S0.1
    func test_EvaluateAuthentication_Unavailable() {
        // Given
        session.lock = .screen
        appLock._authenticationResult = .unavailable

        // When
        sut.executeRequest(.evaluateAuthentication)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // Then
        XCTAssertEqual(session.methodCalls.unlockDatabase.count, 0)
        XCTAssertEqual(appLock.methodCalls.open.count, 0)
        XCTAssertEqual(presenter.results, [.authenticationUnavailable])
    }

    // MARK: - Open app lock

    func test_ItOpensAppLock() {
        // When
        sut.executeRequest(.openAppLock)

        // Then
        XCTAssertEqual(appLock.methodCalls.open.count, 1)
    }

}
