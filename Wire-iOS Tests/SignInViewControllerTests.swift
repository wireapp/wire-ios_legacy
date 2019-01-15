//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class EmailOnlySignInViewController: SignInViewController {

    override var supportsMultipleFlowTypes: Bool {
        return false
    }

}

final class SignInViewControllerTests: ZMSnapshotTestCase {
    
    var sut: SignInViewController!
    
    override func setUp() {
        super.setUp()
        sut = SignInViewController()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Logic

    func testThatSignInViewControllerCanHandleTheCaseWithLoginCredentialsHasNilEmailButPhoneNumber(){
        // GIVEN
        let credentials = LoginCredentials(emailAddress: nil, phoneNumber: "fake number", hasPassword: false, usesCompanyLogin: false)
        sut.loginCredentials = credentials
        sut.viewDidLoad()

        // WHEN
        sut.signInByPhone(nil)

        // THEN
        XCTAssertEqual(sut.presentedSignInViewController, sut.phoneSignInViewControllerContainer)
    }

    func testThatItDoesNotSwitchToPhoneScreenIfPhoneDisabled() {
        // GIVEN
        let sut = EmailOnlySignInViewController()
        sut.loginCredentials = LoginCredentials(emailAddress: nil, phoneNumber: "+0123456789", hasPassword: false, usesCompanyLogin: false)

        // THEN
        XCTAssertEqual(sut.presentedSignInViewController, sut.emailSignInViewControllerContainer)
    }

    // MARK: - Snapshot

    func testThatItShowsPhoneNumberButtonIfNeeded() {
        // GIVEN
        let sut = SignInViewController()

        // THEN
        let form = wrap(sut)
        verify(view: form.view)
    }

    func testThatItHidesPhoneNumberButtonIfNeeded() {
        // GIVEN
        let sut = EmailOnlySignInViewController()

        // THEN
        let form = wrap(sut)
        verify(view: form.view)
    }

    // MARK: - Helpers

    private func wrap(_ child: UIViewController) -> UIViewController {
        let container = BlueViewController()
        container.addChild(child)
        container.view.addSubview(child.view)
        child.didMove(toParent: container)

        child.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            child.view.bottomAnchor.constraint(equalTo: container.view.bottomAnchor),
        ])

        return container
    }
}
