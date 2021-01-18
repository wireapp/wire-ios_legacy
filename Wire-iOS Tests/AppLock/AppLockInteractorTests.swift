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
import WireDataModel
import LocalAuthentication
@testable import Wire
@testable import WireCommonComponents

private final class AppLockInteractorOutputMock: AppLockInteractorOutput {
    
    var authenticationResult: AppLockController.AuthenticationResult?
    func authenticationEvaluated(with result: AppLockController.AuthenticationResult) {
        authenticationResult = result
    }
    
    var passwordVerificationResult: VerifyPasswordResult?
    func passwordVerified(with result: VerifyPasswordResult?) {
        passwordVerificationResult = result
    }
}

final class MockAppLockUserSession: AppLockInteractorUserSession {
    
    var appLockController: AppLockType = MockAppLock()
    
    var encryptMessagesAtRest: Bool = false
    
    var isDatabaseLocked: Bool = false
    
    var result: VerifyPasswordResult? = .denied
    func setEncryptionAtRest(enabled: Bool) throws {
        encryptMessagesAtRest = enabled
    }
    
    func setEncryptionAtRest(enabled: Bool, skipMigration: Bool) throws {
        encryptMessagesAtRest = enabled
    }
    
    func unlockDatabase(with context: LAContext) throws {
        isDatabaseLocked = false
    }
    
    func registerDatabaseLockedHandler(_ handler: @escaping (Bool) -> Void) -> Any {
        return "token"
    }
    
    func verify(password: String, completion: @escaping (VerifyPasswordResult?) -> Void) {
        completion(result)
    }
}

final class MockAppLock: AppLockType {

    static var authenticationResult: AppLockController.AuthenticationResult = .granted
    static var didPersistBiometrics: Bool = false

    // MARK: - Properties

    var isActive: Bool = false
    var isLocked = false
    var requiresBiometrics = false
    var needsToSetCustomPasscode = false
    var isCustomPasscodeNotSet: Bool = false
    var needsToNotifyUser: Bool = false
    var timeout: UInt = 900
    var isForced = false
    var isAvailable = true

    var delegate: AppLockDelegate? = nil

    private var customPasscode: Data?

    // MARK: - Methods

    func open() {
        // No op
    }

    func evaluateAuthentication(scenario: AppLockController.AuthenticationScenario, description: String, context: LAContextProtocol, with callback: @escaping (AppLockController.AuthenticationResult, LAContextProtocol) -> Void) {
        callback(MockAppLock.authenticationResult, LAContext())
    }

    func persistBiometrics() {
        MockAppLock.didPersistBiometrics = true
    }

    func storePasscode(_ passcode: String) throws {
        customPasscode = passcode.data(using: .utf8)
    }

    func fetchPasscode() -> Data? {
        return customPasscode
    }

    func deletePasscode() throws {
        customPasscode = nil
    }
}

final class AppLockInteractorTests: ZMSnapshotTestCase {
    var sut: OldAppLockInteractor!
    private var appLockInteractorOutputMock: AppLockInteractorOutputMock!
    private var userSessionMock: MockAppLockUserSession!
    
    override func setUp() {
        super.setUp()
        appLockInteractorOutputMock = AppLockInteractorOutputMock()
        userSessionMock = MockAppLockUserSession()
        sut = OldAppLockInteractor(session: userSessionMock)
        sut.output = appLockInteractorOutputMock
    }
    
    override func tearDown() {
        appLockInteractorOutputMock = nil
        sut = nil
        super.tearDown()
    }

    func testThatEvaluateAuthenticationCompletesWithCorrectResult() {
        //given
        let queue = DispatchQueue.main
        sut.dispatchQueue = queue
        MockAppLock.authenticationResult = .granted
        appLockInteractorOutputMock.authenticationResult = nil
        let expectation = XCTestExpectation(description: "evaluate authentication")

        //when
        sut.evaluateAuthentication(description: "")

        //then
        queue.async {
            XCTAssertNotNil(self.appLockInteractorOutputMock.authenticationResult)
            XCTAssertEqual(self.appLockInteractorOutputMock.authenticationResult, MockAppLock.authenticationResult)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testThatItNotifiesOutputWhenPasswordWasVerified() {
        //given
        let queue = DispatchQueue.main
        sut.dispatchQueue = queue
        try! userSessionMock.appLockController.storePasscode("foo")
        appLockInteractorOutputMock.passwordVerificationResult = nil
        let expectation = XCTestExpectation(description: "verify password")
        
        //when
        sut.verify(customPasscode: "bar")
        
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
        try! userSessionMock.appLockController.storePasscode("foo")

        //when
        sut.verify(customPasscode: "foo")
        
        //then
        XCTAssertTrue(MockAppLock.didPersistBiometrics)
    }
    
    func testThatItDoesntPersistBiometricsWhenPasswordIsInvalid() {
        //given
        userSessionMock.result = .denied
        
        //when
        sut.verify(customPasscode: "")

        //then
        XCTAssertFalse(MockAppLock.didPersistBiometrics)
    }

}
