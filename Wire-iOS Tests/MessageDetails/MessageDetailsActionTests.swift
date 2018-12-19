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

class MessageDetailsActionTests: CoreDataSnapshotTestCase {

    // MARK: - One To One

    func testThatDetailsAreNotAvailableForOneToOne_Consumer() {
        withOneToOneMessage(inTeam: false) { message in
            XCTAssertFalse(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }

    func testThatDetailsAreNotAvailableForOneToOne_Team() {
        withOneToOneMessage(inTeam: true) { message in
            XCTAssertFalse(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }

    // MARK: - Groups

    func testThatDetailsAreAvailableInGroup_WithoutReceipts_Consumer() {
        withGroupMessage(inTeam: false) { message in
            XCTAssertTrue(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }

    func testThatDetailsAreAvailableInGroup_WithReceipts_Team() {
        withGroupMessage(inTeam: true) { message in
            XCTAssertTrue(message.areMessageDetailsAvailable)
            XCTAssertTrue(message.areReadReceiptsDetailsAvailable)
        }
    }

    // MARK: - Messages Sent by Other User

    func testThatDetailsAreNotAvailableInGroup_OtherUserMesaage_Consumer() {
        withGroupMessage(inTeam: false) { message in
            message.sender = self.otherUser
            XCTAssertTrue(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }

    func testThatDetailsAreAvailableInGroup_WithoutReceipts_OtherUserMessage_Team() {
        withGroupMessage(inTeam: true) { message in
            message.sender = self.otherUser
            XCTAssertTrue(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }

    // MARK: - Ephemeral Message in Group

    func testThatDetailsAreNotAvailableInGroup_Ephemeral_Consumer() {
        withGroupMessage(inTeam: false) { message in
            message.isEphemeral = true
            XCTAssertFalse(message.canBeLiked)
            XCTAssertFalse(message.areMessageDetailsAvailable)
            XCTAssertFalse(message.areReadReceiptsDetailsAvailable)
        }
    }

    func testThatDetailsAreAvailableInGroup_Ephemeral_Team() {
        withGroupMessage(inTeam: true) { message in
            message.isEphemeral = true
            XCTAssertFalse(message.canBeLiked)
            XCTAssertTrue(message.areMessageDetailsAvailable)
            XCTAssertTrue(message.areReadReceiptsDetailsAvailable)
        }
    }

    // MARK: - Helpers

    private func withGroupMessage(inTeam: Bool, _ block: @escaping (MockMessage) -> Void) {
        let context = inTeam ? teamTest : nonTeamTest

        context {
            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.sender = self.selfUser
            message.conversation = self.createGroupConversation()
            block(message)
        }
    }

    private func withOneToOneMessage(inTeam: Bool, _ block: @escaping (MockMessage) -> Void) {
        let context = inTeam ? teamTest : nonTeamTest

        context {
            let message = MockMessageFactory.textMessage(withText: "Message")!
            message.sender = self.selfUser
            message.conversation = otherUserConversation
            block(message)
        }
    }

}
