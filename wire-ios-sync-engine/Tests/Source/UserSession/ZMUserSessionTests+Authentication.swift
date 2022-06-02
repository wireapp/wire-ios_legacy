////
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
@testable import WireSyncEngine

class ZMUserSessionTests_Authentication: ZMUserSessionTestsBase {

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedBlockAndWait {
            self.createSelfClient()
        }
    }

    func testThatIsLoggedInIsFalseAtStartup() {
        // then
        XCTAssertFalse(sut.isLoggedIn)
    }

    func testThatIsLoggedInIsTrueIfItHasACookieAndSelfUserRemoteIdAndRegisteredClientID() {
        // when
        simulateLoggedInUser()

        // then
        XCTAssertTrue(sut.isLoggedIn)
    }

    func testThatItEnqueuesRequestToDeleteTheSelfClient() {
        // given
        let selfClient = ZMUser.selfUser(in: uiMOC).selfClient()!
        let credentials = ZMEmailCredentials(email: "john.doe@domain.com", password: "123456")

        // when
        sut.logout(credentials: credentials, {_ in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let request = transportSession.lastEnqueuedRequest!
        let payload = request.payload as? [String: Any]
        XCTAssertEqual(request.method, ZMTransportRequestMethod.methodDELETE)
        XCTAssertEqual(request.path, "/clients/\(selfClient.remoteIdentifier!)")
        XCTAssertEqual(payload?["password"] as? String, credentials.password)
    }

    func testThatItEnqueuesRequestToDeleteTheSelfClientWithoutPassword() {
        // given
        let selfClient = ZMUser.selfUser(in: uiMOC).selfClient()!
        let credentials = ZMEmailCredentials(email: "john.doe@domain.com", password: "")

        // when
        sut.logout(credentials: credentials, {_ in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let request = transportSession.lastEnqueuedRequest!
        let payload = request.payload as? [String: Any]
        XCTAssertEqual(request.method, ZMTransportRequestMethod.methodDELETE)
        XCTAssertEqual(request.path, "/clients/\(selfClient.remoteIdentifier!)")
        XCTAssertEqual(payload?.keys.count, 0)
    }

    func testThatItPostsNotification_WhenLogoutRequestSucceeds() {
        // given
        let userSessionDelegate = MockUserSessionDelegate()
        sut.delegate = userSessionDelegate
        let credentials = ZMEmailCredentials(email: "john.doe@domain.com", password: "123456")

        // when
        sut.logout(credentials: credentials, {_ in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        transportSession.lastEnqueuedRequest?.complete(with: ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNotNil(userSessionDelegate.calleduserDidLogout)
        XCTAssertEqual(userSessionDelegate.calleduserDidLogout?.0, true)
        XCTAssertEqual(userSessionDelegate.calleduserDidLogout?.1, ZMUser.selfUser(in: uiMOC).remoteIdentifier)
    }

    func testThatItCallsTheCompletionHandler_WhenLogoutRequestSucceeds() {
        // given
        let credentials = ZMEmailCredentials(email: "john.doe@domain.com", password: "123456")

        // expect
        let completionHandlerCalled = expectation(description: "Completion handler called")

        // when
        sut.logout(credentials: credentials, {result in
            switch result {
            case .success:
                completionHandlerCalled.fulfill()
            case .failure:
                XCTFail()
            }
        })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        transportSession.lastEnqueuedRequest?.complete(with: ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCallsTheCompletionHandlerWithCorrectErrorCode_WhenLogoutRequestFails() {
        checkThatItCallsTheCompletionHandler(with: .clientDeletedRemotely, for: ZMTransportResponse(payload: ["label": "client-not-found"] as ZMTransportData, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        checkThatItCallsTheCompletionHandler(with: .invalidCredentials, for: ZMTransportResponse(payload: ["label": "invalid-credentials"] as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        checkThatItCallsTheCompletionHandler(with: .invalidCredentials, for: ZMTransportResponse(payload: ["label": "missing-auth"]  as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        checkThatItCallsTheCompletionHandler(with: .invalidCredentials, for: ZMTransportResponse(payload: ["label": "bad-request"]  as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
    }

    func checkThatItCallsTheCompletionHandler(with errorCode: ZMUserSessionErrorCode, for response: ZMTransportResponse) {
        // given
        let credentials = ZMEmailCredentials(email: "john.doe@domain.com", password: "123456")

        // expect
        let completionHandlerCalled = expectation(description: "Completion handler called")

        // when
        sut.logout(credentials: credentials, {result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                if errorCode == (error as NSError).userSessionErrorCode {
                    completionHandlerCalled.fulfill()
                }

            }
        })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        transportSession.lastEnqueuedRequest?.complete(with: response)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

}
