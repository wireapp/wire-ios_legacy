//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import XCTest
import WireSyncEngine
import LocalAuthentication
@testable import Wire
@testable import WireCommonComponents

private final class AppLockInteractorOutputMock: AppLockInteractorOutput {
    
    var authenticationResult: AppLock.AuthenticationResult?
    func authenticationEvaluated(with result: AppLock.AuthenticationResult) {
        authenticationResult = result
    }
    
    var passwordVerificationResult: VerifyPasswordResult?
    func passwordVerified(with result: VerifyPasswordResult?) {
        passwordVerificationResult = result
    }
}

private final class UserSessionMock: AppLockInteractorUserSession {
    var encryptMessagesAtRest: Bool = false
    
    var isDatabaseLocked: Bool = false
    
    func unlockDatabase(with context: LAContext) throws {
        isDatabaseLocked = false
    }
    
    func registerDatabaseLockedHandler(_ handler: @escaping (Bool) -> Void) -> Any {
        return "token"
    }
    
    var result: VerifyPasswordResult? = .denied
    func verify(password: String, completion: @escaping (VerifyPasswordResult?) -> Void) {
        completion(result)
    }
}

private final class AppLockMock: AppLock {
    static var authenticationResult: AuthenticationResult = .granted

    override final class func evaluateAuthentication(scenario: AuthenticationScenario, description: String, with callback: @escaping (AuthenticationResult, LAContext) -> Void) {
        callback(authenticationResult, LAContext())
    }
    
    static var didPersistBiometrics: Bool = false
    override final class func persistBiometrics() {
        didPersistBiometrics = true
    }
}

final class AppLockInteractorTests: XCTestCase {
    var sut: AppLockInteractor!
    private var appLockInteractorOutputMock: AppLockInteractorOutputMock!
    private var userSessionMock: UserSessionMock!
    
    override func setUp() {
        super.setUp()
        appLockInteractorOutputMock = AppLockInteractorOutputMock()
        userSessionMock = UserSessionMock()
        sut = AppLockInteractor()
        sut._userSession = userSessionMock
        sut.output = appLockInteractorOutputMock
        sut.appLock = AppLockMock.self
    }
    
    override func tearDown() {
        appLockInteractorOutputMock = nil
        sut = nil
        super.tearDown()
    }
    
    func testThatIsDimmingScreenWhenInactiveReturnsTrueWhenAppLockIsActive() {
        //given
        set(appLockActive: true, timeoutReached: false, authenticatedAppState: true, databaseIsLocked: false)
        
        //when / then
        XCTAssertTrue(sut.isDimmingScreenWhenInactive)
    }
    
    func testThatIsDimmingScreenWhenInactiveReturnsTrueWhenEncryptionAtRestIsEnabled() {
        //given
        set(appLockActive: false, timeoutReached: false, authenticatedAppState: true, databaseIsLocked: false)
        userSessionMock.encryptMessagesAtRest = true
        
        //when / then
        XCTAssertTrue(sut.isDimmingScreenWhenInactive)
    }
    
    func testThatIsDimmingScreenWhenInactiveReturnsFalseWhenAppLockIsInactive() {
        //given
        set(appLockActive: false, timeoutReached: false, authenticatedAppState: true, databaseIsLocked: false)
        
        //when / then
        XCTAssertFalse(sut.isDimmingScreenWhenInactive)
    }
    
    
    func testThatIsAuthenticationNeededReturnsTrueIfNeeded() {
        //given
        set(appLockActive: true, timeoutReached: true, authenticatedAppState: true, databaseIsLocked: false)
        
        //when / then
        XCTAssertTrue(sut.isAuthenticationNeeded)
    }
    
    func testThatIsAuthenticationNeededReturnsTrueIfDatabaseIsLocked() {
        //given
        set(appLockActive: false, timeoutReached: false, authenticatedAppState: true, databaseIsLocked: true)
        
        //when / then
        XCTAssertTrue(sut.isAuthenticationNeeded)
    }
    
    func testThatIsAuthenticationNeededReturnsFalseIfTimeoutNotReached() {
        //given
        set(appLockActive: true, timeoutReached: false, authenticatedAppState: true, databaseIsLocked: false)
        
        //when / then
        XCTAssertFalse(sut.isAuthenticationNeeded)
    }
    
