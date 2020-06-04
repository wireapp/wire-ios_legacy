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
    
    var be: BackendEnvironment!
    
    override func setUp() {
        super.setUp()
        let bundle = Bundle.backendBundle
        let defaults = UserDefaults(suiteName: "URLWireTests")!
        EnvironmentType.production.save(in: defaults)
        be = BackendEnvironment(userDefaults: defaults, configurationBundle: bundle)
    }
    
    override func tearDown() {
        be = nil
        super.tearDown()
    }
    
    func testThatWebsiteURLsAreLoadedCorrectly() {
        let websiteURL = URL(string: "https://wire.com")!
        XCTAssertEqual(be.websiteURL, websiteURL)
        XCTAssertEqual(URL.wr_usernameLearnMore, websiteURL.appendingPathComponent("support/username"))
        XCTAssertEqual(URL.wr_fingerprintLearnMore, websiteURL.appendingPathComponent("privacy/why"))
        XCTAssertEqual(URL.wr_fingerprintHowToVerify, websiteURL.appendingPathComponent("privacy/how"))
        XCTAssertEqual(URL.wr_privacyPolicy, websiteURL.appendingPathComponent("legal/privacy/embed"))
        XCTAssertEqual(URL.wr_licenseInformation, websiteURL.appendingPathComponent("legal/licenses/embed"))
        XCTAssertEqual(URL.wr_reportAbuse, websiteURL.appendingPathComponent("support/misuse"))
        XCTAssertEqual(URL.wr_cannotDecryptHelp, websiteURL.appendingPathComponent("privacy/error-1"))
        XCTAssertEqual(URL.wr_cannotDecryptNewRemoteIDHelp, websiteURL.appendingPathComponent("privacy/error-2"))
        XCTAssertEqual(URL.wr_createTeamFeatures, websiteURL.appendingPathComponent("teams/learnmore"))
        XCTAssertEqual(URL.wr_emailInUseLearnMore, websiteURL.appendingPathComponent("support/email-in-use"))
        XCTAssertEqual(URL.wr_termsOfServicesURL(forTeamAccount: true), websiteURL.appendingPathComponent("legal/terms/teams"))
        XCTAssertEqual(URL.wr_termsOfServicesURL(forTeamAccount: false), websiteURL.appendingPathComponent("legal/terms/personal"))
    }
    
    func testThatSupportURLsAreLoadedCorrectly() {
        let supportURL = URL(string: "https://support.wire.com")!
        XCTAssertEqual(WireUrl.shared.support, supportURL)
        XCTAssertEqual(URL.wr_emailAlreadyInUseLearnMore, supportURL.appendingPathComponent("hc/en-us/articles/115004082129-My-email-address-is-already-in-use-and-I-cannot-create-an-account-What-can-I-do-"))
        XCTAssertEqual(URL.wr_askSupport, supportURL.appendingPathComponent("hc/requests/new"))
    }
    
    func testThatAccountURLsAreLoadedCorrectly() {
        let accountsURL = URL(string: "https://account.wire.com")!
        XCTAssertEqual(be.accountsURL, accountsURL)
        XCTAssertEqual(URL.wr_passwordReset, accountsURL.appendingPathComponent("forgot"))
    }    
}
