//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

class CompanyLoginURLActionProcessorTests: ZMTBaseTest, WireSyncEngine.UnauthenticatedSessionStatusDelegate {

    var isAllowedToCreateNewAccount: Bool = true
    var sut: WireSyncEngine.CompanyLoginURLActionProcessor!
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
        sut = WireSyncEngine.CompanyLoginURLActionProcessor(delegate: self, authenticationStatus: authenticationStatus)
    }

    override func tearDown() {
        sut = nil
        delegate = nil
        authenticationStatus = nil

        super.tearDown()
    }

    func testThatAuthenticationStatusIsInformed_OnCompanyLoginSuccessAction() {
        // given
        let accountId = UUID()
        let cookieData = "cookie".data(using: .utf8)!
        let userInfo = UserInfo(identifier: accountId, cookieData: cookieData)
        let action: URLAction = .companyLoginSuccess(userInfo: userInfo)

        // when
        sut.process(urlAction: action, delegate: nil)

        // then
        XCTAssertEqual(authenticationStatus.authenticatedUserIdentifier, accountId)
    }

    func testThatStartCompanyLoginActionFails_WhenAccountLimitIsReached() {
        // given
        isAllowedToCreateNewAccount = false
        let ssoCode = UUID()
        let action: URLAction = .startCompanyLogin(code: ssoCode)
        let presentationDelegate = MockPresentationDelegate()

        // when
        sut.process(urlAction: action, delegate: presentationDelegate)

        // then
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.0, action)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.1 as? SessionManager.AccountError, .accountLimitReached)
    }

    func testThatSSOCodeIsPropagatedToAuthenticationStatus_OnStartCompanyLoginAction() {
        // given
        let ssoCode = UUID()
        let action: URLAction = .startCompanyLogin(code: ssoCode)

        // when
        sut.process(urlAction: action, delegate: nil)

        // then
        XCTAssertEqual(delegate.receivedSSOCode, ssoCode)
    }
}
