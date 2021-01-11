//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

@testable import Wire

final class ConversationRenamedCellTests: ConversationCellSnapshotTestCase {

    func testThatItRendersRenamedCellCorrectlySelf() {
        let name = "Amazing Conversation"
        let message = renamedMessage(fromSelf: true, name: name)

        verify(message: message)
    }

    func testThatItRendersRenamedCellCorrectlyOther() {
        let name = "Best Conversation Ever"
        let message = renamedMessage(fromSelf: false, name: name)

        verify(message: message)
    }

    func testThatItRendersRenamedCellCorrectlyLongName() {
        let name = "This is the best conversation name I could come up with for now!"
        let message = renamedMessage(fromSelf: false, name: name)

        verify(message: message)
    }

    // MARK: – Helpers

    private func renamedMessage(fromSelf: Bool, name: String) -> ZMConversationMessage {
        let message = MockMessageFactory.systemMessage(with: .conversationNameChanged, users: 0, clients: 0)!
        message.backingSystemMessageData.systemMessageType = .conversationNameChanged
        message.backingSystemMessageData.text = name
        message.senderUser = fromSelf ? MockUserType.createSelfUser(name: "Alice") : MockUserType.createUser(name: "Bruno")
        message.conversation = otherUserConversation

        return message
    }

}
