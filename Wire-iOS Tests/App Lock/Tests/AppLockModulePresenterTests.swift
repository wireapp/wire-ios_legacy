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
        sut.handle(.customPasscodeCreationNeeded(shouldInform: true))

        // Then
        XCTAssertEqual(router.modules, [.createPasscode(shouldInform: true)])
    }

    func test_PresentCreateCustomPasscode_WithoutInformingUserOfConfigChange() {
        // When
        sut.handle(.customPasscodeCreationNeeded(shouldInform: false))

        // Then
        XCTAssertEqual(router.modules, [.createPasscode(shouldInform: false)])
    }

    func test_ItOpensAppLock_AfterPasscodeIsCreated() {
        // Given
        sut.handle(.customPasscodeCreationNeeded(shouldInform: false))
        let onPasscodeCreated = router.completions[0]

        // when
        onPasscodeCreated()

        // Then
        XCTAssertEqual(interactor.requests, [.openAppLock])
    }

    // MARK: - Proceed with authentication

    func test_ProceedWithAuthentication_InformingUserOfConfigChange() {
        // When
        sut.handle(.readyForAuthentication(shouldInform: true))

        // Then
        XCTAssertEqual(router.modules, [.informUserOfConfigChange])

        let completion = router.completions[0]
        completion()

        XCTAssertEqual(view.methodCalls.refresh, [.authenticating])
        XCTAssertEqual(interactor.requests, [.evaluateAuthentication])
    }

    func test_ProceedWithAuthentication_WithoutInformingUserOfConfigChange() {
        // When
        sut.handle(.readyForAuthentication(shouldInform: false))

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.authenticating])
        XCTAssertEqual(interactor.requests, [.evaluateAuthentication])
    }

    // MARK: - Authentication evaluated

    func test_ItSetsTheViewStateToLocked_WhenAuthenticationDenied() {
        // Given
        interactor.currentAuthenticationType = .faceID
        
        // When
        sut.handle(.authenticationDenied)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.locked(.faceID)])
    }

    func test_ItRequestsToInputPasscode_WhenPasscodeIsNeeded() {
        // When
        sut.handle(.customPasscodeNeeded)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.locked(.passcode)])
        XCTAssertEqual(router.modules, [.inputPasscode])

        let onGranted = router.completions[0]
        onGranted()

        XCTAssertEqual(interactor.requests, [.openAppLock])
    }

    func test_ItUpdatesViewState_WhenAuthenticationMethodUnavailable() {
        // When
        sut.handle(.authenticationUnavailable)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.locked(.unavailable)])
    }

    // MARK: - Process Event

    func test_InitiateAuthentication_AndRefreshView_WhenViewLoads() {
        // Given
        interactor.currentAuthenticationType = .faceID

        // When
        sut.processEvent(.viewDidLoad)

        // Then
        XCTAssertEqual(view.methodCalls.refresh, [.locked(.faceID)])
        XCTAssertEqual(interactor.requests, [.initiateAuthentication])
    }

    func test_InitiateAuthentication_WhenUnlockButtonTapped() {
        // When
        sut.processEvent(.unlockButtonTapped)

        // Then
        XCTAssertEqual(interactor.requests, [.initiateAuthentication])
    }

}
