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

struct MockCompanyLoginLinkResponseContext: CompanyLoginLinkResponseContext {
    var numberOfAccounts: Int
    var userIsInIncompatibleState: Bool
}

class CompanyLoginLinkResponseActionTests: XCTestCase {

    // MARK: - Valid Link

    func testThatItAllowsCompanyLogin_ValidLink_1AccountAndValidState() {
        // GIVEN
        let context = MockCompanyLoginLinkResponseContext(numberOfAccounts: 0, userIsInIncompatibleState: false)

        // WHEN
        let action = context.actionForValidLink()

        // THEN
        XCTAssertEqual(action, .allowStartingFlow)
    }

    func testThatItDoesNotAllowCompanyLogin_ValidLink_NoAccountdAndInvalidState() {
        // GIVEN
        let context = MockCompanyLoginLinkResponseContext(numberOfAccounts: 0, userIsInIncompatibleState: true)

        // WHEN
        let action = context.actionForValidLink()

        // THEN
        XCTAssertEqual(action, .preventStartingFlow)
    }

    func testThatItDoesNotAllowCompanyLogin_ValidLink_3AccountsAndValidState() {
        // GIVEN
        let context = MockCompanyLoginLinkResponseContext(numberOfAccounts: 3, userIsInIncompatibleState: false)

        // WHEN
        let action = context.actionForValidLink()

        // THEN
        XCTAssertEqual(action, .showDismissableAlert(title: "self.settings.add_account.error.title".localized, message: "self.settings.add_account.error.message".localized, allowStartingFlow: false))
    }

    func testThatItDoesNotAllowCompanyLogin_ValidLink_3AccountsAndInvalidState() {
        // GIVEN
        let context = MockCompanyLoginLinkResponseContext(numberOfAccounts: 3, userIsInIncompatibleState: true)

        // WHEN
        let action = context.actionForValidLink()

        // THEN
        XCTAssertEqual(action, .preventStartingFlow)
    }

    // MARK: - Invalid Link

    func testThatItShowsAlert_InvalidLink() {
        // GIVEN
        let context = MockCompanyLoginLinkResponseContext(numberOfAccounts: 3, userIsInIncompatibleState: false)

        // WHEN
        let action = context.actionForInvalidRequest(error: .invalidLink)

        // THEN
        XCTAssertEqual(action, .showDismissableAlert(title: "login.sso.start_error_title".localized, message: "login.sso.link_error_message".localized, allowStartingFlow: false))
    }

    func testThatItDoesntShowAlert_InvalidLink_InvalidState() {
        // GIVEN
        let context = MockCompanyLoginLinkResponseContext(numberOfAccounts: 3, userIsInIncompatibleState: true)

        // WHEN
        let action = context.actionForInvalidRequest(error: .invalidLink)

        // THEN
        XCTAssertEqual(action, .preventStartingFlow)
    }

}