    func testThatIsAuthenticationNeededReturnsFalseIfAppLockNotActive() {
        //given - appLock not active
        set(appLockActive: false, timeoutReached: true, authenticatedAppState: true, databaseIsLocked: false)
        
        //when / then
        XCTAssertFalse(sut.isAuthenticationNeeded)
    }
    
    func testThatIsAuthenticationNeededReturnsFalseIfAppStateNotAuthenticated() {
        //given
        set(appLockActive: true, timeoutReached: true, authenticatedAppState: false, databaseIsLocked: false)
        
        //when / then
        XCTAssertFalse(sut.isAuthenticationNeeded)
    }
    
    func testThatEvaluateAuthenticationCompletesWithCorrectResult() {
        //given
        let queue = DispatchQueue.main
        sut.dispatchQueue = queue
        AppLockMock.authenticationResult = .granted
        appLockInteractorOutputMock.authenticationResult = nil
        let expectation = XCTestExpectation(description: "evaluate authentication")

        //when
        sut.evaluateAuthentication(description: "")

        //then
        queue.async {
            XCTAssertNotNil(self.appLockInteractorOutputMock.authenticationResult)
            XCTAssertEqual(self.appLockInteractorOutputMock.authenticationResult, AppLockMock.authenticationResult)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testThatItNotifiesOutputWhenPasswordWasVerified() {
        //given
        let queue = DispatchQueue.main
        sut.dispatchQueue = queue
        userSessionMock.result = .denied
        appLockInteractorOutputMock.passwordVerificationResult = nil
        let expectation = XCTestExpectation(description: "verify password")
        
        //when
        sut.verify(password: "")
        
        //then
        queue.async {
            XCTAssertNotNil(self.appLockInteractorOutputMock.passwordVerificationResult)
            XCTAssertEqual(self.appLockInteractorOutputMock.passwordVerificationResult, VerifyPasswordResult.denied)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testThatItPersistsBiometricsWhenPasswordIsValid() {
        //given
        userSessionMock.result = .validated

        //when
        sut.verify(password: "")
        
        //then
        XCTAssertTrue(AppLockMock.didPersistBiometrics)
    }
    
    func testThatItDoesntPersistBiometricsWhenPasswordIsInvalid() {
        //given
        userSessionMock.result = .denied
        
        //when
        sut.verify(password: "")

        //then
        XCTAssertFalse(AppLockMock.didPersistBiometrics)
    }
    
    func testThatAppStateDidTransitionToNewAppStateUpdatesAppState() {
        //given
        sut.appState = nil
        let appState = AppState.authenticated(completedRegistration: false, databaseIsLocked: false)
        //when
        sut.appStateDidTransition(to: appState)
        //the
        XCTAssertEqual(sut.appState, appState)
    }
    
    func testThatStateChangeFromUnauthenticatedToAuthenticationUpdatesLastUnlockedDate() {
        //given
        AppLock.lastUnlockedDate = Date(timeIntervalSince1970: 0)
        sut.appState = AppState.unauthenticated(error: nil)
        //when
        sut.appStateDidTransition(to: AppState.authenticated(completedRegistration: false, databaseIsLocked: false))
        //then
        XCTAssert(AppLock.lastUnlockedDate > Date(timeIntervalSince1970: 0))
    }
}

extension AppLockInteractorTests {
    func set(appLockActive: Bool, timeoutReached: Bool, authenticatedAppState: Bool, databaseIsLocked: Bool) {
        AppLock.isActive = appLockActive
        AppLock.rules = AppLockRules(useBiometricsOrAccountPassword: false, useCustomCodeInsteadOfAccountPassword: false, forceAppLock: false, appLockTimeout: 900)
        let timeInterval = timeoutReached ? -Double(AppLock.rules.appLockTimeout)-100 : -10
        AppLock.lastUnlockedDate = Date(timeIntervalSinceNow: timeInterval)
        sut.appState = authenticatedAppState ? AppState.authenticated(completedRegistration: false, databaseIsLocked: databaseIsLocked) : AppState.unauthenticated(error: nil)
    }
}
