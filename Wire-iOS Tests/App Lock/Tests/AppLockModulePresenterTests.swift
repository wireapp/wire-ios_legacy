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

    // MARK: - Create custom passcode

    func test_PresentCreateCustomPasscode_InformingUserOfConfigChange() {
        // When
        sut.handle(result: .customPasscodeCreationNeeded(shouldInform: true))

        // Then
        XCTAssertEqual(router.actions, [.createPasscode(shouldInform: true)])
    }

    func test_PresentCreateCustomPasscode_WithoutInformingUserOfConfigChange() {
        // When
        sut.handle(result: .customPasscodeCreationNeeded(shouldInform: false))

        // Then
        XCTAssertEqual(router.actions, [.createPasscode(shouldInform: false)])
    }

    // MARK: - Proceed with authentication

    func test_ProceedWithAuthentication_InformingUserOfConfigChange() {
        // When
        sut.handle(result: .readyForAuthentication(shouldInform: true))

        // Then
        XCTAssertEqual(router.actions, [.informUserOfConfigChange])
    }

    func test_ProceedWithAuthentication_WithoutInformingUserOfConfigChange() {
        // When
        sut.handle(result: .readyForAuthentication(shouldInform: false))

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.authenticating])
        XCTAssertEqual(interactor.requests, [.evaluateAuthentication])
    }

    // MARK: - Authentication evaluated

    func test_ItSetsTheViewStateToLocked_WhenAuthenticationDenied() {
        // When
        sut.handle(result: .authenticationDenied(.faceID))

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.locked(.faceID)])
    }

    func test_ItRequestsToInputPasscode_WhenPasscodeIsNeeded() {
        // When
        sut.handle(result: .customPasscodeNeeded)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.locked(.passcode)])
        XCTAssertEqual(router.actions, [.inputPasscode])
    }

    func test_ItUpdatesViewState_WhenAuthenticationMethodUnavailable() {
        // When
        sut.handle(result: .authenticationUnavailable)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.locked(.unavailable)])
    }

    // MARK: - Process Event

    func test_InitiateAuthentication_AndRefreshView_WhenViewLoads() {
        // Given
        interactor.currentAuthenticationType = .faceID

        // When
        sut.process(event: .viewDidLoad)

        // Then
        XCTAssertEqual(interactor.requests, [.initiateAuthentication])
    }

    func test_InitiateAuthentication_WhenUnlockButtonTapped() {
        // When
        sut.process(event: .unlockButtonTapped)

        // Then
        XCTAssertEqual(interactor.requests, [.initiateAuthentication])
    }

    func test_ItOpensAppLock_AfterPasscodeIsCreated() {
        // When
        sut.process(event: .passcodeSetupCompleted)

        // Then
        XCTAssertEqual(interactor.requests, [.openAppLock])
    }

    func test_EvaluatesAuthentication_WhenConfigChangeIsAcknowledged() {
        // When
        sut.process(event: .configChangeAcknowledged)

        // Then
        XCTAssertEqual(interactor.requests, [.evaluateAuthentication])
    }

    func test_OpenAppLock_WhenCustomPasscodeIsVerified() {
        // When
        sut.process(event: .customPasscodeVerified)

        // Then
        XCTAssertEqual(interactor.requests, [.openAppLock])
    }

}
