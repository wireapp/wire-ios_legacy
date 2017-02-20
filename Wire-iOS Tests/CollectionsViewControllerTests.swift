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
import ZMCDataModel

extension MockMessage {
    var message: ZMConversationMessage {
        return self as Any as! ZMConversationMessage
    }
}

class CollectionsViewControllerTests: ZMSnapshotTestCase {
    
    var emptyCollection: AssetCollectionWrapper!
    var fileMessage: ZMConversationMessage!
    var linkMessage: ZMConversationMessage!

    override func setUp() {
        super.setUp()
        let conversation = MockConversation() as Any as! ZMConversation
        let assetCollection = MockCollection.empty
        let delegate = AssetCollectionMulticastDelegate()
        emptyCollection = AssetCollectionWrapper(conversation: conversation, assetCollection: assetCollection, assetCollectionDelegate: delegate, matchingCategories: [])
        
        fileMessage = MockMessageFactory.fileTransferMessage()
        linkMessage = MockMessageFactory.linkMessage()
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
