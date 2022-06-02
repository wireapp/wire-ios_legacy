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

final class TestPushDispatcherClient: NSObject, PushDispatcherOptionalClient {
    var pushTokens: [PushToken?] = []
    var canHandlePayloads: [[AnyHashable: Any]] = []
    var receivedPayloads: [[AnyHashable: Any]] = []

    var canHandleNext: Bool = true

    func updatedPushToken(to token: PushToken?) {
        pushTokens.append(token)
    }

    func mustHandle(payload: [AnyHashable: Any]) -> Bool {
        canHandlePayloads.append(payload)
        return canHandleNext
    }

    func receivedPushNotification(with payload: [AnyHashable: Any], from source: ZMPushNotficationType, completion: ZMPushNotificationCompletionHandler?) {
        receivedPayloads.append(payload)
    }
}

public final class PushDispatcherTests: ZMTBaseTest {
    var sut: PushDispatcher!

    static let token = Data(bytes: [0xba, 0xdf, 0x00, 0xd0])
    static let userID = UUID().transportString()
    static let payload: [AnyHashable: Any] = ["data": [
        "user": userID,
        "type": "notice"
        ]]

    static let payloadWithoutUser: [AnyHashable: Any] = ["data": [
        "type": "notice"
        ]]

    public override func setUp() {
        super.setUp()
        sut = PushDispatcher(analytics: nil)
    }

    public override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItDoesNotRetainTheObservers() {
        weak var observerWeakReference: TestPushDispatcherClient?
        var observer: TestPushDispatcherClient?
        autoreleasepool {
            // GIVEN
            observer = TestPushDispatcherClient()
            observerWeakReference = observer
            // WHEN 
            sut.add(client: observer!)
            observer = nil
        }
        // THEN

        XCTAssertNil(observerWeakReference)
    }

    func testThatItDoesNotRetainTheFallbackObserver() {
        weak var observerWeakReference: TestPushDispatcherClient?
        var observer: TestPushDispatcherClient?
        autoreleasepool {
            // GIVEN
            observer = TestPushDispatcherClient()
            observerWeakReference = observer
            // WHEN
            sut.fallbackClient = observer
            observer = nil
        }
        // THEN

        XCTAssertNil(observerWeakReference)
    }

    func testThatItForwardTheRegistrationEvent() {
        // GIVEN
        let client = TestPushDispatcherClient()
        sut.add(client: client)
        // WHEN
        sut.updatePushToken(to: PushToken(data: type(of: self).token))

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        // THEN
        XCTAssertEqual(client.pushTokens.count, 1)
        XCTAssertEqual(client.pushTokens[0]?.data, type(of: self).token)
    }

    func testThatItForwardsThePushTokenToNewObserver() {
        // GIVEN
        sut.updatePushToken(to: PushToken(data: type(of: self).token))
        let client = TestPushDispatcherClient()

        // WHEN
        sut.add(client: client)

        // THEN
        XCTAssertEqual(client.pushTokens.count, 1)
        XCTAssertEqual(client.pushTokens[0]?.data, type(of: self).token)
    }

    func testThatItAsksObserverIfItCanHandleThePush() {
        // GIVEN
        let client = TestPushDispatcherClient()
        sut.add(client: client)

        // WHEN
        sut.didReceiveRemoteNotification(type(of: self).payload, fetchCompletionHandler: { _ in })

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(client.canHandlePayloads.count, 1)
        XCTAssertTrue(NSDictionary(dictionary: client.canHandlePayloads[0]).isEqual(to: type(of: self).payload))
    }

    func testThatItForwardsTheNotificationToTheFallbackObserverIfCannotHandle() {
        // GIVEN
        let client = TestPushDispatcherClient()
        client.canHandleNext = false
        sut.add(client: client)
        let fallbackClient = TestPushDispatcherClient()
        sut.fallbackClient = fallbackClient

        // WHEN
        sut.didReceiveRemoteNotification(type(of: self).payload, fetchCompletionHandler: { _ in })

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(client.canHandlePayloads.count, 1)

        XCTAssertEqual(fallbackClient.receivedPayloads.count, 1)
        XCTAssertTrue(NSDictionary(dictionary: fallbackClient.receivedPayloads[0]).isEqual(to: type(of: self).payload))
    }

    func testThatItForwardsTheNotificationToFallbackObserverWhenNoObservers() {
        // GIVEN
        let fallbackClient = TestPushDispatcherClient()
        sut.fallbackClient = fallbackClient

        // WHEN
        sut.didReceiveRemoteNotification(type(of: self).payload, fetchCompletionHandler: { _ in })

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(fallbackClient.receivedPayloads.count, 1)
        XCTAssertTrue(NSDictionary(dictionary: fallbackClient.receivedPayloads[0]).isEqual(to: type(of: self).payload))
    }
}
