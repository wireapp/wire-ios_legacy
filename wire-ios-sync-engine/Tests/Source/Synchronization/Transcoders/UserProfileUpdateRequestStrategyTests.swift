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

class UserProfileUpdateRequestStrategyTests: MessagingTest {

    var sut: UserProfileUpdateRequestStrategy!
    var userProfileUpdateStatus: TestUserProfileUpdateStatus!
    var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()

        self.mockApplicationStatus = MockApplicationStatus()
        self.mockApplicationStatus.mockSynchronizationState = .online
        self.userProfileUpdateStatus = TestUserProfileUpdateStatus(managedObjectContext: self.uiMOC, analytics: MockAnalytics())
        self.sut = UserProfileUpdateRequestStrategy(managedObjectContext: self.uiMOC,
                                              applicationStatus: self.mockApplicationStatus,
                                              userProfileUpdateStatus: self.userProfileUpdateStatus)
    }

    override func tearDown() {
        self.sut = nil
        self.userProfileUpdateStatus = nil
        self.mockApplicationStatus = nil
        super.tearDown()
    }

}

// MARK: - Request generation
extension UserProfileUpdateRequestStrategyTests {

    func testThatItDoesNotCreateAnyRequestWhenNotAuthenticated() {

        // GIVEN
        self.userProfileUpdateStatus.requestPhoneVerificationCode(phoneNumber: "+15553453453")
        self.mockApplicationStatus.mockSynchronizationState = .unauthenticated

        // THEN
        XCTAssertNil(self.sut.nextRequest(for: .v0))

    }

    func testThatItDoesNotCreateAnyRequestWhenIdle() {

        // GIVEN
        // already authenticated in setup

        // THEN
        XCTAssertNil(self.sut.nextRequest(for: .v0))
    }

    func testThatItCreatesARequestToRequestAPhoneVerificationCode() {

        // GIVEN
        let phone = "+155523123123"
        self.userProfileUpdateStatus.requestPhoneVerificationCode(phoneNumber: phone)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)

