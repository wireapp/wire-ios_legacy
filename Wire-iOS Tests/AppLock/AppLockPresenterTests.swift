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
@testable import Wire
@testable import WireCommonComponents

private final class AppLockUserInterfaceMock: AppLockUserInterface {
    var passwordInput: String?
    var requestPasswordMessage: String?
    func presentRequestPasswordController(with message: String, callback: @escaping RequestPasswordController.Callback) {
        requestPasswordMessage = message
        callback(passwordInput)
    }
    
    var spinnerAnimating: Bool?
    func setSpinner(animating: Bool) {
        spinnerAnimating = animating
    }
    
    var contentsDimmed: Bool?
    func setContents(dimmed: Bool) {
        contentsDimmed = dimmed
    }
    
    var reauthVisible: Bool?
    func setReauth(visible: Bool) {
        reauthVisible = visible
    }
}

private final class AppLockInteractorMock: AppLockInteractorInput {
    var _isAuthenticationNeeded: Bool = false
    var didCallIsAuthenticationNeeded: Bool = false
    var isAuthenticationNeeded: Bool {
        didCallIsAuthenticationNeeded = true
        return _isAuthenticationNeeded
    }
    
    var passwordToVerify: String?
    func verify(password: String) {
        self.passwordToVerify = password
    }
    
    var didCallEvaluateAuthentication: Bool = false
    var authDescription: String?
    func evaluateAuthentication(description: String) {
        authDescription = description
        didCallEvaluateAuthentication = true
    }
    
    var appState: AppState?
    func appStateDidTransition(to newState: AppState) {
        appState = newState
    }
}

final class AppLockPresenterTests: XCTestCase {
    var sut: AppLockPresenter!
    private var userInterface: AppLockUserInterfaceMock!
    private var appLockInteractor: AppLockInteractorMock!
    
