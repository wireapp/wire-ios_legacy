//
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

import XCTest
@testable import WireDataModel

class ZMConversationTests_HasMessages: ZMConversationTestsBase {

    func testThatItHasMessages_ReadButNotCleared() {
        // Given
        let sut = ZMConversation.insertNewObject(in: uiMOC)
        sut.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -10)

        XCTAssertNotNil(sut.lastReadServerTimeStamp)
        XCTAssertNil(sut.clearedTimeStamp)

        // Then
        XCTAssertTrue(sut.estimatedHasMessages)
    }

    func testThatItHasMessages_ReadAfterCleared() {
        // Given
        let sut = ZMConversation.insertNewObject(in: uiMOC)
        sut.clearedTimeStamp = Date(timeIntervalSinceNow: -15)
        sut.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -10)

        XCTAssertNotNil(sut.clearedTimeStamp)
        XCTAssertNotNil(sut.lastReadServerTimeStamp)

        // Then
        XCTAssertTrue(sut.estimatedHasMessages)
    }

    func testThatItHasNoMessages_NotRead() {
        // Given
        let sut = ZMConversation.insertNewObject(in: uiMOC)

        XCTAssertNil(sut.lastReadServerTimeStamp)

        // Then
        XCTAssertFalse(sut.estimatedHasMessages)
    }

    func testThatItHasNoMessages_ReadAndCleared() {
        // Given
        let sut = ZMConversation.insertNewObject(in: uiMOC)
        sut.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -10)
        sut.clearedTimeStamp = Date(timeIntervalSinceNow: -10)

        XCTAssertNotNil(sut.lastReadServerTimeStamp)
        XCTAssertNotNil(sut.clearedTimeStamp)

        // Then
        XCTAssertFalse(sut.estimatedHasMessages)
    }

    func testThatItHasNoMessages_ReadThenCleared() {
        // Given
        let sut = ZMConversation.insertNewObject(in: uiMOC)
        sut.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -10)
        sut.clearedTimeStamp = Date(timeIntervalSinceNow: -5)

        XCTAssertNotNil(sut.lastReadServerTimeStamp)
        XCTAssertNotNil(sut.clearedTimeStamp)

        // Then
        XCTAssertFalse(sut.estimatedHasMessages)
    }
}
