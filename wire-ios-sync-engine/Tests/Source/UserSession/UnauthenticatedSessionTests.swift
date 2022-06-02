//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireTesting
@testable import WireSyncEngine

final class TestUnauthenticatedTransportSession: NSObject, UnauthenticatedTransportSessionProtocol {

    public var cookieStorage = ZMPersistentCookieStorage()

    var nextEnqueueResult: EnqueueResult = .nilRequest
    var lastEnqueuedRequest: ZMTransportRequest?

    func enqueueOneTime(_ request: ZMTransportRequest) {
        lastEnqueuedRequest = request
    }

    func enqueueRequest(withGenerator generator: () -> ZMTransportRequest?) -> EnqueueResult {
        return nextEnqueueResult
    }

    func tearDown() {}
    let environment: BackendEnvironmentProvider = MockEnvironment()

}

@objcMembers
final class MockAuthenticationStatusDelegate: NSObject, ZMAuthenticationStatusDelegate {
    public var authenticationDidSucceedEvents: Int = 0
    public var authenticationDidFailEvents: [Error] = []
    public var authenticationWasRequestedEvents: Int = 0
    public var receivedSSOCode: UUID?

    func authenticationDidFail(_ error: Error!) {
        authenticationDidFailEvents.append(error)
    }

    func authenticationReadyImportingBackup(_ existingAccount: Bool) {
        authenticationDidSucceedEvents += 1
    }

    func authenticationDidSucceed() {
        authenticationDidSucceedEvents += 1
    }

    func loginCodeRequestDidFail(_ error: Error!) {
        authenticationDidFailEvents.append(error)
    }

    func loginCodeRequestDidSucceed() {
        authenticationDidSucceedEvents += 1
    }

    func companyLoginCodeDidBecomeAvailable(_ uuid: UUID!) {
        receivedSSOCode = uuid
    }

    func authenticationWasRequested() {
        authenticationWasRequestedEvents += 1
    }
}

final class MockUnauthenticatedSessionDelegate: NSObject, UnauthenticatedSessionDelegate {

    var existingAccounts = [Account]()
    var existingAccountsCalled = 0
    func session(session: UnauthenticatedSession, isExistingAccount account: Account) -> Bool {
        existingAccountsCalled += 1
        return existingAccounts.contains(account)
    }

    var createdAccounts = [Account]()
    var didUpdateCredentials: Bool = false
    var willAcceptUpdatedCredentials = false
    var isAllowedToCreatingNewAccounts = true

    func session(session: UnauthenticatedSession, createdAccount account: Account) {
        createdAccounts.append(account)
    }

    func session(session: UnauthenticatedSession, updatedProfileImage imageData: Data) {
        // no-op
    }

    func session(session: UnauthenticatedSession, updatedCredentials credentials: ZMCredentials) -> Bool {
        didUpdateCredentials = true
        return willAcceptUpdatedCredentials
    }

    func sessionIsAllowedToCreateNewAccount(_ session: UnauthenticatedSession) -> Bool {
        return isAllowedToCreatingNewAccounts
    }

}

public final class UnauthenticatedSessionTests: ZMTBaseTest {
    var transportSession: TestUnauthenticatedTransportSession!
    var sut: UnauthenticatedSession!
    var mockDelegate: MockUnauthenticatedSessionDelegate!
    var reachability: MockReachability!
    var mockAuthenticationStatusDelegate: MockAuthenticationStatusDelegate!

    public override func setUp() {
        super.setUp()
        transportSession = TestUnauthenticatedTransportSession()
        mockDelegate = MockUnauthenticatedSessionDelegate()
        reachability = MockReachability()
        mockAuthenticationStatusDelegate = MockAuthenticationStatusDelegate()
        sut = UnauthenticatedSession(transportSession: transportSession,
                                     reachability: reachability,
                                     delegate: mockDelegate,
                                     authenticationStatusDelegate: mockAuthenticationStatusDelegate)
        sut.groupQueue.add(dispatchGroup)
    }

    public override func tearDown() {
        sut.tearDown()
        sut = nil
        transportSession = nil
        mockDelegate = nil
        reachability = nil
        super.tearDown()
    }

    func testThatTriesToUpdateCredentials() {
        // given
        let emailCredentials = ZMEmailCredentials(email: "hello@email.com", password: "123456")
        mockDelegate.willAcceptUpdatedCredentials = true

        // when
        sut.login(with: emailCredentials)

        // then
        XCTAssertTrue(mockDelegate.didUpdateCredentials)
    }

