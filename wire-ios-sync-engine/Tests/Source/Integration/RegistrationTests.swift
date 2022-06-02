//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
@testable import WireSyncEngine

class RegistrationTests: IntegrationTest {

    var delegate: TestRegistrationStatusDelegate!
    var registrationStatus: WireSyncEngine.RegistrationStatus? {
        return sessionManager?.unauthenticatedSession?.registrationStatus
    }
    var teamToRegister: UnregisteredTeam!
    var user: UnregisteredUser!
    var email: String!
    let environment = BackendEnvironment(type: .wire(.staging))

    override func setUp() {
        super.setUp()
        delegate = TestRegistrationStatusDelegate()
        sessionManager?.unauthenticatedSession?.registrationStatus.delegate = delegate
        email = "ba@a-team.de"

        teamToRegister = UnregisteredTeam(teamName: "A-Team", email: email, emailCode: "911", fullName: "Bosco B. A. Baracus", password: "BadAttitude", accentColor: .vividRed)

        user = UnregisteredUser()
        user.name = "Bosco B. A. Baracus"
        user.verificationCode = "911"
        user.credentials = .email(address: email, password: "BadAttitude")
        user.accentColorValue = .vividRed
        user.acceptedTermsOfService = true
        user.marketingConsent = true
    }

    override func tearDown() {
        delegate = nil
        teamToRegister = nil
        user = nil
        super.tearDown()
    }

    // MARK: - send activation code tests

    func testThatIsActivationCodeIsSentToSpecifiedEmail() {
        // Given
        let email = "john@smith.com"
        XCTAssertEqual(delegate.activationCodeSentCalled, 0)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)

