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

import SnapshotTesting
import XCTest
import WireDataModel
@testable import Wire

extension MockMessage {
    var message: ZMConversationMessage {
        return self as Any as! ZMConversationMessage
    }
}

final class CollectionsViewControllerTests: XCTestCase {

    var emptyCollection: AssetCollectionWrapper!
    var imageMessage: ZMConversationMessage!
    var videoMessage: ZMConversationMessage!
    var audioMessage: ZMConversationMessage!
    var fileMessage: ZMConversationMessage!
    var linkMessage: ZMConversationMessage!

    var expiredImageMessage: ZMConversationMessage!
    var expiredVideoMessage: ZMConversationMessage!
    var expiredAudioMessage: ZMConversationMessage!
    var expiredFileMessage: ZMConversationMessage!
    var expiredLinkMessage: ZMConversationMessage!

    var deletedImageMessage: ZMConversationMessage!
    var deletedVideoMessage: ZMConversationMessage!
    var deletedAudioMessage: ZMConversationMessage!
    var deletedFileMessage: ZMConversationMessage!
    var deletedLinkMessage: ZMConversationMessage!

    override func setUp() {
        super.setUp()

        accentColor = .vividRed

        let conversation = MockConversation() as Any as! ZMConversation
        let assetCollection = MockCollection.empty
        let delegate = AssetCollectionMulticastDelegate()
        emptyCollection = AssetCollectionWrapper(conversation: conversation, assetCollection: assetCollection, assetCollectionDelegate: delegate, matchingCategories: [])

        imageMessage = MockMessageFactory.imageMessage()
        videoMessage = MockMessageFactory.videoMessage()
        audioMessage = MockMessageFactory.audioMessage()
        fileMessage = MockMessageFactory.fileTransferMessage()
        linkMessage = MockMessageFactory.linkMessage()

        expiredImageMessage = MockMessageFactory.expiredImageMessage()
        expiredVideoMessage = MockMessageFactory.expiredVideoMessage()
        expiredFileMessage = MockMessageFactory.expiredFileMessage()
        expiredLinkMessage = MockMessageFactory.expiredLinkMessage()
        expiredAudioMessage = MockMessageFactory.expiredAudioMessage()

        deletedImageMessage = MockMessageFactory.deletedImageMessage()
        deletedVideoMessage = MockMessageFactory.deletedVideoMessage()
        deletedFileMessage = MockMessageFactory.deletedFileMessage()
        deletedLinkMessage = MockMessageFactory.deletedLinkMessage()
        deletedAudioMessage = MockMessageFactory.deletedAudioMessage()
    }

    override func tearDown() {
        emptyCollection = nil
        imageMessage = nil
        videoMessage = nil
        audioMessage = nil
        fileMessage = nil
        linkMessage = nil

        expiredImageMessage = nil
        expiredVideoMessage = nil
        expiredAudioMessage = nil
        expiredFileMessage = nil
        expiredLinkMessage = nil

        deletedImageMessage = nil
        deletedVideoMessage = nil
        deletedAudioMessage = nil
        deletedFileMessage = nil
        deletedLinkMessage = nil

        super.tearDown()
    }

    func testThatNoElementStateIsShownWhenCollectionIsEmpty() {
        let controller = CollectionsViewController(collection: emptyCollection, fetchingDone: true)
        verifyAllIPhoneSizes(matching: controller)
    }

    func testThatLoadingIsShownWhenFetching() {
        let controller = CollectionsViewController(collection: emptyCollection, fetchingDone: false)
        controller.view.layer.speed = 0 // Disable animations so that the spinner would always be in the same phase
        verifyAllIPhoneSizes(matching: controller)
    }

    func testFilesSectionWhenNotFull() {
        let assetCollection = MockCollection(fileMessages: [fileMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

    func testFilesSectionWhenFull() {
        let assetCollection = MockCollection(fileMessages: [fileMessage, fileMessage, fileMessage, fileMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

    func testLinksSectionWhenNotFull() {
        let assetCollection = MockCollection(linkMessages: [linkMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

    func testLinksSectionWhenFull() {
        let assetCollection = MockCollection(linkMessages: [linkMessage, linkMessage, linkMessage, linkMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

    // MARK: - Expiration

    func testImagesSectionWhenExpired() {
        let assetCollection = MockCollection(messages: [
            MockCollection.onlyImagesCategory: [expiredImageMessage],
            MockCollection.onlyVideosCategory: [videoMessage, expiredVideoMessage]])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

    func testFilesSectionWhenExpired() {
        let assetCollection = MockCollection(fileMessages: [fileMessage, expiredFileMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

    func testAudioSectionWhenExpired() {
        let assetCollection = MockCollection(fileMessages: [audioMessage, expiredAudioMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

    func testLinksSectionWhenExpired() {
        let assetCollection = MockCollection(linkMessages: [expiredLinkMessage, linkMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

    // MARK: - Expiration: Deletion

    func testImagesSectionWhenDeleted() {
        let assetCollection = MockCollection(messages: [
            MockCollection.onlyImagesCategory: [deletedImageMessage],
            MockCollection.onlyVideosCategory: [videoMessage, deletedVideoMessage]])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

    func testFilesSectionWhenDeleted() {
        let assetCollection = MockCollection(fileMessages: [fileMessage, deletedFileMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

    func testAudioSectionWhenDeleted() {
        let assetCollection = MockCollection(fileMessages: [audioMessage, deletedAudioMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

    func testLinksSectionWhenDeleted() {
        let assetCollection = MockCollection(linkMessages: [deletedLinkMessage, linkMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyAllIPhoneSizes(matching: controller)
    }

}

extension CollectionsViewControllerTests {

    func createController(showingCollection assetCollection: MockCollection) -> CollectionsViewController {
        let conversation = MockConversation() as Any as! ZMConversation
        let delegate = AssetCollectionMulticastDelegate()
        let collection = AssetCollectionWrapper(conversation: conversation, assetCollection: assetCollection, assetCollectionDelegate: delegate, matchingCategories: [])

        let controller = CollectionsViewController(collection: collection)
        _ = controller.view
        delegate.assetCollectionDidFetch(collection: assetCollection, messages: assetCollection.messages, hasMore: false)
        delegate.assetCollectionDidFinishFetching(collection: assetCollection, result: .success)
        return controller
    }
}
