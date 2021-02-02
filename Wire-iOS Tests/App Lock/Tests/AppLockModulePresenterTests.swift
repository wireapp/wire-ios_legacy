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

final class AppLockModulePresenterTests: XCTestCase {

    private var sut: AppLockModule.Presenter!
    private var router: AppLockModule.MockRouter!
    private var interactor: AppLockModule.MockInteractor!
    private var view: AppLockModule.MockView!

    override func setUp() {
        super.setUp()
        sut = .init()
        router = .init()
        interactor = .init()
        view = .init()

        sut.router = router
        sut.interactor = interactor
        sut.view = view
    }

    override func tearDown() {
        sut = nil
        router = nil
        interactor = nil
        view = nil
        super.tearDown()
    }

    // MARK: - Process Event

    func test_ItRequestsToEvaluateAuthentication_WhenViewLoads() {
        // Given
        interactor.needsToCreateCustomPasscode = false
        interactor.currentAuthenticationType = .faceID

        // When
        sut.processEvent(.viewDidLoad)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.locked(.faceID), .authenticating])
        XCTAssertEqual(interactor.methodCalls.evaluateAuthentication.count, 1)
    }

    func test_ItRequestsToEvaluateAuthentication_WhenUnlockButtonTapped() {
        // Given
        interactor.needsToCreateCustomPasscode = false

        // When
        sut.processEvent(.unlockButtonTapped)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.authenticating])
        XCTAssertEqual(interactor.methodCalls.evaluateAuthentication.count, 1)
    }

    // MARK: - Create custom passcode

    func test_ItRequestsToCreateCustomPasscode() {
        // Given
        interactor.needsToCreateCustomPasscode = true
        interactor.needsToInformUserOfConfigurationChange = false

        // When
        sut.processEvent(.unlockButtonTapped)

        // Then
        XCTAssertEqual(router.methodCalls.presentCreatePasscodeModule.count, 1)
        XCTAssertEqual(router.methodCalls.presentCreatePasscodeModule[0].shouldInform, false)
    }

    func test_ItRequestsToCreateCustomPasscode_DueToConfigurationChange() {
        // Given
        interactor.needsToCreateCustomPasscode = true
        interactor.needsToInformUserOfConfigurationChange = true

        // When
        sut.processEvent(.unlockButtonTapped)

        // Then
        XCTAssertEqual(router.methodCalls.presentCreatePasscodeModule.count, 1)
        XCTAssertEqual(router.methodCalls.presentCreatePasscodeModule[0].shouldInform, true)
    }

    func test_ItOpensAppLock_AfterPasscodeIsCreated() {
        // Given
        interactor.needsToCreateCustomPasscode = true
        interactor.needsToInformUserOfConfigurationChange = false

        sut.processEvent(.unlockButtonTapped)

        let onPasscodeCreated = router.methodCalls.presentCreatePasscodeModule[0].completion

        // when
        onPasscodeCreated()

        // Then
        XCTAssertEqual(interactor.methodCalls.openAppLock.count, 1)
    }

    // MARK: - Request authentication

    func test_ItRequestsToEvaluateAuthentication() {
        // Given
        interactor.needsToCreateCustomPasscode = false

        // When
        sut.processEvent(.unlockButtonTapped)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.authenticating])
        XCTAssertEqual(interactor.methodCalls.evaluateAuthentication.count, 1)
    }

    func test_ItPresentsWarningModuleBeforeAuthenticating() {
        // Given
        interactor.needsToInformUserOfConfigurationChange = true

        // When
        sut.processEvent(.unlockButtonTapped)

        // Then
        XCTAssertEqual(router.methodCalls.presentWarningModule.count, 1)
        XCTAssertEqual(view.methodCalls.refresh.count, 0)
        XCTAssertEqual(interactor.methodCalls.evaluateAuthentication.count, 0)

        let completion = router.methodCalls.presentWarningModule[0]
        completion()

        XCTAssertEqual(view.methodCalls.refresh, [.authenticating])
        XCTAssertEqual(interactor.methodCalls.evaluateAuthentication.count, 1)
    }

    // MARK: - Authentication evaluated

    func test_ItRequestToOpenAppLock_WhenAuthenticationGranted() {
        // When
        sut.authenticationEvaluated(with: .granted)

        // Then
        XCTAssertEqual(interactor.methodCalls.openAppLock.count, 1)
    }

    func test_ItSetsTheViewStateToLocked_WhenAuthenticationDenied() {
        // Given
        interactor.currentAuthenticationType = .faceID
        
        // When
        sut.authenticationEvaluated(with: .denied)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.locked(.faceID)])
    }

    func test_ItRequestsToInputPasscode_WhenPasscodeIsNeeded() {
        // When
        sut.authenticationEvaluated(with: .needCustomPasscode)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.locked(.passcode)])
        XCTAssertEqual(router.methodCalls.presentInputPasscodeModule.count, 1)

        let onGranted = router.methodCalls.presentInputPasscodeModule[0]
        onGranted()

        XCTAssertEqual(interactor.methodCalls.openAppLock.count, 1)
    }

    func test_ItUpdatesViewState_WhenAuthenticationMethodUnavailable() {
        // When
        sut.authenticationEvaluated(with: .unavailable)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.locked(.unavailable)])
    }

}
