//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import WireSyncEngine
import WireUtilities

class UserProfileUpdateStatusTests: MessagingTest {

    var observerToken: Any?

    var sut: UserProfileUpdateStatus! = nil

    fileprivate var observer: TestUserProfileUpdateObserver! = nil

    fileprivate var newRequestObserver: OperationLoopNewRequestObserver!

    fileprivate var mockAnalytics: MockAnalytics!

    /// Number of time the new request callback was invoked
    var newRequestCallbackCount: Int {
        return newRequestObserver.notifications.count
    }

    override func setUp() {
        super.setUp()
        self.newRequestObserver = OperationLoopNewRequestObserver()
        self.observer = TestUserProfileUpdateObserver()
        self.mockAnalytics = MockAnalytics()
        self.sut = UserProfileUpdateStatus(managedObjectContext: self.uiMOC, analytics: self.mockAnalytics)
        self.observerToken = self.sut.add(observer: self.observer)
    }

    override func tearDown() {
        self.newRequestObserver = nil
        self.observerToken = nil
        self.observer = nil
        self.mockAnalytics = nil
        self.sut = nil
        super.tearDown()
    }
}

extension UserProfileUpdateStatusTests {
    func testThatItDoesNotRetainObserver() {
        // GIVEN
        var observer: TestUserProfileUpdateObserver? = TestUserProfileUpdateObserver()

        // WHEN
        _ = self.sut.add(observer: observer!)

        weak var weakObserver = observer

        autoreleasepool {
            observer = nil
        }

        // THEN
        XCTAssertNil(weakObserver)
    }
}

// MARK: - Changing email
extension UserProfileUpdateStatusTests {
    func testThatItReturnsErrorWhenPreparingForEmailChangeAndUserUserHasNoEmail() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.setValue(nil, forKey: #keyPath(ZMUser.emailAddress))

        // WHEN
        do {
            try self.sut.requestEmailChange(email: "foo@example.com")
        } catch {
            XCTFail("Should not throw")
            return
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .emailUpdateDidFail(error: UserProfileUpdateError.emailNotSet):
            break
        default:
            XCTFail()
        }
    }

    func testThatItPreparesForEmailChangeIfSelfUserHasEmail() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))

        // WHEN
        do {
            try self.sut.requestEmailChange(email: "foo@example.com")
        } catch {
            XCTFail("Should not throw")
            return
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertTrue(self.sut.currentlyChangingEmail)
        XCTAssertFalse(self.sut.currentlySettingEmail)
        XCTAssertFalse(self.sut.currentlySettingPassword)
        XCTAssertEqual(self.newRequestCallbackCount, 1)
    }

}

// MARK: - Set email and password
extension UserProfileUpdateStatusTests {

    func testThatItIsNotUpdatingEmail() {
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
        XCTAssertNil(self.sut.emailCredentials())
    }

    func testThatItPreparesForEmailAndPasswordChangeIfTheSelfUserHasNoEmail() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        XCTAssertNil(selfUser.emailAddress)
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")

