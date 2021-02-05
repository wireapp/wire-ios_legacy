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

    // MARK: - Handle result

    func test_CustomPasscodeCreationNeeded_InformingUserOfConfigChange() {
        // When
        sut.handle(result: .customPasscodeCreationNeeded(shouldInform: true))

        // Then
        XCTAssertEqual(router.actions, [.createPasscode(shouldInform: true)])
    }

    func test_CustomPasscodeCreationNeeded_WithoutInformingUserOfConfigChange() {
        // When
        sut.handle(result: .customPasscodeCreationNeeded(shouldInform: false))

        // Then
        XCTAssertEqual(router.actions, [.createPasscode(shouldInform: false)])
    }

    func test_ReadyForAuthentication_InformingUserOfConfigChange() {
        // When
        sut.handle(result: .readyForAuthentication(shouldInform: true))

        // Then
        XCTAssertEqual(router.actions, [.informUserOfConfigChange])
    }

    func test_ReadyForAuthentication_WithoutInformingUserOfConfigChange() {
        // When
        sut.handle(result: .readyForAuthentication(shouldInform: false))

        // Then
        XCTAssertEqual(view.models, [.authenticating])
        XCTAssertEqual(interactor.requests, [.evaluateAuthentication])
    }

    func test_CustomPasscodeNeeded() {
        // When
        sut.handle(result: .customPasscodeNeeded)

        // Then
        XCTAssertEqual(view.models, [.locked(.passcode)])
        XCTAssertEqual(router.actions, [.inputPasscode])
    }

    func test_AuthenticationDenied() {
        // When
        sut.handle(result: .authenticationDenied(.faceID))

        // Then
        XCTAssertEqual(view.models, [.locked(.faceID)])
    }

    func test_AuthenticationUnavailable() {
        // When
        sut.handle(result: .authenticationUnavailable)

        // Then
        XCTAssertEqual(view.models, [.locked(.unavailable)])
    }

    // MARK: - Process Event

    func test_ViewDidLoad() {
        // When
        sut.process(event: .viewDidLoad)

        // Then
        XCTAssertEqual(interactor.requests, [.initiateAuthentication])
    }

    func test_UnlockButtonTapped() {
        // When
        sut.process(event: .unlockButtonTapped)

        // Then
        XCTAssertEqual(interactor.requests, [.initiateAuthentication])
    }

    func test_PasscodeSetupCompleted() {
        // When
        sut.process(event: .passcodeSetupCompleted)

        // Then
        XCTAssertEqual(interactor.requests, [.openAppLock])
    }

    func test_ConfigChangeAcknowledged() {
        // When
        sut.process(event: .configChangeAcknowledged)

        // Then
        XCTAssertEqual(interactor.requests, [.evaluateAuthentication])
    }

    func test_CustomPasscodeVerified() {
        // When
        sut.process(event: .customPasscodeVerified)

        // Then
        XCTAssertEqual(interactor.requests, [.openAppLock])
    }

}
