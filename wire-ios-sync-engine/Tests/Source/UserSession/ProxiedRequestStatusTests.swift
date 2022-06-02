//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

class MockRequestCancellation: NSObject, ZMRequestCancellation {

    var canceledTasks: [ZMTaskIdentifier] = []

    func cancelTask(with taskIdentifier: ZMTaskIdentifier) {
        canceledTasks.append(taskIdentifier)
    }
}

class ProxiedRequestsStatusTests: MessagingTest {

    fileprivate var sut: ProxiedRequestsStatus!
    fileprivate var mockRequestCancellation: MockRequestCancellation!

    override func setUp() {
        super.setUp()
        self.mockRequestCancellation = MockRequestCancellation()
        self.sut = ProxiedRequestsStatus(requestCancellation: mockRequestCancellation)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testThatRequestIsAddedToPendingRequest() {
        // given
        let request = ProxyRequest(type: .giphy, path: "foo/bar", method: .methodGET, callback: nil)

        // when
        self.sut.add(request: request)

        // then
        let pendingRequest = self.sut.pendingRequests.first
        XCTAssertEqual(pendingRequest, request)
    }

    func testCancelRemovesRequestFromPendingRequests() {
        // given
        let request = ProxyRequest(type: .giphy, path: "foo/bar", method: .methodGET, callback: nil)
        sut.add(request: request)

        // when
        sut.cancel(request: request)

        // then
        XCTAssertTrue(sut.pendingRequests.isEmpty)
    }

    func testCancelCancelsAssociatedDataTask() {
        // given
        let request = ProxyRequest(type: .giphy, path: "foo/bar", method: .methodGET, callback: nil)
        let taskIdentifier = ZMTaskIdentifier(identifier: 0, sessionIdentifier: "123")!
        sut.executedRequests[request] = taskIdentifier

        // when
        sut.cancel(request: request)

        // then
        XCTAssertEqual(mockRequestCancellation.canceledTasks.first, taskIdentifier)
    }

}
