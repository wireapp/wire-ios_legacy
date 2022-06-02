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

import Foundation
import WireTransport
import WireTesting

@objcMembers public class FakeReachability: NSObject, ReachabilityProvider, TearDownCapable {
    
    public var observerCount = 0
    public func add(_ observer: ZMReachabilityObserver, queue: OperationQueue?) -> Any {
        observerCount += 1
        return NSObject()
    }
    
    public func addReachabilityObserver(on queue: OperationQueue?, block: @escaping ReachabilityObserverBlock) -> Any {
        return NSObject()
    }

    public var mayBeReachable: Bool = true
    public var isMobileConnection: Bool = true
    public var oldMayBeReachable: Bool = true
    public var oldIsMobileConnection: Bool = true
    
    public func tearDown() { }
}

@objcMembers public class MockSessionsDirectory: NSObject, URLSessionsDirectory, TearDownCapable {
    public var foregroundSession: ZMURLSession
    public var backgroundSession: ZMURLSession
    public var voipSession: ZMURLSession
    public var allSessions: [ZMURLSession]
    
    public init(foregroundSession: ZMURLSession, backgroundSession: ZMURLSession? = nil, voipSession: ZMURLSession? = nil) {
        self.foregroundSession = foregroundSession
        self.backgroundSession = backgroundSession ?? foregroundSession
        self.voipSession = voipSession ?? foregroundSession
        allSessions = [foregroundSession, backgroundSession, voipSession].compactMap{ $0 }
    }
    
    var tearDownCalled = false
    public func tearDown() {
        tearDownCalled = true
    }

}

class ZMTransportSessionTests_Initialization: ZMTBaseTest {
    var userIdentifier: UUID!
    var containerIdentifier: String!
    var serverName: String!
    var baseURL: URL!
    var websocketURL: URL!
    var cookieStorage: ZMPersistentCookieStorage!
    var reachability: FakeReachability!
    var sut: ZMTransportSession!
    var environment: MockEnvironment!
    
    override func setUp() {
        super.setUp()
        userIdentifier = UUID()
        containerIdentifier = "some.bundle.id"
        serverName = "https://example.com"
        baseURL = URL(string: serverName)!
        websocketURL = URL(string: serverName)!.appendingPathComponent("websocket")
        cookieStorage = ZMPersistentCookieStorage(forServerName: serverName, userIdentifier: userIdentifier)
        reachability = FakeReachability()
        environment = MockEnvironment()
        sut = ZMTransportSession(environment: environment, cookieStorage: cookieStorage, reachability: reachability, initialAccessToken: nil, applicationGroupIdentifier: containerIdentifier, applicationVersion: "1.0")
    }
    
    override func tearDown() {
        userIdentifier = nil
        containerIdentifier = nil
        serverName = nil
        baseURL = nil
        websocketURL = nil
        cookieStorage = nil
        reachability = nil
        sut.tearDown()
        sut = nil
        super.tearDown()
    }
    
    func check(identifier: String?, contains items: [String], file: StaticString = #file, line: UInt = #line) {
        guard let identifier = identifier else { XCTFail("identifier should not be nil", file: file, line: line); return }
        for item in items {
            XCTAssert(identifier.contains(item), "[\(identifier)] should contain [\(item)]", file: file, line: line)
        }
    }
    
    func testThatBackgorundSessionIsBackground() {
        XCTAssertTrue(sut.sessionsDirectory.backgroundSession.isBackgroundSession)
        XCTAssertFalse(sut.sessionsDirectory.foregroundSession.isBackgroundSession)
    }
    
    func testThatItConfiguresSessionsCorrectly() {
        // given
        let userID = userIdentifier.transportString()
        let voipSession = sut.sessionsDirectory.voipSession
        let foregroundSession = sut.sessionsDirectory.foregroundSession
        let backgroundSession = sut.sessionsDirectory.backgroundSession

        // then
        check(identifier: voipSession.identifier, contains: [ZMURLSessionVoipIdentifier, userID])
        
        check(identifier: foregroundSession.identifier, contains: [ZMURLSessionForegroundIdentifier, userID])
        
        check(identifier: backgroundSession.identifier, contains: [ZMURLSessionBackgroundIdentifier, userID])
        let backgroundConfiguration = backgroundSession.configuration
        check(identifier: backgroundConfiguration.identifier, contains: [userID])
        XCTAssertEqual(backgroundConfiguration.sharedContainerIdentifier, containerIdentifier)
        
        XCTAssertEqual(Set<String>([voipSession.identifier, foregroundSession.identifier, backgroundSession.identifier]).count, 3, "All identifiers should be unique")
    }
    
}

