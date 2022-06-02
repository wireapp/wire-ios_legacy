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

import Foundation

class MockTransportSessionAPIVersionTests: MockTransportSessionTests {

    func testThatItReturnsAPIVersionInfo() {
        // Given
        let path = "/api-version"
        sut.supportedAPIVersions = [0, 1, 2, 3]
        sut.domain = "foo.com"
        sut.federation = true

        // Then
        let response = self.response(forPayload: [:] as ZMTransportData,
                                     path: path,
                                     method: .methodGET,
                                     apiVersion: .v0)

        // Then
        XCTAssertEqual(response?.httpStatus, 200)

        let payload = response?.payload?.asDictionary()
        XCTAssertEqual(payload?["supported"] as? [Int32], sut.supportedAPIVersions.map(\.int32Value))
        XCTAssertEqual(payload?["domain"] as? String, sut.domain)
        XCTAssertEqual(payload?["federation"] as? Bool, sut.federation)
    }

    func testThatItReturns404IfAPIVersionEndpointIsUnavailable() {
        // Given
        let path = "/api-version"
        sut.isAPIVersionEndpointAvailable = false

        // Then
        let response = self.response(forPayload: [:] as ZMTransportData,
                                     path: path,
                                     method: .methodGET,
                                     apiVersion: .v0)

        // Then
        XCTAssertEqual(response?.httpStatus, 404)
    }

    // TODO: [John] Uncomment when we add API version 1.

//    func testThatItReturns404IfAPIVersionIsNotZero() {
//        // Given
//        let path = "/api-version"
//
//        // Then
//        let response = self.response(forPayload: [:] as ZMTransportData,
//                                     path: path,
//                                     method: .methodGET,
//                                     apiVersion: .v1)
//
//        // Then
//        XCTAssertEqual(response?.httpStatus, 404)
//    }

}