    override func setUp() {
        super.setUp()
        userInterface = AppLockUserInterfaceMock()
        appLockInteractor = AppLockInteractorMock()
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor)
        AppLock.rules = AppLockRules(useBiometricsOrAccountPassword: true, forceAppLock: false, appLockTimeout: 1)
    }
    
    override func tearDown() {
        userInterface = nil
        appLockInteractor = nil
        sut = nil
        super.tearDown()
    }
    
    func testThatItEvaluatesAuthenticationOrUpdatesUIIfNeeded() {
        //given
        set(authNeeded: true, authenticationState: .needed)
        resetMocksValues()
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertEqual(appLockInteractor.authDescription, "self.settings.privacy_security.lock_app.description")
        XCTAssertTrue(appLockInteractor.didCallEvaluateAuthentication)
        assert(contentsDimmed: true, reauthVisibile: false)
        
        //given
        set(authNeeded: true, authenticationState: .authenticated)
        resetMocksValues()
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertTrue(appLockInteractor.didCallEvaluateAuthentication)
        assert(contentsDimmed: true, reauthVisibile: false)
    }
    
    func testThatItDoesntEvaluateAuthenticationOrUpdateUIIfNotNeeded() {
        //given
        set(authNeeded: false, authenticationState: .needed)
        resetMocksValues()
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertFalse(appLockInteractor.didCallEvaluateAuthentication)
        assert(contentsDimmed: false, reauthVisibile: false)
        
        //given
        set(authNeeded: true, authenticationState: .cancelled)
        resetMocksValues()
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertFalse(appLockInteractor.didCallEvaluateAuthentication)
        assert(contentsDimmed: true, reauthVisibile: true)
        
        //given
        set(authNeeded: true, authenticationState: .pendingPassword)
        resetMocksValues()
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertFalse(appLockInteractor.didCallEvaluateAuthentication)
        assert(contentsDimmed: nil, reauthVisibile: nil)
    }
    
    func testThatFailedAuthenticationDimsContentsWithoutReauth() {
        //when
        sut.authenticationEvaluated(with: .denied)
        //then
        assert(contentsDimmed: true, reauthVisibile: false)
        
        //given
        resetMocksValues()
        //when
        sut.authenticationEvaluated(with: .needAccountPassword)
        //then
        assert(contentsDimmed: true, reauthVisibile: false)
    }
    
    func testThatUnavailableAuthenticationDimsContentsWithReauth() {
        //when
        sut.authenticationEvaluated(with: .unavailable)
        //then
        assert(contentsDimmed: true, reauthVisibile: true)
    }
    
    func testThatGrantedAuthenticationDoesntDimContentsOrShowReauth() {
        //when
        sut.authenticationEvaluated(with: .granted)
        //then
        assert(contentsDimmed: false, reauthVisibile: false)
    }
    
    func testThatPasswordVerifiedStopsSpinner() {
        //when
        sut.passwordVerified(with: nil)
        //then
        XCTAssertNotNil(userInterface.spinnerAnimating)
        XCTAssertFalse(userInterface.spinnerAnimating ?? true)
    }
    
    func testThatPasswordVerifiedWithoutResultDimsContentsWithReauth() {
        //when
        sut.passwordVerified(with: nil)
        //then
        assert(contentsDimmed: true, reauthVisibile: true)
    }
    
    func testThatPasswordVerifiedWithValidatedResultSetContentsNotDimmed() {
        //when
        sut.passwordVerified(with: .validated)
        //then
        assert(contentsDimmed: false, reauthVisibile: false)
    }
    
    func testThatPasswordVerifiedDoesntDimContentIfAuthIsNotNeeded() {
        //given
        appLockInteractor._isAuthenticationNeeded = false
        
        //when
        sut.passwordVerified(with: .denied)
        
        //then
        assert(contentsDimmed: false, reauthVisibile: false)
    }
    
    func testThatPasswordVerifiedWithNotValidatedResultDimsContentsIfAuthNeeded() {
        //given
        appLockInteractor._isAuthenticationNeeded = true
        
        //when
        sut.passwordVerified(with: .denied)
        //then
        assert(contentsDimmed: true, reauthVisibile: false)
        
        //given
        resetMocksValues()
        //when
        sut.passwordVerified(with: .unknown)
        //then
        assert(contentsDimmed: true, reauthVisibile: false)
        
        //given
        resetMocksValues()
        //when
        sut.passwordVerified(with: .timeout)
        //then
        assert(contentsDimmed: true, reauthVisibile: false)
    }
    
    func testThatItOnlyAsksForPasswordWhenNeeded() {
        //given
        appLockInteractor._isAuthenticationNeeded = true
        //when
        sut.passwordVerified(with: .denied)
        //then
        XCTAssertNotNil(userInterface.requestPasswordMessage)
        
        //given
        userInterface.requestPasswordMessage = nil
        appLockInteractor._isAuthenticationNeeded = false
        //when
        sut.passwordVerified(with: .denied)
        //then
        XCTAssertNil(userInterface.requestPasswordMessage)
    }
    
    func testThatItVerifiesPasswordWithCorrectMessageWhenNeeded() {
        //given
        appLockInteractor._isAuthenticationNeeded = true
        let queue = DispatchQueue(label: "Password verification tests queue", qos: .background)
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor)
        sut.dispatchQueue = queue
        setupPasswordVerificationTest()

        //when
        sut.authenticationEvaluated(with: .needAccountPassword)

        //then
        assertPasswordVerification(on: queue)
        XCTAssertEqual(userInterface.requestPasswordMessage, "self.settings.privacy_security.lock_password.description.unlock")
        
        //given
        setupPasswordVerificationTest()
        
        //when
        sut.passwordVerified(with: .denied)
        
        //then
        assertPasswordVerification(on: queue)
        XCTAssertEqual(userInterface.requestPasswordMessage, "self.settings.privacy_security.lock_password.description.wrong_password")


        //given
        setupPasswordVerificationTest()
        
        //when
        sut.passwordVerified(with: .unknown)
        
        //then
        assertPasswordVerification(on: queue)
        XCTAssertEqual(userInterface.requestPasswordMessage, "self.settings.privacy_security.lock_password.description.wrong_password")
    }

    func testThatApplicationWillResignActiveDimsContentIfAppLockIsActive() {
        //given
        AppLock.isActive = true
        //when
        sut.applicationWillResignActive()
        //then
        assert(contentsDimmed: true, reauthVisibile: nil)
    }
    
    func testThatApplicationWillResignActiveDoesntDimContentsIfAppLockNotActive() {
        //given
        AppLock.isActive = false
        //when
        sut.applicationWillResignActive()
        //then
        assert(contentsDimmed: nil, reauthVisibile: nil)
    }
    
    func testThatApplicationDidEnterBackgroundUpdatesLastUnlockedDateIfAuthenticated() {
        //given
        AppLock.lastUnlockedDate = Date()
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .authenticated)
        //when
        sut.applicationDidEnterBackground()
        //then
        XCTAssertTrue(Date() > AppLock.lastUnlockedDate)
    }
    
    func testThatApplicationDidEnterBackgroundDoenstUpdateLastUnlockDateIfNotAuthenticated() {
        //given
        let date = Date()
        AppLock.lastUnlockedDate = date
        
        //given
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .cancelled)
        //when
        sut.applicationDidEnterBackground()
        //then
        XCTAssertEqual(date, AppLock.lastUnlockedDate)
        
        //given
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .needed)
        //when
        sut.applicationDidEnterBackground()
        //then
        XCTAssertEqual(date, AppLock.lastUnlockedDate)
        
        //given
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .pendingPassword)
        //when
        sut.applicationDidEnterBackground()
        //then
        XCTAssertEqual(date, AppLock.lastUnlockedDate)
    }
    
    func testThatApplicationDidEnterBackgroundDimsContentIfAppLockActive() {
        //given
        AppLock.isActive = true
        //when
        sut.applicationDidEnterBackground()
        //then
        assert(contentsDimmed: true, reauthVisibile: nil)
    }
    
    func testThatApplicationDidEnterBackgroundDoesntDimContentsIfAppLockNotActive() {
        //given
        AppLock.isActive = false
        //when
        sut.applicationDidEnterBackground()
        //then
        assert(contentsDimmed: nil, reauthVisibile: nil)
    }
    
    func testThatApplicationDidBecomeActiveRequireAuthenticationIfNeeded() {
        //when
        sut.applicationDidBecomeActive()
        //then
        XCTAssertTrue(appLockInteractor.didCallIsAuthenticationNeeded)
    }
    
    func testThatAppStateDidTransitionNotifiesInteractorWithState() {
        //given
        let appState = AppState.authenticated(completedRegistration: true, databaseIsLocked: false)
        //when
        sut.appStateDidTransition(notification(for: appState))
        //then
        XCTAssertNotNil(appLockInteractor.appState)
        XCTAssertEqual(appLockInteractor.appState, appState)
    }
    
    func testThatAppStateDidTransitionToAuthenticatedAsksIfApplockIsNeeded() {
        //given
        let appState = AppState.authenticated(completedRegistration: true, databaseIsLocked: false)
        //when
        sut.appStateDidTransition(notification(for: appState))
        //then
        XCTAssertTrue(appLockInteractor.didCallIsAuthenticationNeeded)
    }
    
    func testThatAppStateDidTransitionToNotAuthenticatedRevealsContent() {
        //when
        sut.appStateDidTransition(notification(for: AppState.unauthenticated(error: nil)))
        //then
        assert(contentsDimmed: false, reauthVisibile: false)

        //when
        sut.appStateDidTransition(notification(for: AppState.headless))
        //then
        assert(contentsDimmed: false, reauthVisibile: false)
        
        //when
        sut.appStateDidTransition(notification(for: AppState.migrating))
        //then
        assert(contentsDimmed: false, reauthVisibile: false)
        
        //when
        sut.appStateDidTransition(notification(for: AppState.blacklisted(jailbroken: true)))
        //then
        assert(contentsDimmed: false, reauthVisibile: false)
    }
}

