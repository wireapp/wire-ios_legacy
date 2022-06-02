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
@testable import WireSyncEngine

class CompanyLoginActionTests: XCTestCase {

    var userDefaults: UserDefaults!
    var currentToken: CompanyLoginVerificationToken!

    override func setUp() {
        userDefaults = UserDefaults(suiteName: name)
        currentToken = CompanyLoginVerificationToken()
        currentToken.store(in: userDefaults)
    }

    override func tearDown() {
        CompanyLoginVerificationToken.flush(in: userDefaults)
        currentToken = nil
        userDefaults = nil
    }

    func testThatItParsesLoginSuccessResponse() throws {
        // GIVEN
        let userID = UUID(uuidString: "0AEF17E9-BBA6-4F6D-BF79-6260AABB5457")!
        let url = URL(string: "wire-sso://login/success?userid=\(userID)&validation_token=\(currentToken.uuid)&cookie=\(testCookie)")!

        // WHEN
        guard let action = try URLAction(url: url, validatingIn: userDefaults) else {
            XCTFail("No action was returned.")
            return
        }

        // THEN
        guard case let URLAction.companyLoginSuccess(userInfo) = action else {
            XCTFail("The action is not a success (\(action)")
            return
        }

        XCTAssertEqual(userInfo.identifier, userID)
    }

    func testThatItRejectsUnverifiedLoginSuccessResponse() {
        // GIVEN
        let unverifiedToken = CompanyLoginVerificationToken()
        let userID = UUID(uuidString: "0AEF17E9-BBA6-4F6D-BF79-6260AABB5457")!
        let url = URL(string: "wire-sso://login/success?userid=\(userID)&validation_token=\(unverifiedToken.uuid)&cookie=\(testCookie)")!

        // THEN
        XCTAssertThrowsError(try URLAction(url: url, validatingIn: userDefaults)) { (error) in
            XCTAssertEqual(error as? CompanyLoginError, .tokenNotFound)
        }
    }

    func testThatItDecodesKnownUserLabel() {
        // GIVEN
        let url = URL(string: "wire-sso://login/failure?label=bad-username&validation_token=\(currentToken.uuid)")!

        // THEN
        XCTAssertThrowsError(try URLAction(url: url, validatingIn: userDefaults)) { (error) in
            XCTAssertEqual(error as? CompanyLoginError, .badUsername)
        }
    }

    func testThatItFallbacksToZeroErrorCodeWhenDecodingUnknownUserLabel() {
        // GIVEN
        let url = URL(string: "wire-sso://login/failure?label=something_went_wrong&validation_token=\(currentToken.uuid)")!

        // THEN
        XCTAssertThrowsError(try URLAction(url: url, validatingIn: userDefaults)) { (error) in
            XCTAssertEqual(error as? CompanyLoginError, .unknownLabel)
        }
    }

    // MARK: - Utilities

    private var testCookie: String {
        return "zuid%3D00000-000000000_000000000000000000000000000000000000000000000000000000_0000000-00000000%3D%3D.v%3D1.k%3D1.d%3D0000000000.t%3Du.l%3Ds.u%3D00000000-0000-0000-0000-000000000000.r%3D00000000%3B%20Path%3D/access%3B%20Domain%3Dzinfra.io%3B%20HttpOnly%3B%20Secure"
    }

}
