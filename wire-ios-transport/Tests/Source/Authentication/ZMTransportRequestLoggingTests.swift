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
import WireTesting
@testable import WireTransport


final class ZMTransportRequestLoggingTests: ZMTBaseTest {

    
    func testThatItObfuscatesPasswordsInLogs() {
        
        //given
        let password = "secret"
        
        let payload: [String:String] = [
            "username":"test@test.xyz",
            "password":password
        ]
        
        //when
        let requestDescription = ZMTransportRequest(path: "/test",
                                                    method: .methodGET,
                                                    payload: payload as ZMTransportData,
                                                    apiVersion: 0).description
        
        //then
        XCTAssertTrue(requestDescription.contains("password = \"<redacted>\""))
        XCTAssertFalse(requestDescription.contains("password = \"\(password)\""))
    }
}

