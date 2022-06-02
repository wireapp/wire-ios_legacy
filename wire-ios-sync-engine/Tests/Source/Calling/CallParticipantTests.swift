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
@testable import WireSyncEngine

final class CallParticipantTests: MessagingTest {
    var otherUser: ZMUser!
    let otherUserID: UUID = UUID()
    let otherUserClientID = UUID().transportString()

    override func setUp() {
        super.setUp()

        otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = otherUserID
    }

    override func tearDown() {
        otherUser = nil

        super.tearDown()
    }

    func testThatHashIsSameWithDifferentState() {

        // GIVEN & WHEN
        let callParticipant1 = CallParticipant(user: otherUser, clientId: otherUserClientID, state: .connecting, activeSpeakerState: .inactive)
        let callParticipant2 = CallParticipant(user: otherUser, clientId: otherUserClientID, state: .unconnected, activeSpeakerState: .inactive)

        // THEN
        XCTAssertEqual(callParticipant1.hashValue, callParticipant2.hashValue)
    }

    func testThatItFetchesUserCorrectly_WhenCreatedFromAVSCallMember() {
        // GIVEN
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.domain = "wire.com"
        user.remoteIdentifier = UUID()

        let avsIdentifier = AVSIdentifier(
            identifier: user.remoteIdentifier,
            domain: user.domain
        )

        let member = AVSCallMember(member: AVSParticipantsChange.Member(
            userid: avsIdentifier.serialized,
            clientid: UUID().uuidString,
            aestab: .established,
            vrecv: .started,
            muted: .muted
        ))

        // WHEN
        let participant = CallParticipant(member: member, activeSpeakerState: .inactive, context: uiMOC)

        // THEN
        XCTAssertEqual(participant?.user as? ZMUser, user)
        XCTAssertEqual(participant?.userId, avsIdentifier)
    }
}