        // WHEN
        do {
            try self.sut.requestSettingEmailAndPassword(credentials: credentials)
        } catch {
            XCTFail()
            return
        }

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        XCTAssertFalse(self.sut.currentlySettingEmail)
        XCTAssertTrue(self.sut.currentlySettingPassword)
        XCTAssertNil(self.sut.emailCredentials())
        XCTAssertEqual(self.newRequestCallbackCount, 1)
    }

    func testThatItReturnsErrorWhenPreparingForEmailAndPasswordChangeAndUserUserHasEmail() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")

        // WHEN
        do {
            try self.sut.requestSettingEmailAndPassword(credentials: credentials)
        } catch {
            XCTFail("Should not throw")
            return
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .emailUpdateDidFail(error: UserProfileUpdateError.emailAlreadySet):
            break
        default:
            XCTFail()
        }
    }

    func testThatItCanCancelSettingEmailAndPassword() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.sut.cancelSettingEmailAndPassword()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
        XCTAssertNil(self.sut.emailCredentials())
    }

    func testThatItNeedsToSetEmailAfterSuccessfullySettingPassword() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.sut.didUpdatePasswordSuccessfully()

        // THEN
        XCTAssertTrue(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
        XCTAssertNil(self.sut.emailCredentials())

    }

    func testThatItCompletesAfterSuccessfullySettingPasswordAndEmail() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.sut.didUpdatePasswordSuccessfully()
        self.sut.didUpdateEmailSuccessfully()

        // THEN
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
        XCTAssertEqual(self.sut.emailCredentials(), credentials)
    }

    func testThatItNotifiesAfterSuccessfullySettingEmail() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.sut.didUpdatePasswordSuccessfully()
        self.sut.didUpdateEmailSuccessfully()

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .emailDidSendVerification:
            break
        default:
            XCTFail()
        }
    }

    func testThatItIsNotSettingEmailAnymoreAsSoonAsTheSelfUserHasEmail() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))

        // THEN
        XCTAssertFalse(self.sut.currentlySettingEmail)
        XCTAssertFalse(self.sut.currentlySettingPassword)
    }

    func testThatItIsNotSettingPasswordAnymoreAsSoonAsTheSelfUserHasEmail() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didUpdatePasswordSuccessfully()

        // WHEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))

        // THEN
        XCTAssertFalse(self.sut.currentlySettingEmail)
        XCTAssertFalse(self.sut.currentlySettingPassword)
    }

    func testThatItIsNotSettingEmailAndPasswordAnymoreIfItFailsToUpdatePassword() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.sut.didFailPasswordUpdate()

        // THEN
        XCTAssertFalse(self.sut.currentlySettingEmail)
        XCTAssertFalse(self.sut.currentlySettingPassword)
        XCTAssertNil(self.sut.emailCredentials())
    }

    func testThatItNotifiesIfItFailsToUpdatePassword() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.sut.didFailPasswordUpdate()

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .passwordUpdateDidFail:
            break
        default:
            XCTFail()
        }
    }

    func testThatItIsNotSettingEmailAnymoreIfItFailsToUpdateEmail() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let error = NSError(domain: "WireSyncEngine", code: 100, userInfo: nil)

        // WHEN
        self.sut.didUpdatePasswordSuccessfully()
        self.sut.didFailEmailUpdate(error: error)

        // THEN
        XCTAssertFalse(self.sut.currentlySettingEmail)
        XCTAssertFalse(self.sut.currentlySettingPassword)
        XCTAssertNil(self.sut.emailCredentials())
    }

    func testThatItNotifiesIfItFailsToUpdateEmail() {

        // GIVEN
        let error = NSError(domain: "WireSyncEngine", code: 100, userInfo: nil)
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.sut.didUpdatePasswordSuccessfully()
        self.sut.didFailEmailUpdate(error: error)

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .emailUpdateDidFail(let _error):
            XCTAssertEqual(error, _error as NSError)
        default:
            XCTFail()
        }
    }
}

// MARK: - Credentials provider
extension UserProfileUpdateStatusTests {

    func testThatItDoesNotReturnCredentialsIfOnlyPasswordIsVerified() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")

        // WHEN
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didUpdatePasswordSuccessfully()

        // THEN
        XCTAssertNil(self.sut.emailCredentials())
    }

    func testThatItDoesNotReturnCredentialsIfOnlyEmailIsVerified() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")

        // WHEN
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didUpdateEmailSuccessfully()

        // THEN
        XCTAssertNil(self.sut.emailCredentials())
    }

    func testThatItReturnsCredentialsIfEmailAndPasswordAreVerified() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")

        // WHEN
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didUpdatePasswordSuccessfully()
        self.sut.didUpdateEmailSuccessfully()

        // THEN
        XCTAssertEqual(self.sut.emailCredentials(), credentials)
    }

    func testThatItDeletesCredentials() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? self.sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didUpdatePasswordSuccessfully()
        self.sut.didUpdateEmailSuccessfully()

        // WHEN
        self.sut.credentialsMayBeCleared()

        // THEN
        XCTAssertNil(self.sut.emailCredentials())
    }
}

