//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
    
    func dismissUnlockScreen() {
        // no-op
    }
    
    var passwordInput: String?
    var requestPasswordMessage: String?
    var presentCreatePasscodeScreenCalled: Bool = false
    var presentWarningScreenCalled: Bool = false

    var presentUnlockScreenCalled: Bool = false
    func presentUnlockScreen(with message: String,
                             callback: @escaping RequestPasswordController.Callback) {
        requestPasswordMessage = message
        callback(passwordInput)
        presentUnlockScreenCalled = true
    }
    
    func presentCreatePasscodeScreen(callback: ResultHandler?) {
        presentCreatePasscodeScreenCalled = true
        callback?(true)
    }
    
    func presentWarningScreen(completion: Completion?) {
        presentWarningScreenCalled = true
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
    var needsToCreateCustomPasscode: Bool = false
    var isCustomPasscodeNotSet: Bool = false
    var _isAuthenticationNeeded: Bool = false
    var didCallIsAuthenticationNeeded: Bool = false
    var isAuthenticationNeeded: Bool {
        didCallIsAuthenticationNeeded = true
        return _isAuthenticationNeeded
    }
    var isDimmingScreenWhenInactive: Bool = true
    
    var passwordToVerify: String?
    var customPasscodeToVerify: String?
    
    var needsToNotifyUser: Bool = false

    var lastUnlockedDate: Date = Date()

    func verify(password: String) {
        passwordToVerify = password
    }
    
    func verify(customPasscode: String) {
        customPasscodeToVerify = customPasscode
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
    private var sut: AppLockPresenter!
    private var userInterface: AppLockUserInterfaceMock!
    private var appLockInteractor: AppLockInteractorMock!
    
    override func setUp() {
        super.setUp()
        userInterface = AppLockUserInterfaceMock()
        appLockInteractor = AppLockInteractorMock()
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor)
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
        sut.authenticationEvaluated(with: .needCustomPasscode)
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
        sut.authenticationEvaluated(with: .needCustomPasscode)

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
        appLockInteractor.isDimmingScreenWhenInactive = true
        //when
        sut.applicationWillResignActive()
        //then
        assert(contentsDimmed: true, reauthVisibile: nil)
    }
    
    func testThatApplicationWillResignActiveDoesntDimContentsIfAppLockNotActive() {
        //given
        appLockInteractor.isDimmingScreenWhenInactive = false
        //when
        sut.applicationWillResignActive()
        //then
        assert(contentsDimmed: nil, reauthVisibile: nil)
    }
    
    func testThatApplicationDidEnterBackgroundUpdatesLastUnlockedDateIfAuthenticated() {
        //given
        appLockInteractor.lastUnlockedDate = Date()
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .authenticated)
        //when
        sut.applicationDidEnterBackground()
        //then
        XCTAssertTrue(Date() > appLockInteractor.lastUnlockedDate)
    }
    
    func testThatApplicationDidEnterBackgroundDoenstUpdateLastUnlockDateIfNotAuthenticated() {
        //given
        let date = Date()
        appLockInteractor.lastUnlockedDate = date
        
        //given
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .cancelled)
        //when
        sut.applicationDidEnterBackground()
        //then
        XCTAssertEqual(date, appLockInteractor.lastUnlockedDate)
        
        //given
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .needed)
        //when
        sut.applicationDidEnterBackground()
        //then
        XCTAssertEqual(date, appLockInteractor.lastUnlockedDate)
        
        //given
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .pendingPassword)
        //when
        sut.applicationDidEnterBackground()
        //then
        XCTAssertEqual(date, appLockInteractor.lastUnlockedDate)
    }
    
    func testThatApplicationDidEnterBackgroundDimsContentIfAppLockActive() {
        //given
        appLockInteractor.isDimmingScreenWhenInactive = true
        //when
        sut.applicationDidEnterBackground()
        //then
        assert(contentsDimmed: true, reauthVisibile: nil)
    }
    
    func testThatApplicationDidEnterBackgroundDoesntDimContentsIfAppLockNotActive() {
        //given
        appLockInteractor.isDimmingScreenWhenInactive = false
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
        let appState = AppState.authenticated(completedRegistration: true, isDatabaseLocked: false)
        //when
        sut.appStateDidTransition(notification(for: appState))
        //then
        XCTAssertNotNil(appLockInteractor.appState)
        XCTAssertEqual(appLockInteractor.appState, appState)
    }
    
    func testThatAppStateDidTransitionToAuthenticatedAsksIfApplockIsNeeded() {
        //given
        let appState = AppState.authenticated(completedRegistration: true, isDatabaseLocked: false)
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
        sut.appStateDidTransition(notification(for: AppState.jailbroken))
        //then
        assert(contentsDimmed: false, reauthVisibile: false)
    }
    
    //MARK: - custom app lock
    func testThatUpdateFromAnOldVersionToNewVersionSupportAppLockShowsCreatePasscodeScreen() {
        //GIVEN
        appLockInteractor.isCustomPasscodeNotSet = true
        
        //WHEN
        sut.authenticationEvaluated(with: .needCustomPasscode)

        //THEN
        XCTAssert( userInterface.presentCreatePasscodeScreenCalled)
        
    }

    func testThatAppLockDoesNotShowIfIsCustomPasscodIsSet() {
        //GIVEN
        appLockInteractor.isCustomPasscodeNotSet = false
        
        //WHEN
        sut.authenticationEvaluated(with: .needCustomPasscode)
        
        //THEN
        XCTAssertFalse( userInterface.presentCreatePasscodeScreenCalled)
        
    }
    
     //MARK: - warning screen
    func testThatAppLockShowsWarningScreen_IfNeedsToNotifyUserIsTrue() {
        //given
        set(authNeeded: true, authenticationState: .authenticated)
        appLockInteractor.needsToNotifyUser = true
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertTrue(userInterface.presentWarningScreenCalled)
    }
    
    func testThatAppLockDoesNotShowWarningScreen_IfNeedsToNotifyUserIsFalse() {
        //given
        set(authNeeded: true, authenticationState: .authenticated)
        appLockInteractor.needsToNotifyUser = false
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertFalse(userInterface.presentWarningScreenCalled)
    }

    // MARK: - Require authentication

    func testThatIt_AsksToCreateCustomPasscode() {
        // Given
        appLockInteractor._isAuthenticationNeeded = true
        appLockInteractor.needsToCreateCustomPasscode = true

        // When
        sut.requireAuthentication()

        // Then
        XCTAssertTrue(userInterface.presentCreatePasscodeScreenCalled)
    }

    func testThatIt_ResetsNeedsToNotifyUserFlag_AfterDisplayingCreatePasscodeScreen() {
        // Given
        appLockInteractor._isAuthenticationNeeded = true
        appLockInteractor.needsToNotifyUser = true
        appLockInteractor.needsToCreateCustomPasscode = true

        // When
        sut.requireAuthentication()

        // Then
        XCTAssertTrue(userInterface.presentCreatePasscodeScreenCalled)
        XCTAssertFalse(appLockInteractor.needsToNotifyUser)
    }

    func testThatIt_AsksToEvaluateAuthentication() {
        // Given
        appLockInteractor._isAuthenticationNeeded = true
        appLockInteractor.needsToCreateCustomPasscode = false

        // When
        sut.requireAuthentication()

        // Then
        XCTAssertTrue(appLockInteractor.didCallEvaluateAuthentication)
    }
    
    // Mark: - Creating passcode
    
    func testThatItUnlocksAppAfterCreatingAPasscode() {
        // Given
        set(authNeeded: true, authenticationState: .needed)
        appLockInteractor.needsToCreateCustomPasscode = true
        
        // When
        sut.requireAuthenticationIfNeeded()
        
        // Then
        XCTAssertTrue(userInterface.presentCreatePasscodeScreenCalled)
        XCTAssertEqual(userInterface.contentsDimmed, false)
    }

}

extension AppLockPresenterTests {
    func notification(for appState: AppState) -> Notification {
        return Notification(name: AppRootRouter.appStateDidTransition,
                            object: nil,
                            userInfo: [AppRootRouter.appStateKey: appState])
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
            XCTAssertEqual(self.userInterface.passwordInput, self.appLockInteractor.customPasscodeToVerify)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
    }
}
