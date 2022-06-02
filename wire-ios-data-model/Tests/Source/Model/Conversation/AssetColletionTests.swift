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

@testable import WireDataModel

class MockAssetCollectionDelegate: NSObject, AssetCollectionDelegate {

    var messagesByFilter = [[CategoryMatch: [ZMMessage]]]()
    var didCallDelegate = false
    var result: AssetFetchResult?
    var finished: [CategoryMatch] = []

    public func assetCollectionDidFinishFetching(collection: ZMCollection, result: AssetFetchResult) {
        self.result = result
        didCallDelegate = true
    }

    public func assetCollectionDidFetch(collection: ZMCollection, messages: [CategoryMatch: [ZMConversationMessage]], hasMore: Bool) {
        // For testing purposes it's easier to work with ZMMessage directly
        var toAppend = [CategoryMatch: [ZMMessage]]()
        for (key, value) in messages {
            toAppend[key] = value.map { $0 as! ZMMessage }
        }
        messagesByFilter.append(toAppend)

        didCallDelegate = true
        if !hasMore {
            finished += messages.keys
        }
    }

    func allMessages(for categoryMatch: CategoryMatch) -> [ZMMessage] {
        return messagesByFilter.reduce([ZMMessage]()) {$0 + ($1[categoryMatch] ?? [])}
    }
}

class AssetColletionTests: ModelObjectsTests {

