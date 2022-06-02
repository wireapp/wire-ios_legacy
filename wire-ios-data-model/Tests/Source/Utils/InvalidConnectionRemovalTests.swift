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
@testable import WireDataModel

class InvalidConnectionRemovalTests: DiskDatabaseTest {

    func testThatItOnlyRemovesConnectionsToTheSelfUser() throws {
        // Given
        let selfUser = ZMUser.selfUser(in: moc)
        let otherUser = ZMUser.insertNewObject(in: moc)
        let connectionToSelfUser = ZMConnection.insertNewObject(in: self.moc)
        connectionToSelfUser.to = selfUser
        let connectionToOtherUser = ZMConnection.insertNewObject(in: self.moc)
        connectionToOtherUser.to = otherUser

        try self.moc.save()

        // When
        WireDataModel.InvalidConnectionRemoval.removeInvalid(in: self.moc)

        // Then - invalid connection is deleted
        XCTAssertTrue(connectionToSelfUser.isDeleted)
        XCTAssertTrue(connectionToSelfUser.isZombieObject)

        // but all other connections are still there
        XCTAssertFalse(connectionToOtherUser.isDeleted)
        XCTAssertFalse(connectionToOtherUser.isZombieObject)
    }

}
