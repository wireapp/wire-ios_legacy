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

extension AppLockModule {

    final class InteractorTests: XCTestCase {

        private var sut: Interactor!
        private var presenter: MockPresenter!
        private var session: MockSession!
        private var appLock: MockAppLockController!

        override func setUp() {
            super.setUp()
            session = MockSession()
            appLock = MockAppLockController()
            session.appLockController = appLock
            presenter = MockPresenter()
            sut = Interactor(session: session)
            sut.presenter = presenter
        }

        override func tearDown() {
            sut = nil
            presenter = nil
            session = nil
            appLock = nil
            super.tearDown()
        }

        // MARK: - Evaluate authentication

        func test_DatabaseIsUnlocked_IfAuthenticationIsSuccessful() {
            // Given
            appLock._authenticationResult = .granted

            // When
            sut.evaluateAuthentication()

            // Then
            XCTAssertEqual(session.methodCalls.unlockDatabase.count, 1)
        }

        func test_DatabaseIsNotUnlocked_IfAuthenticationIsNotSuccessful() {
            // Given
            let authenticationResults: [AuthenticationResult] = [
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
            let authenticationResults: [AuthenticationResult] = [
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

    }

}