        // THEN
        let expected = ZMTransportRequest(path: "/self/phone", method: .methodPUT, payload: ["phone": phone] as NSDictionary, apiVersion: APIVersion.v0.rawValue)
        XCTAssertEqual(request, expected)
    }

    func testThatItCreatesARequestToChangePhone() {

        // GIVEN
        ZMUser.selfUser(in: self.uiMOC).setValue("+155534534566", forKey: #keyPath(ZMUser.phoneNumber))
        let credentials = ZMPhoneCredentials(phoneNumber: "+155523123123", verificationCode: "12345")
        self.userProfileUpdateStatus.requestPhoneNumberChange(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)

        // THEN
        let expected = ZMTransportRequest(path: "/activate", method: .methodPOST, payload: [
            "phone": credentials.phoneNumber!,
            "code": credentials.phoneNumberVerificationCode!,
            "dryrun": false
            ] as NSDictionary, apiVersion: APIVersion.v0.rawValue)
        XCTAssertEqual(request, expected)
    }

    func testThatItCreatesARequestToAddPhone() {

        // GIVEN
        ZMUser.selfUser(in: self.uiMOC).setValue(nil, forKey: #keyPath(ZMUser.phoneNumber))
        let credentials = ZMPhoneCredentials(phoneNumber: "+155523123123", verificationCode: "12345")
        self.userProfileUpdateStatus.requestPhoneNumberChange(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)

        // THEN
        let expected = ZMTransportRequest(path: "/activate", method: .methodPOST, payload: [
            "phone": credentials.phoneNumber!,
            "code": credentials.phoneNumberVerificationCode!,
            "dryrun": false
            ] as NSDictionary, apiVersion: APIVersion.v0.rawValue)
        XCTAssertEqual(request, expected)
    }

    func testThatItCreatesARequestToUpdatePassword() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "mario@example.com", password: "princess")
        try! self.userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)

        // THEN
        let expected = ZMTransportRequest(path: "/self/password", method: .methodPUT, payload: [
            "new_password": credentials.password!
            ] as NSDictionary, apiVersion: APIVersion.v0.rawValue)
        XCTAssertEqual(request, expected)
    }

    func testThatItCreatesARequestToChangeEmail() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))

        let newEmail = "mario@example.com"
        try! self.userProfileUpdateStatus.requestEmailChange(email: newEmail)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)

        // THEN
        XCTAssertEqual(request?.path, "/access/self/email")
        XCTAssertEqual(request?.method, .methodPUT)
        XCTAssertEqual(request?.needsCookie, true)
        let emailInPayload = request?.payload?.asDictionary()?["email"] as? String
        XCTAssertEqual(emailInPayload, newEmail)
    }

    func testThatItCreatesARequestToRemovePhoneNumber() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))
        selfUser.setValue("+155534534566", forKey: #keyPath(ZMUser.phoneNumber))
        self.userProfileUpdateStatus.requestPhoneNumberRemoval()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)

        // THEN
        XCTAssertEqual(request?.path, "/self/phone")
        XCTAssertEqual(request?.method, .methodDELETE)
        XCTAssertNil(request?.payload)
    }

    func testThatItCreatesARequestToUpdateEmailAfterUpdatingPassword() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "mario@example.com", password: "princess")
        try! self.userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.userProfileUpdateStatus.didUpdatePasswordSuccessfully()

        // WHEN
        let request = self.sut.nextRequest(for: .v0)

        // THEN
        let expected = ZMTransportRequest(path: "/access/self/email", method: .methodPUT, payload: [
            "email": credentials.email!
            ] as NSDictionary, apiVersion: APIVersion.v0.rawValue)
        XCTAssertEqual(request, expected)

    }

    func testThatItCreatesARequestToCheckHandleAvailability() {

        // GIVEN
        let handle = "martha"
        self.userProfileUpdateStatus.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)

        // THEN
        let expected = ZMTransportRequest(path: "/users/handles/\(handle)", method: .methodHEAD, payload: nil, apiVersion: APIVersion.v0.rawValue)
        XCTAssertEqual(request, expected)
    }

    func testThatItCreatesARequestToSetHandle() {

        // GIVEN
        let handle = "martha"
        self.userProfileUpdateStatus.requestSettingHandle(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)

        // THEN
        let payload: NSDictionary = ["handle": handle]
        let expected = ZMTransportRequest(path: "/self/handle", method: .methodPUT, payload: payload, apiVersion: APIVersion.v0.rawValue)
        XCTAssertEqual(request, expected)
    }

    func testThatItCreatesARequestToFindHandleSuggestion() {

        // GIVEN
        self.userProfileUpdateStatus.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        guard let handles = self.userProfileUpdateStatus.suggestedHandlesToCheck else {
            XCTFail()
            return
        }

        // WHEN
        let possibleRequest = self.sut.nextRequest(for: .v0)

        // THEN
        guard let request = possibleRequest else {
            XCTFail()
            return
        }

        XCTAssertEqual(request.method, .methodPOST)
        XCTAssertEqual(request.path, "/users/handles")
        guard let payloadDictionary = request.payload?.asDictionary(),
            let payloadHandles = payloadDictionary["handles"] as? [String]
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(payloadHandles, handles)
        XCTAssertEqual(payloadDictionary["return"] as? Int, 1)
    }
}

// MARK: - Parsing response
extension UserProfileUpdateRequestStrategyTests {

