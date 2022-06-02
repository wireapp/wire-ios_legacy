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
import avs
@testable import WireSyncEngine

class AVSBridgingTests: MessagingTest {

    var rawString: UnsafePointer<CChar>!
    var rawUUID: UnsafePointer<CChar>!
    var rawTrue: Int32!
    var rawFalse: Int32!
    var rawEnumWithFallback: Int32!
    var rawInvalidEnumWithFallback: Int32!
    var rawEnumWithoutFallback: Int32!
    var rawInvalidEnumWithoutFallback: Int32!

    var userID: AVSIdentifier!
    var clientID: String!
    var callCenter: WireCallCenterV3!
    var callCenterRef: UnsafeMutableRawPointer!

    override func setUp() {
        super.setUp()
        rawString = makeCString("Wire")
        rawUUID = makeCString("D2BC8C1E-43DE-4BE8-8868-A66BF565A842")
        rawTrue = 1
        rawFalse = 0
        rawEnumWithFallback = WCALL_REASON_NORMAL
        rawInvalidEnumWithFallback = -1
        rawEnumWithoutFallback = 3
        rawInvalidEnumWithoutFallback = 5

        userID = AVSIdentifier.stub
        clientID = UUID().uuidString
        let avsWrapper = MockAVSWrapper(userId: userID, clientId: clientID, observer: nil)
        callCenter = WireCallCenterV3(userId: userID, clientId: clientID, avsWrapper: avsWrapper, uiMOC: uiMOC, flowManager: FlowManagerMock(), transport: WireCallCenterTransportMock())
        callCenterRef = Unmanaged.passUnretained(callCenter).toOpaque()
    }

    override func tearDown() {
        rawString.deallocate()
        rawString = nil
        rawUUID.deallocate()
        rawUUID = nil
        rawTrue = nil
        rawFalse = nil
        rawEnumWithFallback = nil
        rawInvalidEnumWithFallback = nil
        rawEnumWithoutFallback = nil
        rawInvalidEnumWithoutFallback = nil
        userID = nil
        clientID = nil
        callCenter = nil
        callCenterRef = nil
        super.tearDown()
    }

    func testThatItDecodesBasicTypes() {
        // WHEN
        let string = String(rawValue: rawString)
        let uuid = UUID(rawValue: rawUUID)
        let invalidUUID = UUID(rawValue: rawString)
        let trueBool = Bool(rawValue: rawTrue)
        let falseBool = Bool(rawValue: rawFalse)
        let callEndNormal = CallClosedReason(rawValue: rawEnumWithFallback)
        let callEndInvalid = CallClosedReason(rawValue: rawInvalidEnumWithFallback)
        let videoState = VideoState(rawValue: rawEnumWithoutFallback)
        let invalidVideoState = VideoState(rawValue: rawInvalidEnumWithoutFallback)

        // THEN
        XCTAssertEqual(string, "Wire")
        XCTAssertEqual(uuid?.uuidString, "D2BC8C1E-43DE-4BE8-8868-A66BF565A842")
        XCTAssertNil(invalidUUID)
        XCTAssertEqual(trueBool, true)
        XCTAssertEqual(falseBool, false)
        XCTAssertEqual(callEndNormal, .normal)
        XCTAssertEqual(callEndInvalid, .unknown)
        XCTAssertEqual(videoState, .paused)
        XCTAssertNil(invalidVideoState)

        // TEAR DOWN
    }

    func testThatItDecodesCallCenter() {
        let result = AVSWrapper.withCallCenter(callCenterRef) {
            XCTAssertEqual($0.selfUserId, userID)
        }

        XCTAssertEqual(result, 0)
        XCTAssertNotEqual(result, EINVAL)
    }

    func testThatItDecodesArgumentsInOrder_1() {
        let result = AVSWrapper.withCallCenter(callCenterRef, rawString) {
            checkDecodingResult($0, $1)
        }

        XCTAssertEqual(result, 0)
        XCTAssertNotEqual(result, EINVAL)
    }

    func testThatItDecodesArgumentsInOrder_2() {
        let result = AVSWrapper.withCallCenter(callCenterRef, rawString, rawUUID) {
            checkDecodingResult($0, $1, $2)
        }

        XCTAssertEqual(result, 0)
        XCTAssertNotEqual(result, EINVAL)
    }

    func testThatItReturnsInvalidArgumentWhenDecodingFails() {
        let result = AVSWrapper.withCallCenter(callCenterRef, rawString) {
            checkDecodingResult($0, uuid: $1)
        }

        XCTAssertEqual(result, EINVAL)
    }

    // MARK: - Helpers

    private func checkDecodingResult(_ center: WireCallCenterV3, _ string: String) {
        XCTAssertEqual(center.selfUserId, userID)
        XCTAssertEqual(string, "Wire")
    }

    private func checkDecodingResult(_ center: WireCallCenterV3, _ string: String, _ uuidString: String) {
        XCTAssertEqual(center.selfUserId, userID)
        XCTAssertEqual(string, "Wire")
        XCTAssertEqual(uuidString, "D2BC8C1E-43DE-4BE8-8868-A66BF565A842")
    }

    func checkDecodingResult(_ center: WireCallCenterV3, uuid: UUID) {
        XCTAssertEqual(center.selfUserId, userID)
        XCTAssertEqual(uuid.uuidString, "D2BC8C1E-43DE-4BE8-8868-A66BF565A842")
    }

    private func makeCString(_ string: String) -> UnsafePointer<CChar> {
        let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: string.utf8.count)
        strcpy(ptr, string)
        return UnsafePointer(ptr)
    }

}
