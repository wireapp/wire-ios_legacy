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
@testable import WireDataModel

class InvalidDomainRemovalTests: DiskDatabaseTest {

    func testAllUsersWithInvalidDomainIsRemoved() throws {
        coreDataStack.syncContext.performGroupedAndWait { context in
            // GIVEN
            let selfDomain = "example.com"
            let otherDomain = "other.com"
            let userUUID = UUID()

            ZMUser.selfUser(in: context).domain = selfDomain

            let user1 = ZMUser.insertNewObject(in: context)
            user1.remoteIdentifier = userUUID
            user1.domain = selfDomain
            let user2 = ZMUser.insertNewObject(in: context)
            user2.remoteIdentifier = userUUID
            user2.domain = otherDomain
            context.saveOrRollback()

            // WHEN
            InvalidDomainRemoval.removeDuplicatedEntitiesWithInvalidDomain(in: context)

            // THEN
            XCTAssertFalse(user1.isDeleted)
            XCTAssertTrue(user2.isDeleted)
        }
    }

    func testAllConversationsWithInvalidDomainIsRemoved() throws {
        coreDataStack.syncContext.performGroupedAndWait { context in
            // GIVEN
            let selfDomain = "example.com"
            let otherDomain = "other.com"
            let userUUID = UUID()

            ZMUser.selfUser(in: context).domain = selfDomain

            let conversation1 = ZMConversation.insertNewObject(in: context)
            conversation1.remoteIdentifier = userUUID
            conversation1.domain = selfDomain
            let conversation2 = ZMConversation.insertNewObject(in: context)
            conversation2.remoteIdentifier = userUUID
            conversation2.domain = otherDomain
            context.saveOrRollback()

            // WHEN
            InvalidDomainRemoval.removeDuplicatedEntitiesWithInvalidDomain(in: context)

            // THEN
            XCTAssertFalse(conversation1.isDeleted)
            XCTAssertTrue(conversation2.isDeleted)
        }
    }

}
