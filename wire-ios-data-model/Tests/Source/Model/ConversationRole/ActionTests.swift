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

final class ActionTests: ZMBaseManagedObjectTest {
    func testThatItTracksCorrectKeys() {
        let expectedKeys = Set(arrayLiteral: Action.nameKey,
                                             Action.roleKey)

        let sut = Action.insertNewObject(in: uiMOC)

        XCTAssertEqual(sut.keysTrackedForLocalModifications(), expectedKeys)
    }

    func testThatFetchOrCreate_FetchesAnExistingAction() {
        let name = "dummy action"
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let role = Role.create(managedObjectContext: uiMOC, name: "DUMMY", conversation: conversation)

        // given
        var created = false
        let action = Action.fetchOrCreate(with: name, role: role, in: uiMOC, created: &created)
        XCTAssert(created)

        // when
        let fetchedAction = Action.fetchOrCreate(with: name, role: role, in: uiMOC, created: &created)

        // then
        XCTAssertFalse(created)
        XCTAssertEqual(action, fetchedAction)
    }
}