        // When
        registrationStatus?.sendActivationCode(to: .email(email))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.activationCodeSentCalled, 1)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)
    }

    func testThatActivationCodeIsSentToSpecifiedPhoneNumber() {
        // Given
        let phone = "+4912345678901"
        XCTAssertEqual(delegate.activationCodeSentCalled, 0)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)

        // When
        registrationStatus?.sendActivationCode(to: .phone(phone))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.activationCodeSentCalled, 1)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)
    }

    func testThatIsActivationCodeSendingFailWhenEmailAlreadyRegistered() {
        // Given
        let email = "john@smith.com"
        XCTAssertEqual(delegate.activationCodeSentCalled, 0)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)

        // When
        self.mockTransportSession.performRemoteChanges { (session) in
            let user = session.insertUser(withName: "john")
            user.email = email
        }

        registrationStatus?.sendActivationCode(to: .email(email))

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.activationCodeSentCalled, 0)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 1)

        let error: NSError? = (delegate.activationCodeSendingFailedError) as NSError?

        XCTAssertNotNil(error)
        XCTAssertEqual(error?.code, Int(ZMUserSessionErrorCode.emailIsAlreadyRegistered.rawValue))
    }

    func testThatActivationCodeSendingFailsWhenPhoneIsAlreadyRegistered() {
        // Given
        let phone = "+4912345678900"
        XCTAssertEqual(delegate.activationCodeSentCalled, 0)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)

        // When
        self.mockTransportSession.performRemoteChanges { (session) in
            let user = session.insertUser(withName: "john")
            user.phone = phone
        }

        registrationStatus?.sendActivationCode(to: .phone(phone))

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.activationCodeSentCalled, 0)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 1)

        let error: NSError? = (delegate.activationCodeSendingFailedError) as NSError?

        XCTAssertNotNil(error)
        XCTAssertEqual(error?.code, Int(ZMUserSessionErrorCode.phoneNumberIsAlreadyRegistered.rawValue))
    }

    func testThatWeCanSendAnActivationCodeTwice_Phone() {
        // Given
        let phone1 = "+4912345678900"
        let phone2 = "+4900000000000"
        XCTAssertEqual(delegate.activationCodeSentCalled, 0)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)

        // When
        registrationStatus?.sendActivationCode(to: .phone(phone1))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        registrationStatus?.sendActivationCode(to: .phone(phone2))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.activationCodeSentCalled, 2)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)
    }

    func testThatWeCanSendAnActivationCodeTwice_Email() {
        // Given
        let email1 = "john@smith.com"
        let email2 = "jane@smith.com"
        XCTAssertEqual(delegate.activationCodeSentCalled, 0)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)

        // When
        registrationStatus?.sendActivationCode(to: .email(email1))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        registrationStatus?.sendActivationCode(to: .email(email2))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.activationCodeSentCalled, 2)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)
    }

    // MARK: - check activation code tests

    func testThatIsActivationCodeIsVerifiedToSpecifiedEmail() {
        // Given
        let email = "john@smith.com"
        self.mockTransportSession.performRemoteChanges { (session) in
            session.whiteListEmail(email)
        }
        let code = self.mockTransportSession.emailActivationCode
        XCTAssertEqual(delegate.activationCodeValidatedCalled, 0)
        XCTAssertEqual(delegate.activationCodeValidationFailedCalled, 0)

        // When
        registrationStatus?.checkActivationCode(credential: .email(email), code: code)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.activationCodeValidatedCalled, 1)
        XCTAssertEqual(delegate.activationCodeValidationFailedCalled, 0)
    }

    func testThatIsActivationCodeIsVerifiedToSpecifiedPhoneNumber() {
        // Given
        let phone = "+4912345678900"
        XCTAssertEqual(delegate.activationCodeValidatedCalled, 0)
        XCTAssertEqual(delegate.activationCodeValidationFailedCalled, 0)

        // When
        registrationStatus?.sendActivationCode(to: .phone(phone))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let code = self.mockTransportSession.phoneVerificationCodeForRegistration
        registrationStatus?.checkActivationCode(credential: .phone(phone), code: code)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.activationCodeValidatedCalled, 1)
        XCTAssertEqual(delegate.activationCodeValidationFailedCalled, 0)
    }

    // MARK: - create team tests

    func testThatWeCanRegisterTeamAndLogInIfWeHaveAValidCode() {
        // given
        XCTAssertEqual(delegate.teamRegisteredCalled, 0)
        XCTAssertEqual(delegate.teamRegistrationFailedCalled, 0)

        // When
        registrationStatus?.create(team: teamToRegister)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.teamRegisteredCalled, 1)
        XCTAssertEqual(delegate.teamRegistrationFailedCalled, 0)
    }

    func testThatAfterRegisteringTeamWeHaveAnAccountAndValidCookie() {
        // When
        registrationStatus?.create(team: teamToRegister)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        let selected = sessionManager?.accountManager.selectedAccount
        XCTAssertNotNil(selected)
        XCTAssertEqual(selected?.cookieStorage(for: environment).isAuthenticated, true)
    }

    func testThatItSignalsAnErrorIfTeamCreationFails() {
        // Given
        self.mockTransportSession.performRemoteChanges { (session) in
            let user = session.insertUser(withName: "john")
            user.email = self.teamToRegister.email
        }

        registrationStatus?.create(team: teamToRegister)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.teamRegisteredCalled, 0)
        XCTAssertEqual(delegate.teamRegistrationFailedCalled, 1)
        let error = (delegate.teamRegistrationFailedError) as NSError?
        XCTAssertNotNil(error)
        XCTAssertEqual(error?.code, Int(ZMUserSessionErrorCode.emailIsAlreadyRegistered.rawValue))
    }

    // MARK: - Create User Tests

    func testThatWeCanRegisterUserAndLogInIfWeHaveAValidCode() {
        // given
        XCTAssertEqual(delegate.userRegisteredCalled, 0)
        XCTAssertEqual(delegate.userRegistrationFailedCalled, 0)

        // When
        registrationStatus?.create(user: user)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.userRegisteredCalled, 1)
        XCTAssertEqual(delegate.userRegistrationFailedCalled, 0)
    }

    func testThatAfterRegisteringUserWeHaveAnAccountAndValidCookie() {
        // When
        registrationStatus?.create(user: user)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        let selected = sessionManager?.accountManager.selectedAccount
        XCTAssertNotNil(selected)
        XCTAssertEqual(selected?.cookieStorage(for: environment).isAuthenticated, true)
    }

    func testThatItSignalsAnErrorIfUserCreationFails() {
        // Given
        self.mockTransportSession.performRemoteChanges { (session) in
            let user = session.insertUser(withName: "john")
            user.email = self.email
        }

        registrationStatus?.create(user: user)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(delegate.userRegisteredCalled, 0)
        XCTAssertEqual(delegate.userRegistrationFailedCalled, 1)

        let error = (delegate.userRegistrationError) as NSError?
        XCTAssertNotNil(error)
        XCTAssertEqual(error?.code, Int(ZMUserSessionErrorCode.emailIsAlreadyRegistered.rawValue))
    }

}
