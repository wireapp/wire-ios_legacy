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
    
    func presentUnlockScreen(with message: String,
                             callback: @escaping RequestPasswordController.Callback) {
        requestPasswordMessage = message
        callback(passwordInput)
    }
    
    func presentCreatePasscodeScreen(callback: ResultHandler?) {
        presentCreatePasscodeScreenCalled = true
    }
    
    var spinnerAnimating: Bool?
    func setSpinner(animating: Bool) {
        spinnerAnimating = animating
    }
    
    var reauthVisible: Bool?
    func setReauth(visible: Bool) {
        reauthVisible = visible
    }
}

private final class AppLockInteractorMock: AppLockInteractorInput {
    var isCustomPasscodeNotSet: Bool = false
    
    var passwordToVerify: String?
    var customPasscodeToVerify: String?

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
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .needed)
        AppLock.rules = AppLockRules(useBiometricsOrAccountPassword: true, useCustomCodeInsteadOfAccountPassword: false, forceAppLock: false, appLockTimeout: 1)
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
    }
    
    func testThatItDoesntEvaluateAuthenticationOrUpdateUIIfNotNeeded() {
        //given
        set(authenticationState: .needed)
        resetMocksValues()
        
        //when
        sut.requireAuthenticationIfNeeded()
        
        //then
        XCTAssertTrue(appLockInteractor.didCallEvaluateAuthentication)
        assert(reauthVisibile: false)
        
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
    
    func testThatFailedAuthenticationDimsContentsWithoutReauth() {
        //when
        sut.authenticationEvaluated(with: .denied)
        //then
        assert(reauthVisibile: true)
        
        //given
        resetMocksValues()
        //when
        sut.authenticationEvaluated(with: .needAccountPassword)
        //then
        assert(reauthVisibile: true)
    }
    
    func testThatUnavailableAuthenticationDimsContentsWithReauth() {
        //when
        sut.authenticationEvaluated(with: .unavailable)
        //then
        assert(reauthVisibile: true)
    }
    
    func testThatGrantedAuthenticationDoesntDimContentsOrShowReauth() {
        //when
        sut.authenticationEvaluated(with: .granted)
        //then
        assert(reauthVisibile: false)
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
        assert(reauthVisibile: nil)
        
        //given
        resetMocksValues()
        //when
        sut.passwordVerified(with: .timeout)
        //then
        assert(reauthVisibile: nil)
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
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: .needed)
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
        
    //MARK: - custom app lock
    func testThatUpdateFromAnOldVersionToNewVersionSupportAppLockShowsCreatePasscodeScreen() {
        //GIVEN
        appLockInteractor.isCustomPasscodeNotSet = true
        
        //WHEN
        sut.authenticationEvaluated(with: .needAccountPassword)

        //THEN
        XCTAssert( userInterface.presentCreatePasscodeScreenCalled)
        
    }

    func testThatAppLockDoesNotShowIfIsCustomPasscodIsSet() {
        //GIVEN
        appLockInteractor.isCustomPasscodeNotSet = false
        
        //WHEN
        sut.authenticationEvaluated(with: .needAccountPassword)
        
        //THEN
        XCTAssertFalse( userInterface.presentCreatePasscodeScreenCalled)
        
    }
}

extension AppLockPresenterTests {
    func notification(for appState: AppState) -> Notification {
        return Notification(name: AppStateController.appStateDidTransition,
                            object: nil,
                            userInfo: [AppStateController.appStateKey: appState])
    }
    
    func set(authenticationState: AuthenticationState) {
        sut = AppLockPresenter(userInterface: userInterface, appLockInteractorInput: appLockInteractor, authenticationState: authenticationState)
    }
    
    func resetMocksValues() {
        userInterface.reauthVisible = nil
        userInterface.spinnerAnimating = nil
        appLockInteractor.didCallEvaluateAuthentication = false
    }
    
    func setupPasswordVerificationTest() {
        userInterface.passwordInput = "password"
        appLockInteractor.passwordToVerify = nil
        userInterface.requestPasswordMessage = nil
    }
    
    func assert(reauthVisibile: Bool?) {
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
