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

import WireTesting
@testable import WireDataModel

private class MockTextSearchQueryDelegate: TextSearchQueryDelegate {

    var fetchedResults = [TextQueryResult]()

    fileprivate func textSearchQueryDidReceive(result: TextQueryResult) {
        fetchedResults.append(result)
    }
}

class TextSearchQueryTests: BaseZMClientMessageTests {

    func testThatItOnlyReturnsResultFromTheCorrectConversationNotYetIndexed() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        let otherConversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = try! conversation.appendText(content: "This is the first message in the conversation") as! ZMMessage
        let otherMessage = try! otherConversation.appendText(content: "This is the first message in the other conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 40, normalized: false)
        fillConversationWithMessages(conversation: otherConversation, messageCount: 40, normalized: false)
        [firstMessage, otherMessage].forEach {
            $0.normalizedText = nil
        }

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNil(firstMessage.normalizedText)
        XCTAssertNil(otherMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 41)
        XCTAssertEqual(otherConversation.allMessages.count, 41)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 1 else { return XCTFail("Unexpected count \(results.count)") }

        let result = results.first!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 1)

        let match = result.matches[0]
        XCTAssertEqual(match, firstMessage)
        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItOnlyReturnsResultFromTheCorrectConversationAlreadayIndexed() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        let otherConversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = try! conversation.appendText(content: "This is the first message in the conversation") as! ZMMessage
        let otherMessage = try! otherConversation.appendText(content: "This is the first message in the other conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 40, normalized: true)
        fillConversationWithMessages(conversation: otherConversation, messageCount: 40, normalized: true)

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(otherMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 41)
        XCTAssertEqual(otherConversation.allMessages.count, 41)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 1 else { return XCTFail("Unexpected count \(results.count)") }

        let result = results.first!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 1)

        let match = result.matches[0]
        XCTAssertEqual(match, firstMessage)
        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItDoesntPopulateTheNormalizedTextField_WhenEncryptMessagesAtRestIsEnabled() {
        uiMOC.encryptMessagesAtRest = true
        uiMOC.encryptionKeys = validEncryptionKeys

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        // When
        let message = try! conversation.appendText(content: "This is the first message in the conversation") as! ZMMessage
        XCTAssert(uiMOC.saveOrRollback())

        // Then
        XCTAssertEqual(message.normalizedText, "")
    }

    func testThatItPopulatesTheNormalizedTextFieldAndReturnsTheQueryResults() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = try! conversation.appendText(content: "This is the first message in the conversation") as! ZMMessage
        let secondMessage = try! conversation.appendText(content: "This is the second message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 400, normalized: false)
        let lastMessage = try! conversation.appendText(content: "This is the last message in the conversation") as! ZMMessage
        [firstMessage, secondMessage, lastMessage].forEach {
            $0.normalizedText = nil
        }

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNil(firstMessage.normalizedText)
        XCTAssertNil(secondMessage.normalizedText)
        XCTAssertNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 403)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 3 else { return XCTFail("Unexpected count \(results.count)") }
        for result in results.dropLast() {
            XCTAssertTrue(result.hasMore)
        }

        let finalResult = results.last!
        XCTAssertFalse(finalResult.hasMore)
        XCTAssertEqual(finalResult.matches.count, 3)

        let (first, second, third) = (finalResult.matches[0], finalResult.matches[1], finalResult.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)

        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItReturnsMatchesWhenAllMessagesAreIndexedInTheCorrectOrder() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = try! conversation.appendText(content: "This is the first message in the conversation") as! ZMMessage
        firstMessage.serverTimestamp = Date()
        let secondMessage = try! conversation.appendText(content: "This is the second message in the conversation") as! ZMMessage
        secondMessage.serverTimestamp = firstMessage.serverTimestamp?.addingTimeInterval(100)

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(secondMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 2)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 1 else { return XCTFail("Unexpected count \(results.count)") }

