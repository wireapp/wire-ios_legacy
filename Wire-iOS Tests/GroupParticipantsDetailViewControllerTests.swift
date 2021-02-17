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
import SnapshotTesting

/// TODO: retire this extension
extension ZMConversation {

    func add(participants: Set<ZMUser>) {
        addParticipantsAndUpdateConversationState(users: participants, role: nil)
    }

    func add(participants: [ZMUser]) {
        add(participants: Set(participants))
    }

    func add(participants: ZMUser...) {
        add(participants: Set(participants))
    }
}

private final class MockConversation: MockStableRandomParticipantsConversation, GroupDetailsConversation {

    var userDefinedName: String?

    var hasReadReceiptsEnabled: Bool = false

    var freeParticipantSlots: Int = 1
}

final class GroupParticipantsDetailViewControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()

        SelfUser.setupMockSelfUser()
    }

    override func tearDown() {
        SelfUser.provider = nil
        
        super.tearDown()
    }

    func testThatItRendersALotOfUsers() {
        // given
        let users: [MockUserType] = (0..<20).map {
            let user = MockUserType.createUser(name: "User #\($0)")
            user.handle = nil
            
            return user
        }

        let selected = Array(users.dropLast(15))
        let conversation = MockConversation()
        conversation.sortedOtherParticipants = users

        // when & then
		let createSut: () -> UIViewController = {
			let sut = GroupParticipantsDetailViewController(selectedParticipants: selected, conversation: conversation)
			return sut.wrapInNavigationController()
		}

        verifyInAllColorSchemes(createSut: createSut)
    }

    func testEmptyState() {
        // given
        let conversation = MockConversation()

        // when
        let sut = GroupParticipantsDetailViewController(selectedParticipants: [], conversation: conversation)
        sut.viewModel.admins = []
        sut.viewModel.members = []
        sut.setupViews()
        sut.participantsDidChange()

        // then
        let wrapped = sut.wrapInNavigationController()
        verify(matching: wrapped)
    }
}
