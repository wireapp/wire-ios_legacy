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
    var didCallIsAuthenticationNeeded: Bool = false
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
    private var sut: OldAppLockPresenter!
    private var userInterface: AppLockUserInterfaceMock!
    private var appLockInteractor: AppLockInteractorMock!
    
    override func setUp() {
        super.setUp()
        userInterface = AppLockUserInterfaceMock()
        appLockInteractor = AppLockInteractorMock()
        sut = OldAppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor)
    }
    
    override func tearDown() {
        userInterface = nil
        appLockInteractor = nil
        sut = nil
        super.tearDown()
    }
    
    func testThatItEvaluatesAuthenticationOrUpdatesUIIfNeeded() {
        //given
        set(authenticationState: .needed)
        resetMocksValues()
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertEqual(appLockInteractor.authDescription, "self.settings.privacy_security.lock_app.description")
        XCTAssertTrue(appLockInteractor.didCallEvaluateAuthentication)
        assert(reauthVisibile: false)
        
        //given
        set(authenticationState: .authenticated)
        resetMocksValues()
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertTrue(appLockInteractor.didCallEvaluateAuthentication)
        assert(reauthVisibile: false)
    }
    
    func testThatItDoesntEvaluateAuthenticationOrUpdateUIIfNotNeeded() {
        //given
        set(authenticationState: .cancelled)
        resetMocksValues()
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertFalse(appLockInteractor.didCallEvaluateAuthentication)
        assert(reauthVisibile: true)
        
        //given
        set(authenticationState: .pendingPassword)
        resetMocksValues()
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertFalse(appLockInteractor.didCallEvaluateAuthentication)
        assert(reauthVisibile: nil)
    }
    
    func testThatUnavailableAuthenticationDimsContentsWithReauth() {
        //when
        sut.authenticationEvaluated(with: .unavailable)
        //then
        assert(reauthVisibile: true)
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
        assert(reauthVisibile: true)
    }
    
    func testThatPasswordVerifiedWithValidatedResultSetContentsNotDimmed() {
        //when
        sut.passwordVerified(with: .validated)
        //then
        assert(reauthVisibile: false)
    }

    func testThatPasswordVerifiedWithNotValidatedResultDimsContentsIfAuthNeeded() {
        //when
        sut.passwordVerified(with: .denied)
        //then
        assert(reauthVisibile: false)
        
        //given
        resetMocksValues()
        //when
        sut.passwordVerified(with: .unknown)
        //then
        assert(reauthVisibile: false)
        
        //given
        resetMocksValues()
        //when
        sut.passwordVerified(with: .timeout)
        //then
        assert(reauthVisibile: false)
    }
    
    func testThatItOnlyAsksForPasswordWhenNeeded() {
        //when
        sut.passwordVerified(with: .denied)
        //then
        XCTAssertNotNil(userInterface.requestPasswordMessage)
    }
    
    func testThatItVerifiesPasswordWithCorrectMessageWhenNeeded() {
        //given
        let queue = DispatchQueue(label: "Password verification tests queue", qos: .background)
        sut = OldAppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor)
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

    // TODO: [John] Re-enable

//    func testThatApplicationDidEnterBackgroundUpdatesLastUnlockedDateIfAuthenticated() {
//        //given
//        appLockInteractor.lastUnlockedDate = Date()
//        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .authenticated)
//        //when
//        sut.applicationDidEnterBackground()
//        //then
//        XCTAssertTrue(Date() > appLockInteractor.lastUnlockedDate)
//    }
//
//    func testThatApplicationDidEnterBackgroundDoenstUpdateLastUnlockDateIfNotAuthenticated() {
//        //given
//        let date = Date()
//        appLockInteractor.lastUnlockedDate = date
//
//        //given
//        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .cancelled)
//        //when
//        sut.applicationDidEnterBackground()
//        //then
//        XCTAssertEqual(date, appLockInteractor.lastUnlockedDate)
//
//        //given
//        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .needed)
//        //when
//        sut.applicationDidEnterBackground()
//        //then
//        XCTAssertEqual(date, appLockInteractor.lastUnlockedDate)
//
//        //given
//        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .pendingPassword)
//        //when
//        sut.applicationDidEnterBackground()
//        //then
//        XCTAssertEqual(date, appLockInteractor.lastUnlockedDate)
//    }

    //MARK: - custom app lock
    func testThatUpdateFromAnOldVersionToNewVersionSupportAppLockShowsCreatePasscodeScreen() {
        //GIVEN
        appLockInteractor.isCustomPasscodeNotSet = true
        
        //WHEN
        sut.authenticationEvaluated(with: .needCustomPasscode)

        //THEN
        XCTAssert(userInterface.presentCreatePasscodeScreenCalled)
        
    }

    func testThatAppLockDoesNotShowIfIsCustomPasscodIsSet() {
        //GIVEN
        appLockInteractor.isCustomPasscodeNotSet = false
        
        //WHEN
        sut.authenticationEvaluated(with: .needCustomPasscode)
        
        //THEN
        XCTAssertFalse(userInterface.presentCreatePasscodeScreenCalled)
        
    }
    
     //MARK: - warning screen
    func testThatAppLockShowsWarningScreen_IfNeedsToNotifyUserIsTrue() {
        //given
        set(authenticationState: .authenticated)
        appLockInteractor.needsToNotifyUser = true
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertTrue(userInterface.presentWarningScreenCalled)
    }
    
    func testThatAppLockDoesNotShowWarningScreen_IfNeedsToNotifyUserIsFalse() {
        //given
        set(authenticationState: .authenticated)
        appLockInteractor.needsToNotifyUser = false
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertFalse(userInterface.presentWarningScreenCalled)
    }

    // MARK: - Require authentication

    func testThatIt_AsksToCreateCustomPasscode() {
        // Given
        appLockInteractor.needsToCreateCustomPasscode = true

        // When
        sut.requireAuthentication()

        // Then
        XCTAssertTrue(userInterface.presentCreatePasscodeScreenCalled)
    }

    func testThatIt_ResetsNeedsToNotifyUserFlag_AfterDisplayingCreatePasscodeScreen() {
        // Given
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
        appLockInteractor.needsToCreateCustomPasscode = false

        // When
        sut.requireAuthentication()

        // Then
        XCTAssertTrue(appLockInteractor.didCallEvaluateAuthentication)
    }
}

extension AppLockPresenterTests {
    func notification(for appState: AppState) -> Notification {
        return Notification(name: AppRootRouter.appStateDidTransition,
                            object: nil,
                            userInfo: [AppRootRouter.appStateKey: appState])
    }
    
    func set(authenticationState: AuthenticationState) {
        sut = OldAppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: authenticationState)
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
    
    func assert(reauthVisibile: Bool?, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(userInterface.reauthVisible, reauthVisibile, file: file, line: line)
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
