//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

class DigitalSignatureVerificationViewControllerTest: XCTestCase {

    var sut: DigitalSignatureVerificationViewController!

    override func setUp() {
        let mainURL = URL(string: "https://ais-sas.swisscom.com/sas/web/tkeb8ac3f9bf794cfd90ccc7741c11c908tx/otp?lang=en")!
        sut = DigitalSignatureVerificationViewController(url: mainURL)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatParseDigitalSignatureVerificationURLReturnsSuccess() {
        // given
        let successURL = URL(string: "https://ais-sas.swisscom.com/sas/web/success?lang=en&postCode=sas-success")!

        // when
        let response = sut.parseVerificationURL(successURL)

        // then
        guard case .success? = response else {
            XCTFail()
            return
        }
    }

    func testThatParseDigitalSignatureVerificationURLReturnsError() {
        // given
         let failedURL = URL(string: "https://ais-sas.swisscom.com/sas/web/error?lang=en&errorCode=authenticationFailed.numberOfRetryAttemptsExceeded&postCode=sas-error-authentication-failed")!

        // when
        let response = sut.parseVerificationURL(failedURL)

        // then
        guard case .failure? = response else {
            XCTFail()
            return
        }
    }
}
