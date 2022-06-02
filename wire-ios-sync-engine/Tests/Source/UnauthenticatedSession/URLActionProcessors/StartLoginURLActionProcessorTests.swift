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
@testable import WireSyncEngine

class StartLoginURLActionProcessorTests: ZMTBaseTest, WireSyncEngine.UnauthenticatedSessionStatusDelegate {

    var isAllowedToCreateNewAccount: Bool = true
    var sut: WireSyncEngine.StartLoginURLActionProcessor!
    var authenticationStatus: ZMAuthenticationStatus!
    var delegate: MockAuthenticationStatusDelegate!

    override func setUp() {
        super.setUp()

        delegate = MockAuthenticationStatusDelegate()
        let userInfoParser = MockUserInfoParser()
        let groupQueue = DispatchGroupQueue(queue: DispatchQueue.main)
        authenticationStatus = ZMAuthenticationStatus(delegate: delegate,
                                                      groupQueue: groupQueue,
                                                      userInfoParser: userInfoParser)
        sut = WireSyncEngine.StartLoginURLActionProcessor(delegate: self,
                                                          authenticationStatus: authenticationStatus)
    }

    override func tearDown() {
        sut = nil
        delegate = nil
        authenticationStatus = nil

        super.tearDown()
    }

    func testThatAuthenticationStatusChanges_OnStartLoginAction() {
        // given
        isAllowedToCreateNewAccount = true
        let action: URLAction = .startLogin
        let presentationDelegate = MockPresentationDelegate()

        // when
        sut.process(urlAction: action, delegate: presentationDelegate)

        // then
        XCTAssertEqual(delegate.authenticationWasRequestedEvents, 1)
    }

    func testThatStartLoginActionFails_WhenAccountLimitIsReached() {
        // given
        isAllowedToCreateNewAccount = false
        let action: URLAction = .startLogin
        let presentationDelegate = MockPresentationDelegate()

        // when
        sut.process(urlAction: action, delegate: presentationDelegate)

        // then
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.0, action)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.1 as? SessionManager.AccountError, .accountLimitReached)
    }

}
