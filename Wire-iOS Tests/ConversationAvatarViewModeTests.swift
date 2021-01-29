
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
@testable import Wire

final class ConversationAvatarViewModeTests: XCTestCase, CoreDataFixtureTestHelper {
    var sut: ConversationAvatarView!

    var coreDataFixture: CoreDataFixture!

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
        sut = ConversationAvatarView()
    }

    override func tearDown() {
        sut = nil
        coreDataFixture = nil
        super.tearDown()
    }

    func testThatModeIsOneWhenGroupConversationWithOneServiceUser() {
        // GIVEN
        otherUser.serviceIdentifier = "serviceIdentifier"
        otherUser.providerIdentifier = "providerIdentifier"
        XCTAssert(otherUser.isServiceUser)

        let conversation = createGroupConversation()

        // WHEN
        sut.configure(context: .conversation(conversation: conversation))

        // THEN
        XCTAssertEqual(sut.mode, .one(serviceUser: true))
    }

    func testThatModeIsFourWhenGroupConversationWithOneUser() {
        // GIVEN
        let conversation = createGroupConversation()

        // WHEN
        sut.configure(context: .conversation(conversation: conversation))

        // THEN
        XCTAssertEqual(sut.mode, .four)
    }

    func testThatModeIsNoneWhenGroupConversationIsEmpty() {
        // GIVEN
        let conversation = createGroupConversation()
        conversation.removeParticipantsAndUpdateConversationState(users:[otherUser!], initiatingUser: selfUser)

        // WHEN
        sut.configure(context: .conversation(conversation: conversation))

        // THEN
        XCTAssertEqual(sut.mode, .none)
    }
}
