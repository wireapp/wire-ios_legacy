//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
@testable import Wire

final class MessageDetailsActionTests: CoreDataSnapshotTestCase {

    // MARK: - One To One

    func testThatDetailsAreNotAvailableForOneToOne_Consumer() {
        withOneToOneMessage(belongsToTeam: false) { message in
            XCTAssertFalse(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }

    func testThatDetailsAreNotAvailableForOneToOne_Team() {
        withOneToOneMessage(belongsToTeam: true) { message in
            XCTAssertFalse(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }

    // MARK: - Groups

    func testThatDetailsAreAvailableInGroup_WithoutReceipts() {
        withGroupMessage(belongsToTeam: false, teamGroup: false) { message in
            XCTAssertTrue(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }
    
    func testThatDetailsAreAvailableInTeamGroup_Receipts() {
        withGroupMessage(belongsToTeam: false, teamGroup: true) { message in
            XCTAssertTrue(message.areMessageDetailsAvailable)
            XCTAssertTrue(message.areReadReceiptsDetailsAvailable)
        }
    }
    
    // MARK: - Messages Sent by Other User

    func testThatDetailsAreNotAvailableInGroup_OtherUserMesaage() {
        withGroupMessage(belongsToTeam: false, teamGroup: false) { message in
            message.senderUser = MockUserType.createUser(name: "Bob")
            XCTAssertTrue(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }

    func testThatDetailsAreAvailableInTeamGroup_WithoutReceipts_OtherUserMessage() {
        withGroupMessage(belongsToTeam: true, teamGroup: true) { message in
            message.senderUser = MockUserType.createUser(name: "Bob")
            XCTAssertTrue(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }

    // MARK: - Ephemeral Message in Group

    func testThatDetailsAreNotAvailableInGroup_Ephemeral() {
        withGroupMessage(belongsToTeam: false, teamGroup: false) { message in
            message.isEphemeral = true
            XCTAssertFalse(message.canBeLiked)
            XCTAssertFalse(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }

    func testThatDetailsAreAvailableInTeamGroup_Ephemeral() {
        withGroupMessage(belongsToTeam: true, teamGroup: true) { message in
            message.isEphemeral = true
            XCTAssertFalse(message.canBeLiked)
            XCTAssertTrue(message.areMessageDetailsAvailable)
            XCTAssertTrue(message.areReadReceiptsDetailsAvailable)
        }
    }

    // MARK: - Helpers

    private func withGroupMessage(belongsToTeam: Bool, teamGroup: Bool, _ block: @escaping (MockMessage) -> Void) {
        let context = belongsToTeam ? teamTest : nonTeamTest

        context {
            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.senderUser = MockUserType.createSelfUser(name: "Alice")
            message.conversation = teamGroup ? self.createTeamGroupConversation() : self.createGroupConversation()
            block(message)
        }
    }

    private func withOneToOneMessage(belongsToTeam: Bool, _ block: @escaping (MockMessage) -> Void) {
        let context = belongsToTeam ? teamTest : nonTeamTest

        context {
            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.senderUser = MockUserType.createSelfUser(name: "Alice")
            message.conversation = otherUserConversation
            block(message)
        }
    }

}