    // MARK: - Phone verification code
    func testThatItCallsDidRequestPhoneVerificationCodeSuccessfully() {

        // GIVEN
        let phone = "+155523123123"
        self.userProfileUpdateStatus.requestPhoneVerificationCode(phoneNumber: phone)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.successResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidRequestPhoneVerificationCodeSuccessfully, 1)
    }

    func testThatItCallsDidFailPhoneVerificationCodeRequest() {

        // GIVEN
        let phone = "+155523123123"
        self.userProfileUpdateStatus.requestPhoneVerificationCode(phoneNumber: phone)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.invalidPhoneNumberResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailPhoneVerificationCodeRequest.count, 1)
        guard let error = self.userProfileUpdateStatus.recordedDidFailPhoneVerificationCodeRequest.first else { return }
        XCTAssertEqual((error as NSError).code, Int(ZMUserSessionErrorCode.invalidPhoneNumber.rawValue))
    }

    func testThatItGetsInvalidPhoneNumberErrorOnBadRequestResponse() {

        // GIVEN
        let phone = "+155523123123"
        self.userProfileUpdateStatus.requestPhoneVerificationCode(phoneNumber: phone)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.badRequestResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailPhoneVerificationCodeRequest.count, 1)
        guard let error = self.userProfileUpdateStatus.recordedDidFailPhoneVerificationCodeRequest.first else { return }
        XCTAssertEqual((error as NSError).code, Int(ZMUserSessionErrorCode.invalidPhoneNumber.rawValue))
    }

    func testThatItGetsDuplicatePhoneNumberErrorOnDuplicatePhoneNumber() {

        // GIVEN
        let phone = "+155523123123"
        self.userProfileUpdateStatus.requestPhoneVerificationCode(phoneNumber: phone)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.keyExistsResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailPhoneVerificationCodeRequest.count, 1)
        guard let error = self.userProfileUpdateStatus.recordedDidFailPhoneVerificationCodeRequest.first else { return }
        XCTAssertEqual((error as NSError).code, Int(ZMUserSessionErrorCode.phoneNumberIsAlreadyRegistered.rawValue))
    }

    // MARK: - Phone number change
    func testThatItCallsDidChangePhoneSuccessfully() {

        // GIVEN
        let credentials = ZMPhoneCredentials(phoneNumber: "+155523123123", verificationCode: "12345")
        self.userProfileUpdateStatus.requestPhoneNumberChange(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.successResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidChangePhoneSuccesfully, 1)
    }

    func testThatItCallsDidFailChangePhone() {

        // GIVEN
        let credentials = ZMPhoneCredentials(phoneNumber: "+155523123123", verificationCode: "12345")
        self.userProfileUpdateStatus.requestPhoneNumberChange(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.errorResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailChangingPhone.count, 1)
        guard let error = self.userProfileUpdateStatus.recordedDidFailPhoneVerificationCodeRequest.first else { return }
        XCTAssertEqual((error as NSError).code, Int(ZMUserSessionErrorCode.unknownError.rawValue))
    }

    // MARK: - Setting email and password
    func testThatCallsDidUpdatePasswordSuccessfully() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "mario@example.com", password: "princess")
        try! self.userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.successResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidUpdatePasswordSuccessfully, 1)
    }

    func testThatCallsDidUpdatePasswordSuccessfullyOn403() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "mario@example.com", password: "princess")
        try! self.userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.invalidCredentialsResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidUpdatePasswordSuccessfully, 1)
    }

    func testThatCallsDidFailPasswordUpdateOn400() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "mario@example.com", password: "princess")
        try! self.userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.errorResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailPasswordUpdate, 1)
    }

    func testThatItCallsDidUpdateEmailSuccessfullyWhenSettingEmailAndPassword() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "mario@example.com", password: "princess")
        try! self.userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.userProfileUpdateStatus.didUpdatePasswordSuccessfully()

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.successResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidUpdateEmailSuccessfully, 1)
    }

    func testThatItCallsDidFailEmailUpdateWithInvalidEmail() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "mario@example.com", password: "princess")
        try! self.userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.userProfileUpdateStatus.didUpdatePasswordSuccessfully()

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.invalidEmailResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailEmailUpdate.count, 1)
        guard let error = self.userProfileUpdateStatus.recordedDidFailEmailUpdate.first else { return }
        XCTAssertEqual((error as NSError).code, Int(ZMUserSessionErrorCode.invalidEmail.rawValue))
    }

    func testThatItCallsDidFailEmailUpdateWithDuplicatedEmail() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "mario@example.com", password: "princess")
        try! self.userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.userProfileUpdateStatus.didUpdatePasswordSuccessfully()

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.keyExistsResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailEmailUpdate.count, 1)
        guard let error = self.userProfileUpdateStatus.recordedDidFailEmailUpdate.first else { return }
        XCTAssertEqual((error as NSError).code, Int(ZMUserSessionErrorCode.emailIsAlreadyRegistered.rawValue))
    }

    func testThatItCallsDidFailEmailUpdateWithUnknownError() {

        // GIVEN
        let credentials = ZMEmailCredentials(email: "mario@example.com", password: "princess")
        try! self.userProfileUpdateStatus.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.userProfileUpdateStatus.didUpdatePasswordSuccessfully()

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.errorResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailEmailUpdate.count, 1)
        guard let error = self.userProfileUpdateStatus.recordedDidFailEmailUpdate.first else { return }
        XCTAssertEqual((error as NSError).code, Int(ZMUserSessionErrorCode.unknownError.rawValue))

    }

    // MARK: - Email change
    func testThatItCallsDidUpdateEmailSuccessfullyWhenChangingEmail() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))
        try! self.userProfileUpdateStatus.requestEmailChange(email: "mario@example.com")
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.successResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidUpdateEmailSuccessfully, 1)
    }

    // MARK: - Removing phone number
    func testThatItCallsDidRemovePhoneNumberSuccessfully() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.setValue("+155534534566", forKey: #keyPath(ZMUser.phoneNumber))
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))
        self.userProfileUpdateStatus.requestPhoneNumberRemoval()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        XCTAssertNotNil(request)
        request?.complete(with: self.successResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNil(ZMUser.selfUser(in: self.uiMOC).phoneNumber)
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidRemovePhoneNumberSuccessfully, 1)
    }

    func testThatItCallsDidFailRemovePhoneNumberWhenItsLastIdentity() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.setValue("+155534534566", forKey: #keyPath(ZMUser.phoneNumber))
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))
        self.userProfileUpdateStatus.requestPhoneNumberRemoval()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.lastIdentityResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailPhoneNumberRemoval.count, 1)
        guard let error = self.userProfileUpdateStatus.recordedDidFailPhoneNumberRemoval.first else { return }
        XCTAssertEqual((error as NSError).code, Int(ZMUserSessionErrorCode.lastUserIdentityCantBeDeleted.rawValue))
    }

    func testThatItCallsDidFailRemovePhoneNumberOnOtherErrors() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.setValue("+155534534566", forKey: #keyPath(ZMUser.phoneNumber))
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))
        self.userProfileUpdateStatus.requestPhoneNumberRemoval()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.errorResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailPhoneNumberRemoval.count, 1)
        guard let error = self.userProfileUpdateStatus.recordedDidFailPhoneNumberRemoval.first else { return }
        XCTAssertEqual((error as NSError).code, Int(ZMUserSessionErrorCode.unknownError.rawValue))
    }

    // MARK: - Check handle availability
    func testThatItCallsDidFetchHandle() {

        // GIVEN
        let handle = "martha"
        self.userProfileUpdateStatus.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.successResponse(path: request?.path))

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFetchHandle, [handle])
    }

    func testThatItCallsDidNotFindHandle() {

        // GIVEN
        let handle = "martha"
        self.userProfileUpdateStatus.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.notFoundResponse(path: request!.path))

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidNotFindHandle, [handle])
    }

    func testThatItCallsFailedToCheckHandleAvailability() {

        // GIVEN
        let handle = "martha"
        self.userProfileUpdateStatus.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.errorResponse(path: request?.path))

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailRequestToFetchHandle, [handle])
    }

    // MARK: - Setting handle
    func testThatItCallsSuccessSetHandle() {

        // GIVEN
        let handle = "martha"
        self.userProfileUpdateStatus.requestSettingHandle(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.successResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidSetHandle, 1)
    }

    func testThatItCallsFailedToSetHandle() {

        // GIVEN
        let handle = "martha"
        self.userProfileUpdateStatus.requestSettingHandle(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.errorResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailToSetHandle, 1)
    }

    func testThatItCallsFailedToSetHandleBecauseExisting() {

        // GIVEN
        let handle = "martha"
        self.userProfileUpdateStatus.requestSettingHandle(handle: handle)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: self.keyExistsResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailToSetAlreadyExistingHandle, 1)
    }

    // MARK: - Suggesting handles
    func testThatItCallsDidFinddHandleSuggestion() {

        // GIVEN
        self.userProfileUpdateStatus.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        guard let handles = self.userProfileUpdateStatus.suggestedHandlesToCheck, handles.count > 10 else {
            XCTFail()
            return
        }
        let expectedHandle = handles[5]

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        let handlesInResponse = [handles[5], handles[9], handles[10]]
        request?.complete(with: ZMTransportResponse(payload: handlesInResponse as NSArray, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFindHandleSuggestion, [expectedHandle])
    }

    func testThatItCallsFailedToFindHandleSuggestionIfNoHandlesAreReturned() {

        // GIVEN
        self.userProfileUpdateStatus.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let request = self.sut.nextRequest(for: .v0)
        request?.complete(with: ZMTransportResponse(payload: [] as NSArray, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidNotFindAvailableHandleSuggestion, 1)
    }

    func testThatItCallsFailedToFindHandleSuggestionInCaseOfError() {

        // GIVEN
        self.userProfileUpdateStatus.suggestHandles()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        guard let request = self.sut.nextRequest(for: .v0) else {
            XCTFail()
            return
        }
        request.complete(with: self.errorResponse())

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileUpdateStatus.recordedDidFailToFindHandleSuggestion, 1)
    }
}

