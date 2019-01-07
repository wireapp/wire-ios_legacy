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

import XCTest
import Cartography
@testable import Wire
import WireDataModel

extension MockMessage {
    var message: ZMConversationMessage {
        return self as Any as! ZMConversationMessage
    }
}

class CollectionsViewControllerTests: CoreDataSnapshotTestCase {
    
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

        MockUser.mockSelf()?.name = "Tarja Turunen"
        MockUser.mockSelf()?.accentColorValue = .strongBlue

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
        verifyInAllIPhoneSizes(view: controller.view, extraLayoutPass: true)
    }
    
    func testThatLoadingIsShownWhenFetching() {
        let controller = CollectionsViewController(collection: emptyCollection, fetchingDone: false)
        controller.view.layer.speed = 0 // Disable animations so that the spinner would always be in the same phase
        verifyInAllIPhoneSizes(view: controller.view, extraLayoutPass: true)
    }
    
    func testFilesSectionWhenNotFull() {
        let assetCollection = MockCollection(fileMessages: [fileMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view, extraLayoutPass: true)
    }

    func testFilesSectionWhenFull() {
        let assetCollection = MockCollection(fileMessages: [fileMessage, fileMessage, fileMessage, fileMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view, extraLayoutPass: true)
    }

    func testLinksSectionWhenNotFull() {
        let assetCollection = MockCollection(linkMessages: [linkMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view, extraLayoutPass: true)
    }

    func testLinksSectionWhenFull() {
        let assetCollection = MockCollection(linkMessages: [linkMessage, linkMessage, linkMessage, linkMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view, extraLayoutPass: true)
    }

    // MARK: - Expiration

    func testImagesSectionWhenExpired() {
        let assetCollection = MockCollection(messages: [
            MockCollection.onlyImagesCategory: [expiredImageMessage],
            MockCollection.onlyVideosCategory: [videoMessage, expiredVideoMessage]])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view)
    }

    func testFilesSectionWhenExpired() {
        let assetCollection = MockCollection(fileMessages: [fileMessage, expiredFileMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view)
    }

    func testAudioSectionWhenExpired() {
        let assetCollection = MockCollection(fileMessages: [audioMessage, expiredAudioMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view)
    }

    func testLinksSectionWhenExpired() {
        let assetCollection = MockCollection(linkMessages: [expiredLinkMessage, linkMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view)
    }

    // MARK: - Expiration: Deletion
    
    func testImagesSectionWhenDeleted() {
        let assetCollection = MockCollection(messages: [
            MockCollection.onlyImagesCategory: [deletedImageMessage],
            MockCollection.onlyVideosCategory: [videoMessage, deletedVideoMessage]])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view)
    }
    
    func testFilesSectionWhenDeleted() {
        let assetCollection = MockCollection(fileMessages: [fileMessage, deletedFileMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view)
    }
    
    func testAudioSectionWhenDeleted() {
        let assetCollection = MockCollection(fileMessages: [audioMessage, deletedAudioMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view)
    }
    
    func testLinksSectionWhenDeleted() {
        let assetCollection = MockCollection(linkMessages: [deletedLinkMessage, linkMessage])
        let controller = createController(showingCollection: assetCollection)
        verifyInAllIPhoneSizes(view: controller.view)
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