    var sut: AssetCollection!
    var delegate: MockAssetCollectionDelegate!
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()
        delegate = MockAssetCollectionDelegate()
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID()
        uiMOC.saveOrRollback()
    }

    override func tearDown() {
        delegate = nil
        sut?.tearDown()
        uiMOC.zm_fileAssetCache.wipeCaches()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sut = nil
        conversation = nil
        super.tearDown()
    }

    var defaultMatchPair: CategoryMatch {
        return CategoryMatch(including: .image, excluding: .none)
    }

    @discardableResult func insertAssetMessages(count: Int) -> [ZMMessage] {
        var offset: TimeInterval = 0
        var messages = [ZMMessage]()
        (0..<count).forEach { _ in
            let message = try! conversation.appendImage(from: verySmallJPEGData()) as! ZMMessage
            offset += 5
            message.setValue(Date().addingTimeInterval(offset), forKey: "serverTimestamp")
            messages.append(message)
            message.setPrimitiveValue(NSNumber(value: 0), forKey: ZMMessageCachedCategoryKey)
        }
        uiMOC.saveOrRollback()
        return messages
    }

    func testThatItGetsMessagesInTheCorrectOrder() {
        // given
        let messages = insertAssetMessages(count: 10)

        // when
        sut = AssetCollection(conversation: conversation, matchingCategories: [defaultMatchPair], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let receivedMessages = delegate.allMessages(for: defaultMatchPair)
        XCTAssertTrue(receivedMessages.first!.compare(receivedMessages.last!) == .orderedDescending)
        XCTAssertEqual(messages.first, receivedMessages.last)
        XCTAssertEqual(messages.last, receivedMessages.first)
    }

    func testThatItReturnsUIObjects() {
        // given
        insertAssetMessages(count: 1)
        sut = AssetCollection(conversation: conversation, matchingCategories: [defaultMatchPair], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let messages = sut.assets(for: defaultMatchPair)

        // then
        XCTAssertEqual(messages.count, 1)
        guard let message = messages.first as? ZMMessage, let moc = message.managedObjectContext else {return XCTFail()}
        XCTAssertTrue(moc.zm_isUserInterfaceContext)
    }

    func testThatItCanGetMessages_TotalMessageCountSmallerThanInitialFetchCount() {
        // given
        let totalMessageCount = AssetCollection.initialFetchCount - 10
        XCTAssertGreaterThan(totalMessageCount, 0)
        insertAssetMessages(count: totalMessageCount)

        // when
        sut = AssetCollection(conversation: conversation, matchingCategories: [self.defaultMatchPair], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(delegate.result, .success)
        XCTAssertEqual(delegate.messagesByFilter.count, 1)
        XCTAssertTrue(sut.fetchingDone)

        let receivedMessageCount = delegate.messagesByFilter.first?[self.defaultMatchPair]?.count
        XCTAssertEqual(receivedMessageCount, 90)

        guard let lastMessage =  delegate.messagesByFilter.last?[self.defaultMatchPair]?.last,
              let context = lastMessage.managedObjectContext else { return XCTFail() }
        XCTAssertTrue(context.zm_isUserInterfaceContext)
    }

    func testThatItCanGetMessages_TotalMessageCountEqualInitialFetchCount() {
        // given
        let totalMessageCount = AssetCollection.initialFetchCount
        insertAssetMessages(count: totalMessageCount)

        // when
        sut = AssetCollection(conversation: conversation, matchingCategories: [self.defaultMatchPair], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(delegate.result, .success)
        XCTAssertEqual(delegate.messagesByFilter.count, 1)
        XCTAssertTrue(sut.fetchingDone)

        let receivedMessageCount = delegate.messagesByFilter.first?[self.defaultMatchPair]?.count
        XCTAssertEqual(receivedMessageCount, 100)

        guard let lastMessage =  delegate.messagesByFilter.last?[self.defaultMatchPair]?.last,
            let context = lastMessage.managedObjectContext else { return XCTFail() }
        XCTAssertTrue(context.zm_isUserInterfaceContext)
    }

    func testThatItCanGetMessages_TotalMessageCountGreaterThanInitialFetchCount() {
        // given
        let totalMessageCount = 2 * AssetCollection.defaultFetchCount
        XCTAssertGreaterThan(totalMessageCount, AssetCollection.initialFetchCount)

        insertAssetMessages(count: totalMessageCount)

        // when
        sut = AssetCollection(conversation: conversation, matchingCategories: [self.defaultMatchPair], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        // messages were filtered in three batches
        XCTAssertEqual(delegate.result, .success)
        XCTAssertEqual(delegate.messagesByFilter.count, 3)
        XCTAssertTrue(sut.fetchingDone)

        let receivedMessages = delegate.allMessages(for: defaultMatchPair)
        XCTAssertEqual(receivedMessages.count, 1000)

        guard let lastMessage =  receivedMessages.last,
            let context = lastMessage.managedObjectContext else { return XCTFail() }
        XCTAssertTrue(context.zm_isUserInterfaceContext)
    }

    func testThatItCallsTheDelegateWhenTheMessageCountIsZero() {
        // when
        sut = AssetCollection(conversation: conversation, matchingCategories: [self.defaultMatchPair], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(delegate.result, .noAssetsToFetch)
        XCTAssertTrue(delegate.didCallDelegate)
        XCTAssertTrue(sut.fetchingDone)
    }

    func testThatItCanCancelFetchingMessages() {
        // given
        let totalMessageCount = 2 * AssetCollection.defaultFetchCount
        insertAssetMessages(count: totalMessageCount)

        // when
        sut = AssetCollection(conversation: conversation, matchingCategories: [self.defaultMatchPair], delegate: delegate)
        sut.tearDown()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        // messages would filtered in three batches if the fetching was not cancelled
        XCTAssertNotEqual(delegate.messagesByFilter.count, 3)
        XCTAssertTrue(sut.fetchingDone)
    }

    func testPerformanceOfMessageFetching() {
        // Before caching:
        // 1000 messages, 1 category, 500 defaultpaging, average: 0.275, relative standard deviation: 8.967%, values: [0.348496, 0.263188, 0.266409, 0.268903, 0.265612, 0.265829, 0.271573, 0.265206, 0.268697, 0.264837]
        // 1000 messages, 1 category, 200 defaultpaging, average: 0.304, relative standard deviation: 9.818%, values: [0.390736, 0.285759, 0.293118, 0.290341, 0.293730, 0.281093, 0.292787, 0.305865, 0.306954, 0.302983]
        // 1000 messages, 2 categories, 500 defaultpaging, average: 0.570, relative standard deviation: 5.990%, values: [0.656057, 0.526296, 0.530267, 0.572129, 0.557102, 0.586183, 0.574734, 0.580168, 0.563595, 0.556718]
        // 10000 messages, average: 3.495, relative standard deviation: 7.352%, values: [4.259749, 3.372894, 3.389057, 3.404054, 3.363652, 3.400085, 3.416911, 3.417086, 3.442652, 3.488077],

        // given
        insertAssetMessages(count: 1000)
        uiMOC.registeredObjects.forEach {uiMOC.refresh($0, mergeChanges: false)}

        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {

            // when
            self.startMeasuring()
            self.sut = AssetCollection(conversation: self.conversation, matchingCategories: [self.defaultMatchPair], delegate: self.delegate)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            self.stopMeasuring()

            // then
            self.sut.tearDown()
            self.sut = nil
            self.uiMOC.registeredObjects.forEach {self.uiMOC.refresh($0, mergeChanges: false)}
        }
    }

    func testThatItReturnsPreCategorizedItems() {
        // given
        insertAssetMessages(count: 10)

        // when
        conversation.allMessages.forEach {_ = $0.cachedCategory}
        uiMOC.saveOrRollback()

        sut = AssetCollection(conversation: conversation, matchingCategories: [self.defaultMatchPair], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let receivedMessageCount = delegate.messagesByFilter.first?[self.defaultMatchPair]?.count
        XCTAssertEqual(receivedMessageCount, 10)
    }

    func testThatItGetsPreCategorizedMessagesInTheCorrectOrder() {
        // given
        let messages = insertAssetMessages(count: 10)
        conversation.allMessages.forEach {_ = $0.cachedCategory}
        uiMOC.saveOrRollback()

        // when
        sut = AssetCollection(conversation: conversation, matchingCategories: [defaultMatchPair], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let receivedMessages = delegate.allMessages(for: defaultMatchPair)
        XCTAssertTrue(receivedMessages.first!.compare(receivedMessages.last!) == .orderedDescending)
        XCTAssertEqual(messages.first, receivedMessages.last)
        XCTAssertEqual(messages.last, receivedMessages.first)
    }

    func testThatItExcludesDefinedCategories_PreCategorized() {
        // given
        let data = self.data(forResource: "animated", extension: "gif")!
        _ = try! conversation.appendImage(from: data) as! ZMAssetClientMessage

        // when
        conversation.allMessages.forEach {_ = $0.cachedCategory}
        uiMOC.saveOrRollback()
        let excludingGif = CategoryMatch(including: .image, excluding: .GIF)
        sut = AssetCollection(conversation: conversation, matchingCategories: [excludingGif], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(delegate.messagesByFilter.count, 0)

        XCTAssertTrue(delegate.didCallDelegate)
        XCTAssertEqual(delegate.result, .noAssetsToFetch)
    }

    func testThatItExcludesDefinedCategories_NotPreCategorized() {
        // given
        insertAssetMessages(count: 1)
        let data = self.data(forResource: "animated", extension: "gif")!
        _ = try! conversation.appendImage(from: data) as! ZMAssetClientMessage
        uiMOC.saveOrRollback()

        // when
        let excludingGif = CategoryMatch(including: .image, excluding: .GIF)
        sut = AssetCollection(conversation: conversation, matchingCategories: [excludingGif], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let receivedMessages = delegate.messagesByFilter.first?[excludingGif]?.count
        XCTAssertEqual(receivedMessages, 1)

        XCTAssertTrue(delegate.didCallDelegate)
        XCTAssertEqual(delegate.result, .success)
    }

    func testThatItSortsExcludingCategories() {
        // given
        insertAssetMessages(count: 1)

        let data = self.data(forResource: "animated", extension: "gif")!
        _ = try! conversation.appendImage(from: data) as! ZMAssetClientMessage
        uiMOC.saveOrRollback()

        // when
        let excludingGif = CategoryMatch(including: .image, excluding: .GIF)
        let onlyGif = CategoryMatch(including: .GIF, excluding: .none)
        let allImages = defaultMatchPair
        sut = AssetCollection(conversation: conversation, matchingCategories: [excludingGif, onlyGif, allImages], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let receivedNonGifs = delegate.allMessages(for: excludingGif)
        let receivedGifs = delegate.allMessages(for: onlyGif)
        let receivedImages = delegate.allMessages(for: allImages)

        XCTAssertEqual(receivedNonGifs.count, 1)
        XCTAssertEqual(receivedGifs.count, 1)
        XCTAssertEqual(receivedImages.count, 2)

        XCTAssertTrue(delegate.didCallDelegate)
        XCTAssertEqual(delegate.result, .success)
    }

    func testThatItFetchesImagesAndTextMessages() {
        // given
        insertAssetMessages(count: 10)
        try! conversation.appendText(content: "foo")
        uiMOC.saveOrRollback()

        // when
        let textMatchPair = CategoryMatch(including: .text, excluding: .none)

        sut = AssetCollection(conversation: conversation, matchingCategories: [self.defaultMatchPair, textMatchPair], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let receivedAssets = delegate.allMessages(for: defaultMatchPair)
        XCTAssertEqual(receivedAssets.count, 10)

        let receivedTexts = delegate.allMessages(for: textMatchPair)
        XCTAssertEqual(receivedTexts.count, 1)

        XCTAssertEqual(delegate.result, .success)
    }

    func testThatItFetchesPreAndUncategorizedObjectsAndSavesThemAsUIDObjects() {
        // given
        let messages = insertAssetMessages(count: 20)
        messages[0..<10].forEach {_ = $0.cachedCategory}
        uiMOC.saveOrRollback()

        // when
        sut = AssetCollection(conversation: conversation, matchingCategories: [defaultMatchPair], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let allMessages = sut.assets(for: defaultMatchPair)
        XCTAssertEqual(allMessages.count, 20)
        XCTAssertTrue(allMessages.allSatisfy { element in
            guard let message = element as? ZMMessage else { return false }
            return message.managedObjectContext!.zm_isUserInterfaceContext
        })
    }

    func testThatItDoesNotReturnFailedToUploadAssets_Uncategorized() {
        // given
        let includedMessage = try! self.conversation.appendFile(with: ZMVideoMetadata(fileURL: self.fileURL(forResource: "video", extension: "mp4"), thumbnail: self.verySmallJPEGData())) as! ZMAssetClientMessage
        let excludedMessage = try! self.conversation.appendFile(with: ZMVideoMetadata(fileURL: self.fileURL(forResource: "video", extension: "mp4"), thumbnail: self.verySmallJPEGData())) as! ZMAssetClientMessage
        excludedMessage.transferState = .uploadingFailed
        excludedMessage.setPrimitiveValue(NSNumber(value: 0), forKey: ZMMessageCachedCategoryKey)
        includedMessage.setPrimitiveValue(NSNumber(value: 0), forKey: ZMMessageCachedCategoryKey)
        uiMOC.saveOrRollback()

        let match = CategoryMatch(including: .file, excluding: .none)

        // when
        sut = AssetCollection(conversation: conversation, matchingCategories: [match], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let receivedMessages = delegate.allMessages(for: match)
        XCTAssertEqual(receivedMessages.count, 1)
        XCTAssertEqual(receivedMessages.first, includedMessage)
    }

    func testThatItDoesNotReturnFailedToUploadAssets_PreCategorized() {
        // given
        let includedMessage = try! self.conversation.appendFile(with: ZMVideoMetadata(fileURL: self.fileURL(forResource: "video", extension: "mp4"), thumbnail: self.verySmallJPEGData())) as! ZMAssetClientMessage
        let excludedMessage = try! self.conversation.appendFile(with: ZMVideoMetadata(fileURL: self.fileURL(forResource: "video", extension: "mp4"), thumbnail: self.verySmallJPEGData())) as! ZMAssetClientMessage
        excludedMessage.transferState = .uploadingFailed
        excludedMessage.updateCategoryCache()
        uiMOC.saveOrRollback()

        let match = CategoryMatch(including: .file, excluding: .none)

        // when
        sut = AssetCollection(conversation: conversation, matchingCategories: [match], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let receivedMessages = delegate.allMessages(for: match)
        XCTAssertEqual(receivedMessages.count, 1)
        XCTAssertEqual(receivedMessages.first, includedMessage)
    }
}