// MARK: - Phone number code request
extension UserProfileUpdateStatusTests {

    func testThatItIsNotRequestingPhoneVerificationAtStart() {
        XCTAssertFalse(self.sut.currentlyRequestingPhoneVerificationCode)
    }

    func testThatItPreparesForRequestingPhoneVerificationCodeForRegistration() {

        // GIVEN
        let phoneNumber = "+1555234342"

        // WHEN
        self.sut.requestPhoneVerificationCode(phoneNumber: phoneNumber)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertTrue(self.sut.currentlyRequestingPhoneVerificationCode)
        XCTAssertEqual(self.sut.phoneNumberForWhichCodeIsRequested, phoneNumber)
        XCTAssertEqual(self.newRequestCallbackCount, 1)

    }

    func testThatItCompletesRequestingPhoneVerificationCode() {

        // GIVEN
        let phoneNumber = "+1555234342"

        // WHEN
        self.sut.requestPhoneVerificationCode(phoneNumber: phoneNumber)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didRequestPhoneVerificationCodeSuccessfully()

        // THEN
        XCTAssertFalse(self.sut.currentlyRequestingPhoneVerificationCode)
        XCTAssertNil(self.sut.phoneNumberForWhichCodeIsRequested)

    }

    func testThatItFailsRequestingPhoneVerificationCode() {

        // GIVEN
        let error = NSError(domain: "WireSyncEngine", code: 100, userInfo: nil)
        let phoneNumber = "+1555234342"

        // WHEN
        self.sut.requestPhoneVerificationCode(phoneNumber: phoneNumber)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFailPhoneVerificationCodeRequest(error: error)

        // THEN
        XCTAssertFalse(self.sut.currentlyRequestingPhoneVerificationCode)
        XCTAssertNil(self.sut.phoneNumberForWhichCodeIsRequested)

    }

    func testThatItNotifiesAfterCompletingRequestingPhoneVerificationCode() {

        // GIVEN
        let phoneNumber = "+1555234342"

        // WHEN
        self.sut.requestPhoneVerificationCode(phoneNumber: phoneNumber)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didRequestPhoneVerificationCodeSuccessfully()

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .phoneNumberVerificationCodeRequestDidSucceed:
            break
        default:
            XCTFail()
        }
    }

    func testThatItNotifiesAfterFailureInRequestingPhoneVerificationCode() {

        // GIVEN
        let error = NSError(domain: "WireSyncEngine", code: 100, userInfo: nil)
        let phoneNumber = "+1555234342"

        // WHEN
        self.sut.requestPhoneVerificationCode(phoneNumber: phoneNumber)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFailPhoneVerificationCodeRequest(error: error)

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .phoneNumberVerificationCodeRequestDidFail(let _error):
            XCTAssertEqual(error, _error as NSError)
        default:
            XCTFail()
        }
    }
}

// MARK: - Phone number verification
extension UserProfileUpdateStatusTests {

    func testThatItIsNotUpdatingPhoneNumberAtStart() {
        XCTAssertFalse(self.sut.currentlySettingPhone)
    }

