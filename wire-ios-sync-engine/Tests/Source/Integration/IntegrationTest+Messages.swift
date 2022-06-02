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

import Foundation

extension IntegrationTest {

    func remotelyInsert(text: String, from senderClient: MockUserClient, into conversation: MockConversation) {
        remotelyInsert(content: Text(content: text), from: senderClient, into: conversation)
    }

    func remotelyInsert(content: MessageCapable, from senderClient: MockUserClient, into conversation: MockConversation) {
        remotelyInsert(genericMessage: GenericMessage(content: content), from: senderClient, into: conversation)
    }

    func remotelyInsert(genericMessage: GenericMessage, from senderClient: MockUserClient, into conversation: MockConversation) {
        mockTransportSession.performRemoteChanges { _ in
            do {
                conversation.encryptAndInsertData(from: senderClient, to: self.selfUser.clients.anyObject() as! MockUserClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail()
            }
        }
    }

}
