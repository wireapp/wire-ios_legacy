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
@testable import WireSyncEngine

final class ZMUserSessionTests_NetworkState: ZMUserSessionTestsBase {

    func testThatItSetsItselfAsADelegateOfTheTransportSessionAndForwardsUserClientID() {
        // given
        let selfClient = createSelfClient()
        let userId = NSUUID.create()!

        mockPushChannel = MockPushChannel()
        cookieStorage = ZMPersistentCookieStorage(forServerName: "usersessiontest.example.com", userIdentifier: userId)
        let transportSession = RecordingMockTransportSession(cookieStorage: cookieStorage, pushChannel: mockPushChannel)

        // when
        let testSession = ZMUserSession(
            userId: userId,
            transportSession: transportSession,
            mediaManager: mediaManager,
            flowManager: flowManagerMock,
            analytics: nil,
            eventProcessor: nil,
            strategyDirectory: nil,
            syncStrategy: nil,
            operationLoop: nil,
            application: application,
            appVersion: "00000",
            coreDataStack: coreDataStack,
            configuration: .init())
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // then
        XCTAssertTrue(self.transportSession.didCallSetNetworkStateDelegate)
        XCTAssertEqual(mockPushChannel.keepOpen, true)
        XCTAssertEqual(mockPushChannel.clientID, selfClient.remoteIdentifier)

        testSession.tearDown()
    }
}