    func testThatItPreparesForPhoneChangeWithCredentials() {

        // GIVEN
        let credentials = ZMPhoneCredentials(phoneNumber: "+1555234342", verificationCode: "234555")

        // WHEN
        self.sut.requestPhoneNumberChange(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertTrue(self.sut.currentlySettingPhone)
        XCTAssertEqual(self.sut.phoneNumberToSet, credentials)
        XCTAssertEqual(self.newRequestCallbackCount, 1)

    }

    func testThatItCompletesUpdatingPhoneNumber() {

        // GIVEN
        let credentials = ZMPhoneCredentials(phoneNumber: "+1555234342", verificationCode: "234555")

        // WHEN
        self.sut.requestPhoneNumberChange(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didChangePhoneSuccesfully()

        // THEN
        XCTAssertFalse(self.sut.currentlySettingPhone)
        XCTAssertNil(self.sut.phoneNumberToSet)
    }

    func testThatItFailsUpdatingPhoneNumber() {

        // GIVEN
        let error = NSError(domain: "WireSyncEngine", code: 100, userInfo: nil)
        let credentials = ZMPhoneCredentials(phoneNumber: "+1555234342", verificationCode: "234555")

        // WHEN
        self.sut.requestPhoneNumberChange(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFailChangingPhone(error: error)

        // THEN
        XCTAssertFalse(self.sut.currentlySettingPhone)
        XCTAssertNil(self.sut.phoneNumberToSet)

    }

    func testThatItNotifiesAfterFailureInUpdatingPhoneNumber() {

        // GIVEN
        let credentials = ZMPhoneCredentials(phoneNumber: "+1555234342", verificationCode: "234555")
        let error = NSError(domain: "WireSyncEngine", code: 100, userInfo: nil)

        // WHEN
        self.sut.requestPhoneNumberChange(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFailChangingPhone(error: error)

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .phoneNumberChangeDidFail(let _error):
            XCTAssertEqual(error, _error as NSError)
        default:
            XCTFail()
        }
    }
}

// MARK: - Check handle availability
extension UserProfileUpdateStatusTests {

    func testThatItIsNotCheckingAvailabilityAtCreation() {
        XCTAssertFalse(self.sut.currentlyCheckingHandleAvailability)
    }

    func testThatItPreparesForCheckingHandleAvailability() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(self.sut.handleToCheck, handle)
        XCTAssertTrue(self.sut.currentlyCheckingHandleAvailability)
        XCTAssertEqual(newRequestObserver.notifications.count, 1)
    }

    func testThatItCompletesCheckingHandleAvailability_Available() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didNotFindHandle(handle: handle)

        // THEN
        XCTAssertNil(self.sut.handleToCheck)
        XCTAssertFalse(self.sut.currentlyCheckingHandleAvailability)
    }

    func testThatItCompletesCheckingHandleAvailability_NotAvailable() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFetchHandle(handle: handle)

        // THEN
        XCTAssertNil(self.sut.handleToCheck)
        XCTAssertFalse(self.sut.currentlyCheckingHandleAvailability)
    }

    func testThatItFailsCheckingHandleAvailability() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFailRequestToFetchHandle(handle: handle)

        // THEN
        XCTAssertNil(self.sut.handleToCheck)
        XCTAssertFalse(self.sut.currentlyCheckingHandleAvailability)
    }

    func testThatItDoesCompletesCheckingHandleAvailabilityIfDifferentHandle_Available() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didNotFindHandle(handle: "other")

        // THEN
        XCTAssertEqual(self.sut.handleToCheck, handle)
        XCTAssertTrue(self.sut.currentlyCheckingHandleAvailability)
    }

    func testThatItDoesCompletesCheckingHandleAvailabilityIfDifferentHandle_NotAvailable() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFetchHandle(handle: "other")

        // THEN
        XCTAssertEqual(self.sut.handleToCheck, handle)
        XCTAssertTrue(self.sut.currentlyCheckingHandleAvailability)
    }

    func testThatItDoesCompletesCheckingHandleAvailabilityIfDifferentHandle_Failed() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFailRequestToFetchHandle(handle: "other")

        // THEN
        XCTAssertEqual(self.sut.handleToCheck, handle)
        XCTAssertTrue(self.sut.currentlyCheckingHandleAvailability)
    }

    func testThatItNotifiesAfterCheckingHandleAvailability_Available() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestCheckHandleAvailability(handle: "other")
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didNotFindHandle(handle: handle)

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .didCheckAvailabilityOfHandle(handle: handle, available: true):
            break
        default:
            XCTFail()
        }
    }

    func testThatItNotifiesAfterCheckingHandleAvailability_NotAvailable() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestCheckHandleAvailability(handle: "other")
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFetchHandle(handle: handle)

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .didCheckAvailabilityOfHandle(handle: handle, available: false):
            break
        default:
            XCTFail()
        }
    }

    func testThatItNotifiesAfterFailingCheckingHandleAvailability() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestCheckHandleAvailability(handle: "other")
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFailRequestToFetchHandle(handle: handle)

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .didFailToCheckAvailabilityOfHandle(handle: handle):
            break
        default:
            XCTFail()
        }
    }
}

