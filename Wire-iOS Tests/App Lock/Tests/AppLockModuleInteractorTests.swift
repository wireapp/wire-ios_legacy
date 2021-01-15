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
    
    override func setUp() {
        super.setUp()
        session = AppLockModule.MockSession()
        appLock = AppLockModule.MockAppLockController()
        presenter = AppLockModule.MockPresenter()

        session.appLockController = appLock

        sut = AppLockModule.Interactor(session: session)
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

}
