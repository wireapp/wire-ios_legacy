//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import XCTest
@testable import WireRequestStrategy

class VoIPPushHelperTests: XCTestCase {

    // MARK: - Set up

    override func setUp() {
        super.setUp()
        VoIPPushHelper.storage = UserDefaults()
    }

    // MARK: - Tests

    func testIsCallKitAvailable() {
        // Given
        XCTAssertFalse(VoIPPushHelper.isCallKitAvailable)

        // When
        VoIPPushHelper.isCallKitAvailable = true

        // Then
        XCTAssertTrue(VoIPPushHelper.isCallKitAvailable)
    }

    func testLoadedUserSessions() {
        // Given
        let id1 = UUID.create()
        let id2 = UUID.create()
        let id3 = UUID.create()

        XCTAssertFalse(VoIPPushHelper.isUserSessionLoaded(accountID: id1))
        XCTAssertFalse(VoIPPushHelper.isUserSessionLoaded(accountID: id2))
        XCTAssertFalse(VoIPPushHelper.isUserSessionLoaded(accountID: id3))

        // When
        VoIPPushHelper.setLoadedUserSessions(accountIDs: [id1, id2])

        // Then
        XCTAssertTrue(VoIPPushHelper.isUserSessionLoaded(accountID: id1))
        XCTAssertTrue(VoIPPushHelper.isUserSessionLoaded(accountID: id2))
        XCTAssertFalse(VoIPPushHelper.isUserSessionLoaded(accountID: id3))
    }

    func testIsAVSReady() {
        // Given
        XCTAssertFalse(VoIPPushHelper.isAVSReady)

        // When
        VoIPPushHelper.isAVSReady = true

        // Then
        XCTAssertTrue(VoIPPushHelper.isAVSReady)
    }

    func testOngoingCalls() {
        // Given
        let id1 = UUID.create()
        let id2 = UUID.create()
        let id3 = UUID.create()

        XCTAssertFalse(VoIPPushHelper.existsOngoingCallInConversation(withID: id1))
        XCTAssertFalse(VoIPPushHelper.existsOngoingCallInConversation(withID: id2))
        XCTAssertFalse(VoIPPushHelper.existsOngoingCallInConversation(withID: id3))

        // When
        VoIPPushHelper.setOngoingCalls(conversationIDs: [id1, id2])

        // Then
        XCTAssertTrue(VoIPPushHelper.existsOngoingCallInConversation(withID: id1))
        XCTAssertTrue(VoIPPushHelper.existsOngoingCallInConversation(withID: id2))
        XCTAssertFalse(VoIPPushHelper.existsOngoingCallInConversation(withID: id3))
    }

}
