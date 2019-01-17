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

class AuthenticationInterfaceBuilderTests: ZMSnapshotTestCase {

    var featureProvider: MockAuthenticationFeatureProvider!
    var builder: AuthenticationInterfaceBuilder!

    override func setUp() {
        super.setUp()
        recordMode = true
        featureProvider = MockAuthenticationFeatureProvider()
        builder = AuthenticationInterfaceBuilder(featureProvider: featureProvider)
    }

    override func tearDown() {
        builder = nil
        featureProvider = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testLandingScreen() {
        runSnapshotTest(for: .landingScreen)
    }

    func testLoginScreen_Phone() {
        runSnapshotTest(for: .provideCredentials(.phone))
    }

    func testLoginScreen_Email() {
        runSnapshotTest(for: .provideCredentials(.email))
    }

    func testLoginScreen_Email_PhoneDisabled() {
        featureProvider.allowOnlyEmailLogin = true
        runSnapshotTest(for: .provideCredentials(.email))
    }

    func testLoginScreen_PhoneNumberVerification() {
        let phoneNumber = UnverifiedCredentials.phone("+0123456789")
        runSnapshotTest(for: .enterActivationCode(phoneNumber, user: UnregisteredUser()))
    }

    func testBackupScreen_NewDevice() {
        runSnapshotTest(for: .noHistory(credentials: nil, context: .newDevice))
    }

    func testBackupScreen_LoggedOut() {
        runSnapshotTest(for: .noHistory(credentials: nil, context: .loggedOut))
    }

    func testTooManyDevicesScreen() {
        runSnapshotTest(for: .clientManagement(clients: [], credentials: nil))
    }

    func testClientRemovalScreen() {
        runSnapshotTest(for: .deleteClient(clients: [mockUserClient()], credentials: nil))
    }

    func testAddEmailPasswordScreen() {
        runSnapshotTest(for: .addEmailAndPassword)
    }

    func testVerifyEmailLinkTests() {
        let credentials = ZMEmailCredentials(email: "test@example.com", password: "12345678")
        runSnapshotTest(for: .pendingEmailLinkVerification(credentials))
    }

    func testReauthenticate_Email() {
        let credentials = LoginCredentials(emailAddress: "test@example.com", phoneNumber: nil, hasPassword: true, usesCompanyLogin: false)
        runSnapshotTest(for: .reauthenticate(credentials: credentials, numberOfAccounts: 1))
    }

    func testReauthenticate_EmailAndPhone() {
        let credentials = LoginCredentials(emailAddress: "test@example.com", phoneNumber: "+33123456789", hasPassword: true, usesCompanyLogin: false)

        // Email should have priority
        runSnapshotTest(for: .reauthenticate(credentials: credentials, numberOfAccounts: 1))
    }

    func testReauthenticate_Phone() {
        let credentials = LoginCredentials(emailAddress: nil, phoneNumber: "+33123456789", hasPassword: true, usesCompanyLogin: false)

        // Email should have priority
        runSnapshotTest(for: .reauthenticate(credentials: credentials, numberOfAccounts: 1))
    }

    func testReauthenticate_CompanyLogin() {
        let credentials = LoginCredentials(emailAddress: nil, phoneNumber: nil, hasPassword: false, usesCompanyLogin: true)
        runSnapshotTest(for: .reauthenticate(credentials: credentials, numberOfAccounts: 1))
    }

    func testReauthenticate_NoCredentials() {
        runSnapshotTest(for: .reauthenticate(credentials: nil, numberOfAccounts: 1))
    }

    // MARK: - Helpers

    private func runSnapshotTest(for step: AuthenticationFlowStep, file: StaticString = #file, line: UInt = #line) {
        if let viewController = builder.makeViewController(for: step) {
            if !step.needsInterface {
                return XCTFail("An interface was generated but we didn't expect one.", file: file, line: line)
            }

            verify(view: viewController.view, file: file, line: line)
        } else {
            XCTAssertFalse(step.needsInterface, "Missing interface.", file: file, line: line)
        }
    }

}