    func testThatDuringLoginItThrowsErrorWhenNoCredentials() {
        // given
        reachability.mayBeReachable = false
        // when
        sut.login(with: ZMCredentials())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockAuthenticationStatusDelegate.authenticationDidFailEvents.count, 1)
        XCTAssertEqual(mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].localizedDescription, NSError(code: .needsCredentials, userInfo: nil).localizedDescription)
    }

    func testThatDuringLoginWithEmailItThrowsErrorWhenOffline() {
        // given
        reachability.mayBeReachable = false
        // when
        sut.login(with: ZMEmailCredentials(email: "my@mail.com", password: "my-password"))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        // then
        XCTAssertEqual(mockAuthenticationStatusDelegate.authenticationDidFailEvents.count, 1)
        XCTAssertEqual(mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].localizedDescription,
                       NSError(code: .networkError, userInfo: nil).localizedDescription)
    }

    func testThatDuringLoginWithPhoneNumberItThrowsErrorWhenOffline() {
        // given
        reachability.mayBeReachable = false
        // when
        sut.login(with: ZMPhoneCredentials(phoneNumber: "+49111111111111", verificationCode: "1234"))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        // then
        XCTAssertEqual(mockAuthenticationStatusDelegate.authenticationDidFailEvents.count, 1)
        XCTAssertEqual(mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].localizedDescription, NSError(code: .networkError, userInfo: nil).localizedDescription)
    }

    func testThatItAsksDelegateIfAccountAlreadyExists() throws {
        // given
        let userId = UUID.create()
        let cookie = "zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure"
        let response = try createResponse(cookie: cookie, userId: userId, userIdKey: "id")
        mockDelegate.existingAccounts = [Account(userName: "", userIdentifier: userId)]

        guard let userInfo = response.extractUserInfo() else { return XCTFail("no userinfo") }
        // when
        let exists = sut.accountExistsLocally(from: userInfo)

        // then
        XCTAssertTrue(exists)
        XCTAssertEqual(mockDelegate.existingAccountsCalled, 1)
    }

    func testThatItParsesCookieDataAndDoesCallTheDelegateIfTheCookieIsValidAndThereIsAUserIdKeyUser() throws {
        // given
        let userId = UUID.create()
        let cookie = "zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure"

        // when
        let account = try parseAccount(cookie: cookie, userId: userId, userIdKey: "id")

        // then
        XCTAssertEqual(account.userIdentifier, userId)
        XCTAssertNotNil(transportSession.environment.cookieStorage(for: account).authenticationCookieData)
    }

    func testThatItParsesCookieDataAndDoesCallTheDelegateIfTheCookieIsValidAndThereIsAUserIdKeyId() throws {
        // given
        let userId = UUID.create()
        let cookie = "zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure"

        // when
        let account = try parseAccount(cookie: cookie, userId: userId, userIdKey: "user")

        // then
        XCTAssertEqual(account.userIdentifier, userId)
        XCTAssertNotNil(transportSession.environment.cookieStorage(for: account).authenticationCookieData)
    }

    func testThatItDoesNotParseAnAccountWithWrongUserIdKey() {
        // given
        let cookie = "zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure"

        // then
        performIgnoringZMLogError {
            XCTAssertNil(try? self.parseAccount(cookie: cookie, userIdKey: "identifier"))
        }
    }

    func testThatItDoesNotParseAnAccountWithInvalidCookie() throws {
        // given
        let cookie = "Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure"

        // then
        performIgnoringZMLogError {
            XCTAssertNil(try? self.parseAccount(cookie: cookie, userIdKey: "user"))
        }
    }

    private func createResponse(cookie: String, userId: UUID = .create(), userIdKey: String, line: UInt = #line) throws -> ZMTransportResponse {
        // given
        let headers = [
            "Date": "Thu, 24 Jul 2014 09:06:45 GMT",
            "Content-Encoding": "gzip",
            "Server": "nginx",
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "file://",
            "Connection": "keep-alive",
            "Content-Length": "214",
            "Set-Cookie": cookie
        ]

        return try ZMTransportResponse(headers: headers, payload: [userIdKey: userId.transportString()])
    }

    private func parseAccount(cookie: String, userId: UUID = .create(), userIdKey: String, line: UInt = #line) throws -> Account {
        // given
        let response = try createResponse(cookie: cookie, userId: userId, userIdKey: userIdKey, line: line)

        // when
        response.extractUserInfo().apply(sut.upgradeToAuthenticatedSession)

        // then
        XCTAssertLessThanOrEqual(mockDelegate.createdAccounts.count, 1, line: line)
        if mockDelegate.createdAccounts.isEmpty { throw NSError(domain: "No account", code: 1) }
        return mockDelegate.createdAccounts.first!
    }

}

fileprivate extension ZMTransportResponse {

    convenience init(headers: [String: String], payload: [String: String]) throws {
        let httpResponse = HTTPURLResponse(url: URL(string: "/")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        self.init(httpurlResponse: httpResponse, data: data, error: nil, apiVersion: APIVersion.v0.rawValue)
    }

}
