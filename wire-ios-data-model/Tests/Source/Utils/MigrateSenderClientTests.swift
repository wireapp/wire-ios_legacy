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

class MigrateSenderClientTests: DiskDatabaseTest {

    func testSenderClientIDIsMigratedFromClientsSet() throws {
        // given
        let clientID = UUID().transportString()
        let userClient = UserClient(context: coreDataStack.viewContext)
        userClient.remoteIdentifier = clientID
        let systemMessage = ZMSystemMessage(context: coreDataStack.viewContext)
        systemMessage.systemMessageType = .decryptionFailed
        systemMessage.clients = Set(arrayLiteral: userClient)
        coreDataStack.viewContext.saveOrRollback()

        // when
        MigrateSenderClient.migrateSenderClientID(in: coreDataStack.viewContext)

        // then
        XCTAssertEqual(systemMessage.senderClientID, clientID)

    }

}