// MARK: - Helpers
extension UserProfileUpdateRequestStrategyTests {

    func errorResponse(path: String? = nil) -> ZMTransportResponse {
        if let url = path.flatMap(URL.init) {
            return ZMTransportResponse(originalUrl: url, httpStatus: 400, error: nil)
        }

        return ZMTransportResponse(payload: nil,
                                   httpStatus: 400,
                                   transportSessionError: nil,
                                   headers: nil,
                                   apiVersion: APIVersion.v0.rawValue
        )
    }

    func notFoundResponse(path: String? = nil) -> ZMTransportResponse {
        if let url = path.flatMap(URL.init) {
            return ZMTransportResponse(originalUrl: url, httpStatus: 404, error: nil)
        }

        return ZMTransportResponse(payload: nil,
                                   httpStatus: 404,
                                   transportSessionError: nil,
                                   headers: nil,
                                   apiVersion: APIVersion.v0.rawValue
        )
    }

    func badRequestResponse() -> ZMTransportResponse {
        return ZMTransportResponse(payload: ["label": "bad-request"] as NSDictionary,
                                   httpStatus: 400,
                                   transportSessionError: nil,
                                   apiVersion: APIVersion.v0.rawValue)
    }

    func keyExistsResponse() -> ZMTransportResponse {
        return ZMTransportResponse(payload: ["label": "key-exists"] as NSDictionary,
                                   httpStatus: 409,
                                   transportSessionError: nil,
                                   apiVersion: APIVersion.v0.rawValue)
    }