// MARK: - Set handle
extension UserProfileUpdateStatusTests {

    func testThatItIsNotSettingHandleyAtCreation() {
        XCTAssertFalse(self.sut.currentlySettingHandle)
    }

    func testThatItPreparesForSettingHandle() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(self.sut.handleToSet, handle)
        XCTAssertTrue(self.sut.currentlySettingHandle)
        XCTAssertEqual(newRequestObserver.notifications.count, 1)
    }

    func testThatItSetsHandleSuccessfully() {

        // GIVEN
        let handle = "foobar"
        let selfUser = ZMUser.selfUser(in: self.sut.managedObjectContext)
        XCTAssertNotNil(selfUser)

        // WHEN
        self.sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didSetHandle()

        // THEN
        XCTAssertNil(self.sut.handleToSet)
        XCTAssertFalse(self.sut.currentlySettingHandle)
        XCTAssertEqual(selfUser.handle, handle)
    }

    func testThatItCancelsSetHandle() {

        // GIVEN
        let handle = "foobar"
        let selfUser = ZMUser.selfUser(in: self.sut.managedObjectContext)

        // WHEN
        self.sut.requestSettingHandle(handle: handle)
        self.sut.cancelSettingHandle()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertNil(self.sut.handleToSet)
        XCTAssertFalse(self.sut.currentlySettingHandle)
        XCTAssertNil(selfUser.handle)
    }

    func testThatItFailsToSetHandle() {

        // GIVEN
        let handle = "foobar"
        let selfUser = ZMUser.selfUser(in: self.sut.managedObjectContext)

        // WHEN
        self.sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFailToSetHandle()

        // THEN
        XCTAssertNil(self.sut.handleToSet)
        XCTAssertFalse(self.sut.currentlySettingHandle)
        XCTAssertNil(selfUser.handle)
    }

    func testThatItFailsToSetHandleBecauseExisting() {

        // GIVEN
        let handle = "foobar"
        let selfUser = ZMUser.selfUser(in: self.sut.managedObjectContext)

        // WHEN
        self.sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFailToSetAlreadyExistingHandle()

        // THEN
        XCTAssertNil(self.sut.handleToSet)
        XCTAssertFalse(self.sut.currentlySettingHandle)
        XCTAssertNil(selfUser.handle)
    }

    func testThatItDoesNotSetTheHandleOnSelfUserIfCompletedAfterCancelling() {

        // GIVEN
        let handle = "foobar"
        let selfUser = ZMUser.selfUser(in: self.sut.managedObjectContext)

        // WHEN
        self.sut.requestSettingHandle(handle: handle)
        self.sut.cancelSettingHandle()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didSetHandle()

        // THEN
        XCTAssertNil(selfUser.handle)
    }

    func testThatItNotifyWhenSetingHandleSuccessfully() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didSetHandle()

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .didSetHandle:
            break
        default:
            XCTFail()
        }
    }

    func testThatItNotifyWhenItFailsToSetHandle() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFailToSetHandle()

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .didFailToSetHandle:
            break
        default:
            XCTFail()
        }
    }

    func testThatItNotifiesWhenItFailsToSetHandleBecauseExisting() {

        // GIVEN
        let handle = "foobar"

        // WHEN
        self.sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.sut.didFailToSetAlreadyExistingHandle()

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .didFailToSetHandleBecauseExisting:
            break
        default:
            XCTFail()
        }
    }
}

// MARK: - Find handle suggestions
extension UserProfileUpdateStatusTests {

    func testThatItIsNotGeneratingHandleSuggestionsAtCreation() {
        XCTAssertFalse(self.sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(self.sut.bestHandleSuggestion)
    }

    func testThatItPreparesForGeneratingHandleSuggestion() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.sut.managedObjectContext)
        selfUser.name = "Anna Luna"
        let normalized = "annaluna"

        // WHEN
        self.sut.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertTrue(self.sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(self.sut.bestHandleSuggestion)
        XCTAssertEqual(newRequestObserver.notifications.count, 1)
        XCTAssertEqual(self.sut.suggestedHandlesToCheck?.first, normalized)
    }

