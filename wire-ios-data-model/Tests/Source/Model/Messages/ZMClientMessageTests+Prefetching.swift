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

class ZMClientMessageTests_Prefetching: BaseZMClientMessageTests {

    func testThatMessageIsInserted_WhenNotIncludedInPrefetchResults() throws {
        // given
        let prefetchResults = ZMFetchRequestBatchResult()
        let event = createUpdateEvent(UUID(),
                                      conversationID: UUID(),
                                      genericMessage: .init(content: Text(content: "Hello World")))

        // when
        var message: ZMOTRMessage?
        performPretendingUiMocIsSyncMoc {
            message = ZMOTRMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: prefetchResults)
        }

        // then
        XCTAssertNotNil(message)
    }

    func testThatMessageIsUpdated_WhenIncludedInPrefetchResults() throws {
        // given
        let senderClientID = "sender123"
        let existingMessage = createClientTextMessage()!
        existingMessage.senderClientID = senderClientID
        let prefetchResults = ZMFetchRequestBatchResult()
        prefetchResults.add([existingMessage])
        let event = createUpdateEvent(UUID(),
                                      conversationID: UUID(),
                                      genericMessage: .init(content: Text(content: "Hello World"), nonce: existingMessage.nonce!),
                                      senderClientID: senderClientID)

        // when
        var message: ZMOTRMessage?
        performPretendingUiMocIsSyncMoc {
            message = ZMOTRMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: prefetchResults)
        }

        // then
        XCTAssertTrue(existingMessage === message)
    }

    func testThatMessageIsUpdated_WhenNotIncludedInPrefetchResults_ButWasProcessedInTheSameBatch() throws {
        // given
        let prefetchResults = ZMFetchRequestBatchResult()
        let nonce = UUID()
        let senderClientID = "sender123"
        let event1 = createUpdateEvent(UUID(),
                                      conversationID: UUID(),
                                      genericMessage: .init(content: Text(content: "Hello World"), nonce: nonce),
                                      senderClientID: senderClientID)

        let event2 = createUpdateEvent(UUID(),
        conversationID: UUID(),
        genericMessage: .init(content: Text(content: "Hello World"), nonce: nonce),
        senderClientID: senderClientID)

        // when
        var message1: ZMOTRMessage?
        var message2: ZMOTRMessage?
        performPretendingUiMocIsSyncMoc {
            message1 = ZMOTRMessage.createOrUpdate(from: event1, in: self.uiMOC, prefetchResult: prefetchResults)
            message2 = ZMOTRMessage.createOrUpdate(from: event2, in: self.uiMOC, prefetchResult: prefetchResults)
        }

        // then
        XCTAssertTrue(message1 === message2)
    }

}