    func invalidPhoneNumberResponse() -> ZMTransportResponse {
        return ZMTransportResponse(payload: ["label": "invalid-phone"] as NSDictionary,
                                   httpStatus: 400,
                                   transportSessionError: nil,
                                   apiVersion: APIVersion.v0.rawValue)
    }

    func lastIdentityResponse() -> ZMTransportResponse {
        return ZMTransportResponse(payload: ["label": "last-identity"] as NSDictionary,
                                   httpStatus: 403,
                                   transportSessionError: nil,
                                   apiVersion: APIVersion.v0.rawValue)
    }

    func invalidEmailResponse() -> ZMTransportResponse {
        return ZMTransportResponse(payload: ["label": "invalid-email"] as NSDictionary,
                                   httpStatus: 400,
                                   transportSessionError: nil,
                                   apiVersion: APIVersion.v0.rawValue)
    }

    func invalidCredentialsResponse() -> ZMTransportResponse {
        return ZMTransportResponse(payload: ["label": "invalid-credentials"] as NSDictionary,
                                   httpStatus: 403,
                                   transportSessionError: nil,
                                   apiVersion: APIVersion.v0.rawValue)
    }

    func successResponse(path: String? = nil) -> ZMTransportResponse {
        if let url = path.flatMap(URL.init) {
            return ZMTransportResponse(originalUrl: url, httpStatus: 200, error: nil)
        }
        return ZMTransportResponse(
            payload: nil,
            httpStatus: 200,
            transportSessionError: nil,
            headers: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }
}

extension ZMTransportResponse {

    convenience init(originalUrl: URL, httpStatus: Int, error: Error?) {
        let headers = ["Content-Type": "application/json"]
        let httpResponse = HTTPURLResponse(url: originalUrl, statusCode: httpStatus, httpVersion: nil, headerFields: headers)
        self.init(httpurlResponse: httpResponse!, data: nil, error: error, apiVersion: APIVersion.v0.rawValue)
    }

}

class TestUserProfileUpdateStatus: UserProfileUpdateStatus {

