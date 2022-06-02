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

import XCTest
@testable import WireDataModel

class ZMClientMessagesTests_ResetSession: BaseZMClientMessageTests {

    func testSessionResetSystemMessageIsInserted_WhenReceivingMessage() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC); conversation.remoteIdentifier = UUID.create()
        let resetSessionMessage = GenericMessage(clientAction: .resetSession)
        let data = ["sender": NSString.createAlphanumerical(), "text": try? resetSessionMessage.serializedData().base64EncodedString()]
        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRMessage, data: data)
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        let systemMessage = try XCTUnwrap(conversation.lastMessage as? ZMSystemMessage)
        XCTAssertEqual(systemMessage.systemMessageType, .sessionReset)
    }
}
