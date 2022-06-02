//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
@testable import WireRequestStrategy

class CallEventContentTests: XCTestCase {

    private let decoder = JSONDecoder()
    private let remoteMute = "REMOTEMUTE"

    // MARK: - Helpers

    private func eventData(
        type: String,
        callerID: UUID = .create(),
        isVideo: Bool = false,
        resp: Bool = false
    ) -> Data {
        let json: [String: Any] = [
            "type": type,
            "src_userid": callerID.uuidString,
            "resp": resp,
            "props": ["videosend": "\(isVideo)"]
        ]

        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    private func given(
        type: String,
        isVideo: Bool = false,
        resp: Bool = false,
        then assertion: (CallEventContent) -> Void
    ) throws {
        let callerID = UUID.create()
        let data = eventData(type: type, callerID: callerID, isVideo: isVideo, resp: resp)

        // When
        let sut = try XCTUnwrap(CallEventContent(from: data, with: decoder))

        // Then
        assertion(sut)
    }

    // MARK: - Tests

    func test_isRemoteMute() throws {
        try given(type: "REMOTEMUTE") { sut in
            XCTAssertTrue(sut.isRemoteMute)
        }

        try given(type: "FOO") { sut in
            XCTAssertFalse(sut.isRemoteMute)
        }
    }

    func test_IsStartCall() throws {
        try given(type: "SETUP") { sut in
            XCTAssertTrue(sut.isStartCall)
        }

        try given(type: "GROUPSTART") { sut in
            XCTAssertTrue(sut.isStartCall)
        }

        try given(type: "CONFSTART") { sut in
            XCTAssertTrue(sut.isStartCall)
        }

        try given(type: "FOO") { sut in
            XCTAssertFalse(sut.isStartCall)
        }
    }

    func test_isCallEnd() throws {
        try given(type: "CANCEL") { sut in
            XCTAssertTrue(sut.isEndCall)
        }

        try given(type: "GROUPEND") { sut in
            XCTAssertTrue(sut.isEndCall)
        }

        try given(type: "CONFEND") { sut in
            XCTAssertTrue(sut.isEndCall)
        }

        try given(type: "FOO") { sut in
            XCTAssertFalse(sut.isEndCall)
        }
    }

    func test_callState() throws {
        try given(type: "SETUP", isVideo: false, resp: false) { sut in
            XCTAssertEqual(sut.callState, .incomingCall(video: false))
        }

        try given(type: "SETUP", isVideo: true, resp: false) { sut in
            XCTAssertEqual(sut.callState, .incomingCall(video: true))
        }

        try given(type: "SETUP", resp: true) { sut in
            XCTAssertNil(sut.callState)
        }

        try given(type: "CANCEL") { sut in
            XCTAssertEqual(sut.callState, .missedCall(cancelled: true))
        }

        try given(type: "REMOTEMUTE") { sut in
            XCTAssertNil(sut.callState)
        }
    }

}