    var recordedDidFailEmailUpdate: [Error] = []
    var recordedDidUpdateEmailSuccessfully = 0
    var recordedDidRemovePhoneNumberSuccessfully = 0
    var recordedDidFailPhoneNumberRemoval: [Error] = []
    var recordedDidChangePhoneSuccesfully = 0
    var recordedDidFailPasswordUpdate = 0
    var recordedDidUpdatePasswordSuccessfully = 0
    var recordedDidFailChangingPhone: [Error] = []
    var recordedDidRequestPhoneVerificationCodeSuccessfully = 0
    var recordedDidFailPhoneVerificationCodeRequest: [Error] = []
    var recordedDidFetchHandle: [String] = []
    var recordedDidFailRequestToFetchHandle: [String] = []
    var recordedDidNotFindHandle: [String] = []
    var recordedDidSetHandle = 0
    var recordedDidFailToSetHandle = 0
    var recordedDidFailToSetAlreadyExistingHandle = 0
    var recordedDidFailToFindHandleSuggestion = 0
    var recordedDidNotFindAvailableHandleSuggestion = 0
    var recordedDidFindHandleSuggestion: [String] = []

    override func didFailEmailUpdate(error: Error) {
        recordedDidFailEmailUpdate.append(error)
        super.didFailEmailUpdate(error: error)
    }

    override func didUpdateEmailSuccessfully() {
        recordedDidUpdateEmailSuccessfully += 1
        super.didUpdateEmailSuccessfully()
    }

    override func didFailPhoneNumberRemoval(error: Error) {
        recordedDidFailPhoneNumberRemoval.append(error)
        super.didFailPhoneNumberRemoval(error: error)
    }

    override func didRemovePhoneNumberSuccessfully() {
        recordedDidRemovePhoneNumberSuccessfully += 1
        super.didRemovePhoneNumberSuccessfully()
    }

    override func didChangePhoneSuccesfully() {
        recordedDidChangePhoneSuccesfully += 1
        super.didChangePhoneSuccesfully()
    }

    override func didFailPasswordUpdate() {
        recordedDidFailPasswordUpdate += 1
        super.didFailPasswordUpdate()
    }

    override func didUpdatePasswordSuccessfully() {
        recordedDidUpdatePasswordSuccessfully += 1
        super.didUpdatePasswordSuccessfully()
    }

    override func didFailChangingPhone(error: Error) {
        recordedDidFailChangingPhone.append(error)
        super.didFailChangingPhone(error: error)
    }

    override func didRequestPhoneVerificationCodeSuccessfully() {
        recordedDidRequestPhoneVerificationCodeSuccessfully += 1
        super.didRequestPhoneVerificationCodeSuccessfully()
    }

    override func didFailPhoneVerificationCodeRequest(error: Error) {
        recordedDidFailPhoneVerificationCodeRequest.append(error)
        super.didFailPhoneVerificationCodeRequest(error: error)
    }

    override func didFetchHandle(handle: String) {
        recordedDidFetchHandle.append(handle)
        super.didFetchHandle(handle: handle)
    }

    override func didFailRequestToFetchHandle(handle: String) {
        recordedDidFailRequestToFetchHandle.append(handle)
        super.didFailRequestToFetchHandle(handle: handle)
    }

    override func didNotFindHandle(handle: String) {
        recordedDidNotFindHandle.append(handle)
        super.didNotFindHandle(handle: handle)
    }

    override func didSetHandle() {
        recordedDidSetHandle += 1
        super.didSetHandle()
    }

    override func didFailToSetHandle() {
        recordedDidFailToSetHandle += 1
        super.didFailToSetHandle()
    }

    override func didFailToSetAlreadyExistingHandle() {
        recordedDidFailToSetAlreadyExistingHandle += 1
        super.didFailToSetAlreadyExistingHandle()
    }

    override func didNotFindAvailableHandleSuggestion() {
        recordedDidNotFindAvailableHandleSuggestion += 1
        super.didNotFindAvailableHandleSuggestion()
    }

    override func didFailToFindHandleSuggestion() {
        recordedDidFailToFindHandleSuggestion += 1
        super.didFailToFindHandleSuggestion()
    }

    override func didFindHandleSuggestion(handle: String) {
        recordedDidFindHandleSuggestion.append(handle)
        super.didFindHandleSuggestion(handle: handle)
    }
}