    func testThatItStopsGeneratingHandleSuggestionsIfHandleIsSet() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.sut.managedObjectContext)
        selfUser.name = "Anna Luna"

        // WHEN
        self.sut.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        XCTAssertTrue(self.sut.currentlyGeneratingHandleSuggestion)
        selfUser.handle = "annaluna"

        // THEN
        XCTAssertFalse(self.sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(self.sut.bestHandleSuggestion)
    }

    func testThatItPreparesForGeneratingHandleSuggestionWithInvalidDisplayName() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.sut.managedObjectContext)
        selfUser.name = "-"

        // WHEN
        self.sut.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertTrue(self.sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(self.sut.bestHandleSuggestion)
        XCTAssertEqual(newRequestObserver.notifications.count, 1)
        XCTAssertNotNil(self.sut.suggestedHandlesToCheck?.first)
    }

    func testThatItCompletesGeneratingHandleSuggestions() {

        // GIVEN
        let handle = "funkymonkey34"
        self.sut.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.sut.didFindHandleSuggestion(handle: handle)

        // THEN
        XCTAssertFalse(self.sut.currentlyGeneratingHandleSuggestion)
        XCTAssertEqual(self.sut.bestHandleSuggestion, handle)
    }

    func testThatItStopsSearchingForHandleSuggestionsIfItHasHandle() {

        // GIVEN
        self.sut.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let selfUser = ZMUser.selfUser(in: self.sut.managedObjectContext)
        selfUser.handle = "cozypanda23"
        self.sut.didNotFindAvailableHandleSuggestion()

        // THEN
        XCTAssertFalse(self.sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(self.sut.bestHandleSuggestion)
    }

    func testThatItRestatsSearchingForHandleSuggestionsAfterNotFindingAvailableOne() {

        // GIVEN
        self.sut.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        guard let previousHandle = self.sut.suggestedHandlesToCheck?.first else {
            XCTFail()
            return
        }

        // WHEN
        self.sut.didNotFindAvailableHandleSuggestion()

        // THEN
        XCTAssertTrue(self.sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(self.sut.bestHandleSuggestion)
        XCTAssertNotNil(self.sut.suggestedHandlesToCheck?.first)
        XCTAssertNotEqual(self.sut.suggestedHandlesToCheck?.first, previousHandle)
    }

    func testThatItFailsGeneratingHandleSuggestionsAndStopsIfItHasHandle() {

        // GIVEN
        self.sut.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let selfUser = ZMUser.selfUser(in: self.sut.managedObjectContext)
        selfUser.handle = "cozypanda23"
        self.sut.didFailToFindHandleSuggestion()

        // THEN
        XCTAssertFalse(self.sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(self.sut.bestHandleSuggestion)
        XCTAssertNil(self.sut.suggestedHandlesToCheck)
    }

    func testThatItNotifiesAfterFindingAHandleSuggestion() {

        // GIVEN
        let handle = "funkymokkey34"
        self.sut.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.sut.didFindHandleSuggestion(handle: handle)

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .didFindHandleSuggestion(let _handle):
            XCTAssertEqual(handle, _handle)
        default:
            XCTFail()
        }
        XCTAssertEqual(self.sut.lastSuggestedHandle, handle)
    }

    func testThatIfItSuggestsAHandleAndRequestedToSuggestMoreItStartsBySuggestingTheSame() {

        // GIVEN
        let handle = "funkymokkey34"
        self.sut.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.sut.didFindHandleSuggestion(handle: handle)

        // THEN
        XCTAssertEqual(self.observer.invokedCallbacks.count, 1)
        guard let first = self.observer.invokedCallbacks.first else { return }
        switch first {
        case .didFindHandleSuggestion(let _handle):
            XCTAssertEqual(handle, _handle)
        default:
            XCTFail()
        }

        // AND WHEN
        self.sut.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(self.sut.suggestedHandlesToCheck?.count, 1)
        XCTAssertEqual(self.sut.suggestedHandlesToCheck?.first, handle)
    }
}
