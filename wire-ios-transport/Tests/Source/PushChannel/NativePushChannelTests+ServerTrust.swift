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
@testable import WireTransport

class MockURLProtectionSpace: URLProtectionSpace {

    var mockServerTrust: SecTrust?

    override var serverTrust: SecTrust? {
        return mockServerTrust
    }
}

@available(iOS 13.0, *)
class NativePushChannelTests_ServerTrust: XCTestCase {

    var mockEnvironment: MockEnvironment!
    var mockSchedulerSession: FakeSchedulerSession!
    var certificates: CertificateData!
    var sut: NativePushChannel!

    override func setUpWithError() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let mainBundle = Bundle(for: type(of: self))
        let certificatesURL = try XCTUnwrap(mainBundle.url(forResource: "certificates", withExtension: "json"))
        let certsData = try XCTUnwrap(Data(contentsOf: certificatesURL))
        self.certificates = try XCTUnwrap(decoder.decode(CertificateData.self, from: certsData))

        mockSchedulerSession = FakeSchedulerSession()
        mockEnvironment = MockEnvironment()

        let dispatchGroup = ZMSDispatchGroup(label: "scheduler")!
        let scheduler = ZMTransportRequestScheduler(session: mockSchedulerSession,
                                    operationQueue: .main,
                                    group: dispatchGroup,
                                    reachability: FakeReachability(),
                                    backoff: ZMExponentialBackoff(group: dispatchGroup, work: .main))

        sut = NativePushChannel(scheduler: scheduler,
                                userAgentString: "user-agent",
                                environment: mockEnvironment,
                                queue: .main)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockSchedulerSession = nil
        mockEnvironment = nil
        certificates = nil
    }

    func testThatItPerformsDefaultHandling_WhenServerIsTrusted() throws {
        // given
        mockEnvironment.isServerTrusted = true

        // when
        var choosenDisposition: URLSession.AuthChallengeDisposition = .useCredential
        sut.urlSession(URLSession.shared,
                       task: URLSessionTask(),
                       didReceive: createMockAuthenticationChallenge()) { (disposition, credentials) in
            choosenDisposition = disposition
        }

        // then
        XCTAssertEqual(choosenDisposition, .performDefaultHandling)
    }

    func testThatItPerformsDefaultHandling_WhenNotReceivingAServerTrustChallenge() throws {
        // given
        let challenge = createMockAuthenticationChallenge(authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
        mockEnvironment.isServerTrusted = false

        // when
        var choosenDisposition: URLSession.AuthChallengeDisposition = .useCredential
        sut.urlSession(URLSession.shared,
                       task: URLSessionTask(),
                       didReceive: challenge) { (disposition, credentials) in
            choosenDisposition = disposition
        }

        // then
        XCTAssertEqual(choosenDisposition, .performDefaultHandling)
    }

    func testThatItCancelAuthenticationChallenge_WhenServerIsNotTrusted() throws {
        // given
        mockEnvironment.isServerTrusted = false

        // when
        var choosenDisposition: URLSession.AuthChallengeDisposition = .useCredential
        sut.urlSession(URLSession.shared,
                       task: URLSessionTask(),
                       didReceive: createMockAuthenticationChallenge()) { (disposition, credentials) in
            choosenDisposition = disposition
        }

        // then
        XCTAssertEqual(choosenDisposition, .cancelAuthenticationChallenge)
    }

    // MARK: - Helpers

    func createMockAuthenticationChallenge(authenticationMethod: String = NSURLAuthenticationMethodServerTrust) -> URLAuthenticationChallenge {
        let protectionSpace = MockURLProtectionSpace(host: "example.com",
                                                     port: 8080,
                                                     protocol: nil,
                                                     realm: nil,
                                                     authenticationMethod: authenticationMethod)
        protectionSpace.mockServerTrust = SecTrust.trustWithChain(certificateData: certificates.production)

        let authenticationChallenge = URLAuthenticationChallenge(protectionSpace: protectionSpace,
                                                                 proposedCredential: nil,
                                                                 previousFailureCount: 0,
                                                                 failureResponse: nil,
                                                                 error: nil,
                                                                 sender: MockURLAuthenticationChallengeSender())

        return authenticationChallenge
    }

}
