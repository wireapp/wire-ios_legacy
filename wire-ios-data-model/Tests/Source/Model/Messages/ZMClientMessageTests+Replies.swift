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

import XCTest
@testable import WireDataModel

class ZMClientMessagesTests_Replies: BaseZMClientMessageTests {

    func testQuoteRelationshipIsEstablishedWhenSendingMessage() {
        let quotedMessage = try! conversation.appendText(content: "I have a proposal", mentions: [], replyingTo: nil, fetchLinkPreview: false, nonce: UUID()) as! ZMClientMessage

        let message = try! conversation.appendText(content: "That's fine", mentions: [], replyingTo: quotedMessage, fetchLinkPreview: false, nonce: UUID()) as! ZMTextMessageData

        XCTAssertEqual(message.quoteMessage as! ZMMessage, quotedMessage)
    }

    func testQuoteRelationshipIsEstablishedWhenReceivingMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC); conversation.remoteIdentifier = UUID.create()
        let quotedMessage = try! conversation.appendText(content: "The sky is blue") as? ZMClientMessage
        let replyMessage = GenericMessage(content: Text(content: "I agree", replyingTo: quotedMessage))
        let data = ["sender": NSString.createAlphanumerical(), "text": try? replyMessage.serializedData().base64EncodedString()]
        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRMessage, data: data)
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

        // when
        var sut: ZMClientMessage! = nil
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.quote, quotedMessage)
    }

    func testQuoteRelationshipIsEstablishedWhenReceivingEphemeralMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC); conversation.remoteIdentifier = UUID.create()
        let quotedMessage = try! conversation.appendText(content: "The sky is blue") as? ZMClientMessage
        let replyMessage = GenericMessage(content: Ephemeral(content: Text(content: "I agree", replyingTo: quotedMessage), expiresAfter: 1000))
        let data = ["sender": NSString.createAlphanumerical(), "text": try? replyMessage.serializedData().base64EncodedString()]
        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRMessage, data: data)
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

        // when
        var sut: ZMClientMessage! = nil
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.quote, quotedMessage)
    }
}
