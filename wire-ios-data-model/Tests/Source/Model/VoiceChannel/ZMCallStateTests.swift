//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import CoreData
@testable import WireDataModel

class ZMCallStateTests: ZMBaseManagedObjectTest {

    func testThatItReturnsTheSameStateForTheSameConversation() {
        // given
        let sut = ZMCallState()
        let conversationA = ZMConversation.insertNewObject(in: uiMOC)
        let conversationB = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()

        // when
        let a1 = sut.stateForConversation(conversationA)
        let a2 = sut.stateForConversation(conversationA)
        let b1 = sut.stateForConversation(conversationB)
        let b2 = sut.stateForConversation(conversationB)

        // then
        XCTAssertTrue(a1 === a2)
        XCTAssertTrue(b1 === b2)

        XCTAssertFalse(a1 === b1)
        XCTAssertFalse(a2 === b2)
    }

}

// V3 Group calling

extension ZMCallStateTests {

    func testThatItDoesMergeIsCallDeviceActive() {
        // given
        let mainSut = ZMConversationCallState()
        let syncSut = ZMConversationCallState()
        syncSut.isCallDeviceActive = false
        mainSut.isCallDeviceActive = true

        // when
        syncSut.mergeChangesFromState(mainSut)

        // then
        XCTAssertTrue(mainSut.isCallDeviceActive)
        XCTAssertTrue(syncSut.isCallDeviceActive)
    }

    func testThatItDoesMergeIsIgnoringCall() {
        // given
        let mainSut = ZMConversationCallState()
        let syncSut = ZMConversationCallState()
        syncSut.isIgnoringCall = false
        mainSut.isIgnoringCall = true

        // when
        syncSut.mergeChangesFromState(mainSut)

        // then
        XCTAssertTrue(mainSut.isIgnoringCall)
        XCTAssertTrue(syncSut.isIgnoringCall)
    }
}