extension AppLockPresenterTests {
    func notification(for appState: AppState) -> Notification {
        return Notification(name: AppStateController.appStateDidTransition,
                            object: nil,
                            userInfo: [AppStateController.appStateKey: appState])
    }
    
    func set(authNeeded: Bool, authenticationState: AuthenticationState) {
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: authenticationState)
        appLockInteractor._isAuthenticationNeeded = authNeeded
    }
    
    func resetMocksValues() {
        userInterface.contentsDimmed = nil
        userInterface.reauthVisible = nil
        userInterface.spinnerAnimating = nil
        appLockInteractor.didCallEvaluateAuthentication = false
    }
    
    func setupPasswordVerificationTest() {
        userInterface.passwordInput = "password"
        appLockInteractor.passwordToVerify = nil
        userInterface.requestPasswordMessage = nil
    }
    
    func assert(contentsDimmed: Bool?, reauthVisibile: Bool?) {
        XCTAssertEqual(userInterface.contentsDimmed, contentsDimmed)
        XCTAssertEqual(userInterface.reauthVisible, reauthVisibile)
    }
    
    func assertPasswordVerification(on queue: DispatchQueue) {
        let expectation = XCTestExpectation(description: "verify password")
        
        queue.async {
            XCTAssertEqual(self.userInterface.passwordInput, self.appLockInteractor.passwordToVerify)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
    }
}
