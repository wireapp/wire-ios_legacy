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

class RegistrationStatusTests: MessagingTest {
    var sut: WireSyncEngine.RegistrationStatus!
    var delegate: MockRegistrationStatusDelegate!
    var email: String!
    var code: String!
    var team: UnregisteredTeam!
    var user: UnregisteredUser!

    override func setUp() {
        super.setUp()

        sut = WireSyncEngine.RegistrationStatus()
        delegate = MockRegistrationStatusDelegate()
        sut.delegate = delegate
        email = "some@foo.bar"
        code = "123456"
        team = UnregisteredTeam(teamName: "Dream Team", email: email, emailCode: "23", fullName: "M. Jordan", password: "qwerty", accentColor: .brightOrange)

        user = UnregisteredUser()
        user.credentials = UnverifiedCredentials.email(email)
        user.name = "M. Jordan"
        user.password = "qwerty"
        user.accentColorValue = .brightOrange
        user.verificationCode = code
        user.acceptedTermsOfService = true
        user.marketingConsent = true
    }

    override func tearDown() {
        sut = nil
        delegate = nil
        email = nil
        code = nil
        team = nil
        user = nil
        super.tearDown()
    }

    // MARK: - .none state tests

    func testStartWithPhaseNone() {
        XCTAssertEqual(sut.phase, .none)
    }

    func testThatItIgnoresHandleErrorWhenInNoneState() {
        // given
        let error = NSError(domain: "some", code: 2, userInfo: [:])

        // when
        sut.handleError(error)

        // then
        XCTAssertEqual(sut.phase, .none)
    }

    func testThatItIgnoresSuccessWhenInNoneState() {
        // when
        sut.success()

        // then
        XCTAssertEqual(sut.phase, .none)
    }

    // MARK: - Send activation code tests

    func testThatItAdvancesToSendActivationCodeStateAfterTrigerringSendingStarts() {
        // when
        sut.sendActivationCode(to: .email(email))

        // then
        XCTAssertEqual(sut.phase, .sendActivationCode(credentials: .email(email)))
    }

    func testThatItInformsTheDelegateAboutActivationCodeSendingSuccess() {
        // given
        sut.sendActivationCode(to: .email(email))
        XCTAssertEqual(delegate.activationCodeSentCalled, 0)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)

        // when
        sut.success()

        // then
        XCTAssertEqual(delegate.activationCodeSentCalled, 1)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)
    }

    func testThatItInformsTheDelegateAboutActivationCodeSendingError() {
        // given
        let error = NSError(domain: "some", code: 2, userInfo: [:])
        sut.sendActivationCode(to: .email(email))
        XCTAssertEqual(delegate.activationCodeSentCalled, 0)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 0)

        // when
        sut.handleError(error)

        // then
        XCTAssertEqual(delegate.activationCodeSentCalled, 0)
        XCTAssertEqual(delegate.activationCodeSendingFailedCalled, 1)
        XCTAssertEqual(delegate.activationCodeSendingFailedError as NSError?, error)
    }

    // MARK: - Check activation code tests
    func testThatItAdvancesToCheckActivationCodeStateAfterTriggeringCheck() {
        // when
        sut.checkActivationCode(credentials: .email(email), code: code)

        // then
        XCTAssertEqual(sut.phase, .checkActivationCode(credentials: .email(email), code: code))
    }

    func testThatItInformsTheDelegateAboutCheckActivationCodeSuccess() {
        // given
        sut.checkActivationCode(credentials: .email(email), code: code)
        XCTAssertEqual(delegate.activationCodeValidatedCalled, 0)
        XCTAssertEqual(delegate.activationCodeValidationFailedCalled, 0)

        // when
        sut.success()

        // then
        XCTAssertEqual(delegate.activationCodeValidatedCalled, 1)
        XCTAssertEqual(delegate.activationCodeValidationFailedCalled, 0)
    }

    func testThatItInformsTheDelegateAboutCheckActivationCodeError() {
        // given
        let error = NSError(domain: "some", code: 2, userInfo: [:])
        sut.checkActivationCode(credentials: .email(email), code: code)
        XCTAssertEqual(delegate.activationCodeValidatedCalled, 0)
        XCTAssertEqual(delegate.activationCodeValidationFailedCalled, 0)

        // when
        sut.handleError(error)

        // then
        XCTAssertEqual(delegate.activationCodeValidatedCalled, 0)
        XCTAssertEqual(delegate.activationCodeValidationFailedCalled, 1)
        XCTAssertEqual(delegate.activationCodeValidationFailedError as NSError?, error)
    }

    // MARK: - Team creation

    func testThatItAdvancesToCreateTeamStateAfterTriggeringCreationStarts() {
        // when
        sut.create(team: team)

        // then
        XCTAssertEqual(sut.phase, .createTeam(team: team))
    }

    func testThatItInformsTheDelegateAboutCreateTeamSuccess() {
        // given
        sut.create(team: team)
        XCTAssertEqual(delegate.teamRegisteredCalled, 0)
        XCTAssertEqual(delegate.teamRegistrationFailedCalled, 0)

        // when
        sut.success()

        // then
        XCTAssertTrue(sut.completedRegistration)
        XCTAssertEqual(delegate.teamRegisteredCalled, 1)
        XCTAssertEqual(delegate.teamRegistrationFailedCalled, 0)
    }

    func testThatItInformsTheDelegateAboutCreateTeamError() {
        // given
        let error = NSError(domain: "some", code: 2, userInfo: [:])
        sut.create(team: team)
        XCTAssertEqual(delegate.teamRegisteredCalled, 0)
        XCTAssertEqual(delegate.teamRegistrationFailedCalled, 0)

        // when
        sut.handleError(error)

        // then
        XCTAssertEqual(delegate.teamRegisteredCalled, 0)
        XCTAssertEqual(delegate.teamRegistrationFailedCalled, 1)
        XCTAssertEqual(delegate.teamRegistrationFailedError as NSError?, error)
    }

    // MARK: - User Creation

    func testThatItAdvancesToCreateUserStateAfterTriggeringCreationStarts() {
        // when
        sut.create(user: user)

        // then
        XCTAssertEqual(sut.phase, .createUser(user: user))
    }

    func testThatItInformsTheDelegateAboutCreateUserSuccess() {
        // given
        sut.create(user: user)
        XCTAssertEqual(delegate.userRegisteredCalled, 0)
        XCTAssertEqual(delegate.userRegistrationFailedCalled, 0)

        // when
        sut.success()

        // then
        XCTAssertTrue(sut.completedRegistration)
        XCTAssertEqual(delegate.userRegisteredCalled, 1)
        XCTAssertEqual(delegate.userRegistrationFailedCalled, 0)
    }

    func testThatItInformsTheDelegateAboutCreateUserError() {
        // given
        let error = NSError(domain: "some", code: 2, userInfo: [:])
        sut.create(user: user)
        XCTAssertEqual(delegate.userRegisteredCalled, 0)
        XCTAssertEqual(delegate.userRegistrationFailedCalled, 0)

        // when
        sut.handleError(error)

        // then
        XCTAssertEqual(delegate.userRegisteredCalled, 0)
        XCTAssertEqual(delegate.userRegistrationFailedCalled, 1)
        XCTAssertEqual(delegate.userRegistrationError as NSError?, error)
    }

}
