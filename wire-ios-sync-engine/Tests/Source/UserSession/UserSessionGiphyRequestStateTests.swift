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
@testable import WireSyncEngine

class UserSessionGiphyRequestStateTests: ZMUserSessionTestsBase {

    func testThatMakingRequestAddsPendingRequest() {

        // given
        let path = "foo/bar"
        let url = URL(string: path, relativeTo: nil)!

        let exp = self.expectation(description: "expected callback")
        let callback: (Data?, HTTPURLResponse?, Error?) -> Void = { (_, _, _) -> Void in
            exp.fulfill()
        }

        // when
        self.sut.proxiedRequest(path: url.absoluteString, method: .methodGET, type: .giphy, callback: callback)

        // then
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let request = self.sut.applicationStatusDirectory?.proxiedRequestStatus.pendingRequests.first
        XCTAssert(request != nil)
        XCTAssertEqual(request!.path, path)
        XCTAssert(request!.callback != nil)
        request!.callback!(nil, HTTPURLResponse(), nil)
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatAddingRequestStartsOperationLoop() {

        // given
        let exp = self.expectation(description: "new operation loop started")
        let token = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "RequestAvailableNotification"), object: nil, queue: nil) { (_) -> Void in
            exp.fulfill()
        }

        let url = URL(string: "foo/bar", relativeTo: nil)!
        let callback: (Data?, URLResponse?, Error?) -> Void = { (_, _, _) -> Void in }

        // when
        self.sut.proxiedRequest(path: url.absoluteString, method: .methodGET, type: .giphy, callback: callback)

        // then
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))

        NotificationCenter.default.removeObserver(token)
    }

    func testThatAddingRequestIsMadeOnSyncThread() {

        // given
        let url = URL(string: "foo/bar", relativeTo: nil)!
        let callback: (Data?, URLResponse?, Error?) -> Void = { (_, _, _) -> Void in }

        // here we block sync thread and check that right after giphyRequestWithURL call no request is created
        // after we signal semaphore sync thread should be unblocked and pending request should be created
        let sem = DispatchSemaphore(value: 0)
        self.syncMOC.performGroupedBlock {
            _ = sem.wait(timeout: DispatchTime.distantFuture)
        }

        // when
        self.sut.proxiedRequest(path: url.absoluteString, method: .methodGET, type: .giphy, callback: callback)

        // then
        var request = self.sut.applicationStatusDirectory?.proxiedRequestStatus.pendingRequests.first
        XCTAssertTrue(request == nil)

        // when
        sem.signal()

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        request = self.sut.applicationStatusDirectory?.proxiedRequestStatus.pendingRequests.first
        XCTAssert(request != nil)
    }

}
