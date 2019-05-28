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

class URL_WireTests: XCTestCase {

    let be = BackendEnvironment.shared
    
    func testThatWebsiteURLsAreLoadedCorrectly() {
        XCTAssertNotEqual(be.websiteURL.absoluteString, "")
        XCTAssertEqual(URL.wr_website, be.websiteURL)
        XCTAssertEqual(URL.wr_usernameLearnMore, be.websiteURL.appendingPathComponent("support/username"))
        XCTAssertEqual(URL.wr_fingerprintLearnMore, be.websiteURL.appendingPathComponent("privacy/why"))
        XCTAssertEqual(URL.wr_fingerprintHowToVerify, be.websiteURL.appendingPathComponent("privacy/how"))
        XCTAssertEqual(URL.wr_privacyPolicy, be.websiteURL.appendingPathComponent("legal/privacy/embed"))
        XCTAssertEqual(URL.wr_licenseInformation, be.websiteURL.appendingPathComponent("legal/licenses/embed"))
        XCTAssertEqual(URL.wr_reportAbuse, be.websiteURL.appendingPathComponent("support/misuse"))
        XCTAssertEqual(URL.wr_cannotDecryptHelp, be.websiteURL.appendingPathComponent("privacy/error-1"))
        XCTAssertEqual(URL.wr_cannotDecryptNewRemoteIDHelp, be.websiteURL.appendingPathComponent("privacy/error-2"))
        XCTAssertEqual(URL.wr_createTeam, be.websiteURL.appendingPathComponent("create-team?pk_campaign=client&pk_kwd=ios"))
        XCTAssertEqual(URL.wr_createTeamFeatures, be.websiteURL.appendingPathComponent("teams/learnmore"))
        XCTAssertEqual(URL.wr_emailInUseLearnMore, be.websiteURL.appendingPathComponent("support/email-in-use"))
        XCTAssertEqual(URL.wr_termsOfServicesURL(forTeamAccount: true), be.websiteURL.appendingPathComponent("legal/terms/teams"))
        XCTAssertEqual(URL.wr_termsOfServicesURL(forTeamAccount: false), be.websiteURL.appendingPathComponent("legal/terms/personal"))
    }
    
    func testThatSupportURLsAreLoadedCorrectly() {
        XCTAssertNotEqual(WireUrl.shared.support.absoluteString, "")
        XCTAssertEqual(URL.wr_support, WireUrl.shared.support)
        XCTAssertEqual(URL.wr_emailAlreadyInUseLearnMore, WireUrl.shared.support.appendingPathComponent("hc/en-us/articles/115004082129-My-email-address-is-already-in-use-and-I-cannot-create-an-account-What-can-I-do-"))
        XCTAssertEqual(URL.wr_askSupport, WireUrl.shared.support.appendingPathComponent("hc/requests/new"))
    }
    
    func testThatAccountURLsAreLoadedCorrectly() {
        XCTAssertNotEqual(be.accountsURL.absoluteString, "")
        XCTAssertEqual(URL.wr_passwordReset, be.accountsURL.appendingPathComponent("forgot"))
    }
    
    func testThatTeamURLsAreLoadedCorrectly() {
        XCTAssertNotEqual(be.teamsURL.absoluteString, "")
        XCTAssertEqual(URL.wr_manageTeam, be.teamsURL.appendingPathComponent("login?pk_campaign=client&pk_kwd=ios"))
    }
}
