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

final class SoundcloudServiceTests: XCTestCase {

    var sut: SoundcloudService!
    var sessionMock: MockProxiedURLRequester!

    override func setUp() {
        super.setUp()

        sessionMock = MockProxiedURLRequester()
        sut = SoundcloudService(userSession: sessionMock)!
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        sessionMock = nil
    }

    func testThatloadAudioResourceFromURLConstructsValidRequest() {
        // given
        let url = URL(string: "https://soundcloud.com/goldenbest/ho-ga-toppar-djupa-basar")
        let expectedPath = "/resolve?url=\(url?.absoluteString ?? "")"

        // when
        sut.loadAudioResource(from: url, completion: nil)

        guard let proxyRequest = sessionMock.proxyRequest else {
            XCTFail("proxyRequest should have value after loadAudioResource is called")
            return
        }

        // then
        XCTAssertEqual(proxyRequest.type, ProxiedRequestType.soundcloud)
        XCTAssertEqual(proxyRequest.path, expectedPath)
        XCTAssertEqual(proxyRequest.method, ZMTransportRequestMethod.methodGET)
    }

    func testThatItIgnoresInconsistentResponse() {
        // given
        let responseStructure = ["some", "test", ["some": 1]] as [Any]
        let jsonResponseData: Data = try! JSONSerialization.data(withJSONObject: responseStructure, options: .prettyPrinted)
        let response = URLResponse()

        // when
        let result = sut.audioObject(from: jsonResponseData, response: response)

        // then
        // No crash happened and
        XCTAssertNil(result)
    }

    func testThatItIgnoresNilResponse() {
        // given
        let responseData: Data = Data()
        let response = URLResponse()

        // when
        let result = sut.audioObject(from: responseData, response: response)

        // then
        // No crash happened and
        XCTAssertNil(result)
    }
}
