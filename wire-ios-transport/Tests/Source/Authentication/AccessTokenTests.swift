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

import Foundation

import XCTest
import WireTesting
@testable import WireTransport


final class AccessTokenTests: ZMTBaseTest {
    
    func testThatItStoresTokenAndType() {
        // given
        let token = "MyVeryUniqueToken23423540899874"
        let type = "TestTypew930847923874982374"
    
        // when
        let accessToken = AccessToken(token: token, type: type, expiresInSeconds: 0)
    
        // then
        XCTAssertEqual(accessToken.token, token)
        XCTAssertEqual(accessToken.type, type)
    }
    
    func testThatItCalculatesExpirationDate() {
        
        // given
        let expiresIn: UInt = 15162342
    
        // when
        let accessToken = AccessToken(token: "foo", type: "bar", expiresInSeconds: expiresIn)
    
        // then
        let expiration = Date(timeIntervalSinceNow: Double(expiresIn))
        XCTAssertEqual(
            accessToken.expirationDate.timeIntervalSinceReferenceDate,
            expiration.timeIntervalSinceReferenceDate,
            accuracy: 0.1)
    
    }
    
    func testThatItReturnsHTTPHeaders() {
        // given
        let token = "34rfsdfwe3242"
        let type = "secret-token"
        let accessToken = AccessToken(token: token, type: type, expiresInSeconds: 0)
        let expected: [String: String] = ["Authorization": [type, token].joined(separator: " ")]
    
        // when
        let header = accessToken.httpHeaders
    
        // then
        XCTAssertEqual(header, expected)
    }
}
