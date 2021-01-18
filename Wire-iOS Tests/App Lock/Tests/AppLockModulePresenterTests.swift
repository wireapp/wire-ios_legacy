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
        sut = AppLockModule.Presenter()
        router = AppLockModule.MockRouter()
        interactor = AppLockModule.MockInteractor()
        view = AppLockModule.MockView()

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

    // MARK: - Start

    func test_ItRequestsToCustomPasscode_WhenItStarts() {
        // Given
        interactor.needsToCreateCustomPasscode = true

        // When
        sut.start()

        // Then
        XCTAssertEqual(router.methodCalls.presentCreatePasscodeModule.count, 1)

        let completion = router.methodCalls.presentCreatePasscodeModule[0]
        completion()

        XCTAssertEqual(interactor.methodCalls.openAppLock.count, 1)
    }

    func test_ItRequestsToEvaluateAuthentication_WhenItStarts() {
        // Given
        interactor.needsToCreateCustomPasscode = false

        // When
        sut.start()

        // Then
        XCTAssertEqual(view.propertyCalls.state, [.authenticating])
        XCTAssertEqual(interactor.methodCalls.evaluateAuthentication.count, 1)
    }

    // MARK: - Authentication evaluated

    func test_ItRequestToShowTheAuthenticationButton_WhenAuthenticationDenied() {
        // When
        sut.authenticationEvaluated(with: .denied)

        // Then
        XCTAssertEqual(view.propertyCalls.state, [.locked])
    }

}
