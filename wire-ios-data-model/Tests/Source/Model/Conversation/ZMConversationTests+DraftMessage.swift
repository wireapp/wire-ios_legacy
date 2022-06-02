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
@testable import WireDataModel

class ConversationTests_DraftMessage: ZMConversationTestsBase {

    override func setUp() {
        super.setUp()

        createSelfClient(onMOC: uiMOC)
    }

    // MARK: Persist encrypted draft message

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func testThatItEncryptsDraftMessage_WhenEncryptionAtRestIsEnabled() {
        // GIVEN
        uiMOC.encryptMessagesAtRest = true
        uiMOC.encryptionKeys = validEncryptionKeys

        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // WHEN
        conversation.draftMessage = DraftMessage(text: "Draft test", mentions: [], quote: nil)

        // THEN
        XCTAssertNotNil(conversation.draftMessage)
        XCTAssertNotNil(conversation.draftMessageNonce)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func testThatItDiscardsDraftMessage_WhenEncryptionAtRestIsEnabled_And_DatabaseKeyIsMissing() {
        // GIVEN
        uiMOC.encryptMessagesAtRest = true
        uiMOC.encryptionKeys = nil

        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // WHEN
        conversation.draftMessage = DraftMessage(text: "Draft test", mentions: [], quote: nil)

        // THEN
        XCTAssertNil(conversation.draftMessage)
        XCTAssertNil(conversation.draftMessageNonce)
    }

    // MARK: Access encrypted draft message

    func testThatEncryptedDraftMessageCanBeAccessed_WhenDatabaseKeyIsAvailable() {
        // GIVEN
        uiMOC.encryptMessagesAtRest = true
        uiMOC.encryptionKeys = validEncryptionKeys

        let draftText = "Draft test"
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.draftMessage = DraftMessage(text: draftText, mentions: [], quote: nil)

        // WHEN
        XCTAssertNotNil(uiMOC.encryptionKeys)

        // THEN
        XCTAssertEqual(conversation.draftMessage?.text, draftText)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func testThatEncryptedDraftMessageCantBeAccessed_WhenDatabaseKeyIsMissing() {
        // GIVEN
        uiMOC.encryptMessagesAtRest = true
        uiMOC.encryptionKeys = validEncryptionKeys

        let draftText = "Draft test"
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.draftMessage = DraftMessage(text: draftText, mentions: [], quote: nil)

        // WHEN
        uiMOC.encryptionKeys = nil

        // THEN
        XCTAssertNil(conversation.draftMessage)
    }

}