        let result = results.first!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 2)

        let (first, second) = (result.matches[0], result.matches[1])
        XCTAssertEqual(first.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, firstMessage.textMessageData?.messageText)
    }

    func testThatItCallsTheDelegateWithEmptyResultsIfThereAreNoMessages() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        // Then
        let results = search(for: "search query", in: conversation)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.matches.count, 0)
    }

    func testThatItReturnsMatchesWhenAllMessagesAreIndexed() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = try! conversation.appendText(content: "This is the first message in the conversation") as! ZMMessage
        Thread.sleep(forTimeInterval: 0.05)
        let secondMessage = try! conversation.appendText(content: "This is the second message in the conversation") as! ZMMessage
        Thread.sleep(forTimeInterval: 0.05)
        fillConversationWithMessages(conversation: conversation, messageCount: 400, normalized: true)
        let lastMessage = try! conversation.appendText(content: "This is the last message in the conversation") as! ZMMessage

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(secondMessage.normalizedText)
        XCTAssertNotNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 403)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 3 else { return XCTFail("Unexpected count \(results.count)") }

        for fetchedResult in results.dropLast() {
            XCTAssert(fetchedResult.hasMore)
        }

        let result = results.last!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 3)

        let (first, second, third) = (result.matches[0], result.matches[1], result.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)
    }

    func testThatItReturnsAllMatchesWhenMultipleIndexedBatchesNeedToBeFetched() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = try! conversation.appendText(content: "This is the first message in the conversation") as! ZMMessage
        let secondMessage = try! conversation.appendText(content: "This is the second message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 2, normalized: true)
        let lastMessage = try! conversation.appendText(content: "This is the last message in the conversation") as! ZMMessage

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(secondMessage.normalizedText)
        XCTAssertNotNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 5)

        // When
        let delegate = MockTextSearchQueryDelegate()
        let configuration = TextSearchQueryFetchConfiguration(notIndexedBatchSize: 2, indexedBatchSize: 2)
        let sut = TextSearchQuery(conversation: conversation, query: "in the conversation", delegate: delegate, configuration: configuration)
        sut?.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 3 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }

        let firstResult = delegate.fetchedResults.first!
        XCTAssertTrue(firstResult.hasMore)
        XCTAssertEqual(firstResult.matches.count, 2)

        let secondResult = delegate.fetchedResults.last!
        XCTAssertFalse(secondResult.hasMore)
        XCTAssertEqual(secondResult.matches.count, 3)

        let (first, second, third) = (firstResult.matches[0], firstResult.matches[1], secondResult.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)
    }

    func testThatItReturnsAllMatchesIfMessagesAreNotYetAllIndexedAndIndexesNotIndexedMessages() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        // We insert old messages that have not yet been indexed
        let firstMessage = try! conversation.appendText(content: "This is the first message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 200, normalized: false)
        let secondMessage = try! conversation.appendText(content: "This is the second message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 200, normalized: true)
        let lastMessage = try! conversation.appendText(content: "This is the last message in the conversation") as! ZMMessage
        [firstMessage, secondMessage].forEach {
            $0.normalizedText = nil
        }

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNil(firstMessage.normalizedText)
        XCTAssertNil(secondMessage.normalizedText)
        XCTAssertNotNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.allMessages.count, 403)

        // When
        let results = search(for: "in the conversation", in: conversation)

        // Then
        guard results.count == 4 else { return XCTFail("Unexpected count \(results.count)") }
        for result in results.dropLast() {
            XCTAssertTrue(result.hasMore)
        }

        let finalResult = results.last!
        XCTAssertFalse(finalResult.hasMore)
        XCTAssertEqual(finalResult.matches.count, 3)

        let (first, second, third) = (finalResult.matches[0], finalResult.matches[1], finalResult.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)

        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItFindsSpecialCharactersInNormalizedTextMessages() {
        verifyThatItFindsMessage(withText: "Hello Håkon", whenSearchingFor: "hakon")
        verifyThatItFindsMessage(withText: "Hello hakon", whenSearchingFor: "Håkon")
        verifyThatItFindsMessage(withText: "Hello björn", whenSearchingFor: "björn")
        verifyThatItFindsMessage(withText: "Hello björn", whenSearchingFor: "bjorn")
        verifyThatItFindsMessage(withText: "Let's meet in Saint-Étienne", whenSearchingFor: "etienne")
        verifyThatItFindsMessage(withText: "Let's meet in Saint-Etienne", whenSearchingFor: "ētienne")
        verifyThatItFindsMessage(withText: "Coração", whenSearchingFor: "Coracao")
        verifyThatItFindsMessage(withText: "Coracao", whenSearchingFor: "Coração")
        verifyThatItFindsMessage(withText: "❤️🍕", whenSearchingFor: "❤️🍕")
        verifyThatItFindsMessage(withText: "苹果", whenSearchingFor: "苹果")
        verifyThatItFindsMessage(withText: "सेवफलम्", whenSearchingFor: "सेवफलम्")
        verifyThatItFindsMessage(withText: "μήλο", whenSearchingFor: "μήλο")
        verifyThatItFindsMessage(withText: "Яблоко", whenSearchingFor: "Яблоко")
        verifyThatItFindsMessage(withText: "خطای سطح دسترسی", whenSearchingFor: "خطای سطح دسترسی")
        verifyThatItFindsMessage(withText: "תפוח", whenSearchingFor: "תפוח")
        verifyThatItFindsMessage(withText: "ᑭᒻᒥᓇᐅᔭᖅ", whenSearchingFor: "ᑭᒻᒥᓇᐅᔭᖅ")
        verifyThatItFindsMessage(withText: "aa aa aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa.aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "11:45", whenSearchingFor: "11:45")
        verifyThatItFindsMessage(withText: "aabb", whenSearchingFor: "aabb")
        verifyThatItFindsMessage(withText: "aabb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aabb", whenSearchingFor: "bb")
        verifyThatItFindsMessage(withText: "bb aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa bb", whenSearchingFor: "aa bb")
        verifyThatItFindsMessage(withText: "aabb", whenSearchingFor: "aa\nbb")
        verifyThatItFindsMessage(withText: "aa aa aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa bb aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa aa aa", whenSearchingFor: "aa aa")
        verifyThatItFindsMessage(withText: "aa.bb", whenSearchingFor: "bb")
        verifyThatItFindsMessage(withText: "aa...bb", whenSearchingFor: "bb")
        verifyThatItFindsMessage(withText: "aa.bb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa...bb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa-bb", whenSearchingFor: "aa-bb")
        verifyThatItFindsMessage(withText: "aa-bb", whenSearchingFor: "aa bb")
        verifyThatItFindsMessage(withText: "aa-bb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa/bb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa/bb", whenSearchingFor: "bb")
        verifyThatItFindsMessage(withText: "aa:bb", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa:bb", whenSearchingFor: "bb")
        verifyThatItFindsMessage(withText: "@peter", whenSearchingFor: "peter")
        verifyThatItFindsMessage(withText: "rené", whenSearchingFor: "Rene")
        verifyThatItFindsMessage(withText: "https://www.link.com/something-to-read?q=12&second#reader", whenSearchingFor: "something to read")
        verifyThatItFindsMessage(withText: "<8000 x a's>", whenSearchingFor: "<8000 x a's>")
        verifyThatItFindsMessage(withText: "bb бб bb", whenSearchingFor: "бб")
        verifyThatItFindsMessage(withText: "bb бб bb", whenSearchingFor: "bb")

    }

    func testThatItUsesANDConjunctionForSearchTerms() {
        verifyThatItFindsMessage(withText: "This is a test message", whenSearchingFor: "this message")
        verifyThatItFindsMessage(withText: "This is a test message", whenSearchingFor: "this conversation", shouldFind: false)
    }

    func testThatItDoesNotCreateASearchQueryWithQuerySmallerThanTwoCharacters() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        // Then
        XCTAssertNil(TextSearchQuery(conversation: conversation, query: "", delegate: MockTextSearchQueryDelegate()))
        XCTAssertNil(TextSearchQuery(conversation: conversation, query: "a", delegate: MockTextSearchQueryDelegate()))
        XCTAssertNotNil(TextSearchQuery(conversation: conversation, query: "ab", delegate: MockTextSearchQueryDelegate()))
    }

    func testThatItDoesNotReturnsAnyResultsWithOnlyOneCharacterSearchTerms() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        _ = try! conversation.appendText(content: "aa bb a b c dd") as! ZMMessage
        XCTAssert(uiMOC.saveOrRollback())

        let delegate = MockTextSearchQueryDelegate()
        guard let sut = TextSearchQuery(conversation: conversation, query: "a b c d", delegate: delegate) else {
            return XCTFail("Should have created a `TextSearchQuery`")
        }

        // When
        sut.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 1 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }
        let result = delegate.fetchedResults.first!
        XCTAssertFalse(result.hasMore)

        XCTAssertTrue(result.matches.isEmpty, "Expected to not find a match")
    }

    func testThatItUpdatesTheNormalizedTextWhenEditingAMessage() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        let message = try! conversation.appendText(content: "Håkon") as! ZMClientMessage
        message.markAsSent()
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertEqual(message.normalizedText, "hakon")

        // When
        message.textMessageData?.editText("Coração", mentions: [], fetchLinkPreview: false)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(message.normalizedText, "coracao")

        guard let originalMatches = search(for: "hakon", in: conversation).first?.matches,
              let editedMatches = search(for: "coracao", in: conversation).first?.matches else {
                return XCTFail("Unable to get matches")
        }

        XCTAssert(originalMatches.isEmpty)
        guard let editedMatch = editedMatches.first, editedMatches.count == 1 else {
            return XCTFail("Unexpected number of edited matches")
        }

        XCTAssertEqual(editedMatch, message)
    }

    func testThatItReturnsEphemeralMessagesAsSearchResults() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .group
        conversation.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: nil)

        let message = try! conversation.appendText(content: "This is a regular message in the conversation") as! ZMMessage
        let otherMessage = try! conversation.appendText(content: "This is the another message in the conversation") as! ZMMessage
        conversation.setMessageDestructionTimeoutValue(.fiveMinutes, for: .selfUser)
        let ephemeralMessage = try! conversation.appendText(content: "This is a timed message in the conversation") as! ZMMessage

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(message.normalizedText)
        XCTAssertNotNil(otherMessage.normalizedText)
        XCTAssertEqual(ephemeralMessage.normalizedText, "this is a timed message in the conversation")
        XCTAssertEqual(conversation.allMessages.count, 3)

        // When
        guard let ephemeralMatches = search(for: "timed", in: conversation).first?.matches,
            let firstMessageMatches = search(for: "regular message", in: conversation).first?.matches else {
                return XCTFail("Unable to get matches")
        }

        // Then
        XCTAssertFalse(ephemeralMatches.isEmpty)
        guard let messageMatch = firstMessageMatches.first, firstMessageMatches.count == 1 else {
            return XCTFail("Unexpected number of regular matches")
        }

        XCTAssertEqual(messageMatch, message)
    }

    func testThatItCanSearchForALargeMessage() {
        do {
            let longText = try String(contentsOf: fileURL(forResource: "ExternalMessageTextFixture", extension: "txt"), encoding: .utf8)
            let text = longText + "search query"
            verifyThatItFindsMessage(withText: text, whenSearchingFor: "search query")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    func testThatItCanSearchForALikedMessage() {
        verifyThatItFindsMessage(withText: "search term query test", whenSearchingFor: "search query") { message in
            // When we like the message before searching
            message.markAsSent()
            _ = ZMMessage.appendReaction("❤️", toMessage: message)
        }
    }

    func testThatItCanSearchForAMessageThatHasALinkPreview() {
        verifyThatItFindsMessage(withText: "search term query test", whenSearchingFor: "search query") { message in
            // When we add a linkpreview to the message before searching
            guard let clientMessage = message as? ZMClientMessage else { return XCTFail("No client message") }
            let (title, summary, url, permanentURL) = ("title", "summary", "www.example.com/original", "www.example.com/permanent")
            let image = WireProtos.Asset(withUploadedOTRKey: Data.secureRandomData(ofLength: 16), sha256: Data.secureRandomData(ofLength: 16))

            let preview = LinkPreview.with {
                $0.url = url
                $0.permanentURL = permanentURL
                $0.urlOffset = 42
                $0.title = title
                $0.summary = summary
                $0.image = image
            }
            let text = Text.with {
                $0.content = message.textMessageData!.messageText!
                $0.linkPreview = [preview]
            }
            let genericMessage = GenericMessage(content: text, nonce: message.nonce!)
            do {
                try clientMessage.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail()
            }
            message.markAsSent()
        }
    }

    func testThatItCanSearchForAMessageThatContainsALinkWithoutPreview() {
        verifyThatItFindsMessage(withText: "Hey, check out this amazing link: www.wire.com", whenSearchingFor: "wire.com")
    }

    func testThatItDoesNotReturnAnyMessagesOtherThanTextInTheResults() throws {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        try conversation.appendLocation(with: LocationData(latitude: 52.520008, longitude: 13.404954, name: "Berlin, Germany", zoomLevel: 8))
        try conversation.appendImage(from: mediumJPEGData())
        try conversation.appendKnock()
        try conversation.appendImage(from: verySmallJPEGData())
        fillConversationWithMessages(conversation: conversation, messageCount: 10, normalized: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        verifyAllMessagesAreIndexed(in: conversation)

        // When & Then
        verifyThatItFindsMessage(
            withText: "Please check the following messages to get the whole picture!",
            whenSearchingFor: "get the picture",
            in: conversation
        )
    }

    // MARK: Helper

    func fillConversationWithMessages(conversation: ZMConversation, messageCount: Int, normalized: Bool) {
        for index in 0..<messageCount {
            let text = "This is the text message at index \(index)"
            let message = try! conversation.appendText(content: text) as! ZMMessage
            if normalized {
                message.updateNormalizedText()
            } else {
                message.normalizedText = nil
            }
        }

        uiMOC.saveOrRollback()
    }

    func verifyAllMessagesAreIndexed(in conversation: ZMConversation, file: StaticString = #file, line: UInt = #line) {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            ZMClientMessage.predicateForNotIndexedMessages(),
            ZMClientMessage.predicateForMessages(inConversationWith: conversation.remoteIdentifier!)
        ])
        let request = ZMClientMessage.sortedFetchRequest(with: predicate)
        let notIndexedMessageCount = (try? uiMOC.count(for: request)) ?? 0

        if notIndexedMessageCount > 0 {
            recordFailure(
                withDescription: "Found \(notIndexedMessageCount) messages in conversation",
                inFile: String(describing: file),
                atLine: Int(line),
                expected: true
            )
        }
    }

    func verifyThatItFindsMessage(
        withText text: String,
        whenSearchingFor query: String,
        shouldFind: Bool = true,
        in conversation: ZMConversation? = nil,
        file: StaticString = #file,
        line: UInt = #line,
        messageModifier: ((ZMMessage) -> Void)? = nil
        ) {

        // Given
        let conversation = conversation ?? ZMConversation.insertNewObject(in: uiMOC)
        if nil == conversation.remoteIdentifier {
            conversation.remoteIdentifier = .create()
        }
        let message = try! conversation.appendText(content: text) as! ZMMessage
        messageModifier?(message)
        XCTAssert(uiMOC.saveOrRollback(), file: file, line: line)

        // When
        let results = search(for: query, in: conversation, file: file, line: line)

        // Then
        guard results.count == 1 else { return XCTFail("Unexpected count \(results.count)", file: file, line: line) }
        let result = results.first!
        XCTAssertFalse(result.hasMore, file: file, line: line)

        if shouldFind {
            guard let match = result.matches.first else { return XCTFail("No match found", file: file, line: line) }
            XCTAssertEqual(match.textMessageData?.messageText, message.textMessageData?.messageText, file: file, line: line)
            verifyAllMessagesAreIndexed(in: conversation, file: file, line: line)
        } else {
            XCTAssertTrue(result.matches.isEmpty, "Expected to not find a match", file: file, line: line)
        }
    }

    fileprivate func search(for text: String, in conversation: ZMConversation, file: StaticString = #file, line: UInt = #line) -> [TextQueryResult] {
        let delegate = MockTextSearchQueryDelegate()
        guard let sut = TextSearchQuery(conversation: conversation, query: text, delegate: delegate) else {
            XCTFail("Unable to create a query object, ensure the query is >= 2 characters", file: file, line: line)
            return []
        }
        sut.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
        return delegate.fetchedResults
    }

}
