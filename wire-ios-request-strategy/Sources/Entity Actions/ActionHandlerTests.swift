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

import XCTest
@testable import WireRequestStrategy

class MockAction: EntityAction, Equatable {
    let uuid = UUID()
    var resultHandler: ResultHandler?

    typealias Result = Void
    typealias Failure = Error

    static func == (lhs: MockAction, rhs: MockAction) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

class MockActionHandler: ActionHandler<MockAction> {

    var calledRequestForAction: Bool = false
    override func request(for action: ActionHandler<MockAction>.Action, apiVersion: APIVersion) -> ZMTransportRequest? {
        calledRequestForAction = true
        return ZMTransportRequest(getFromPath: "/mock/request", apiVersion: APIVersion.v0.rawValue)
    }

    var calledHandleResponse: Bool = false
    override func handleResponse(_ response: ZMTransportResponse, action: ActionHandler<MockAction>.Action) {
        calledHandleResponse = true
    }

}

class ActionHandlerTests: MessagingTestBase {

    var sut: MockActionHandler!

    override func setUp() {
        super.setUp()
        self.sut = MockActionHandler(context: uiMOC)
    }

    override func tearDown() {
        self.sut = nil
        super.tearDown()
    }

    func testThatItCallsRequestForAction_WhenActionHasBeenSent() throws {
        // given
        let action = MockAction()
        action.send(in: uiMOC.notificationContext)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        _ = self.sut.nextRequest(for: .v0)

        // then
        XCTAssertTrue(sut.calledRequestForAction)
    }

    func testThatItDoesntCallRequestForAction_WhenActionHasAlreadyBeenConsumed() throws {
        // given
        let action = MockAction()
        action.send(in: uiMOC.notificationContext)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        _ = self.sut.nextRequest(for: .v0)
        sut.calledRequestForAction = false

        // when
        _ = self.sut.nextRequest(for: .v0)

        // then
        XCTAssertFalse(sut.calledRequestForAction)
    }

    func testThatItHandleRequestForAction_WhenResponseArrives() throws {
        // given
        let action = MockAction()
        action.send(in: uiMOC.notificationContext)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let request = self.sut.nextRequest(for: .v0)

        // when
        request?.complete(with: ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.calledHandleResponse)
    }

}
