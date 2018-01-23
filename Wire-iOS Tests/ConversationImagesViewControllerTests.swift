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
@testable import Wire

class ConversationImagesViewControllerTests: CoreDataSnapshotTestCase {
    
    var sut: ConversationImagesViewController! = nil
    
    override var needsCaches: Bool {
        return true
    }
    
    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = UIColor.white
    
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let initialMessage = otherUserConversation.appendMessage(withImageData: image.data())!
        let imagesCategoryMatch = CategoryMatch(including: .image, excluding: .none)
        let collection = MockCollection(messages: [ imagesCategoryMatch : [initialMessage] ])
        let delegate = AssetCollectionMulticastDelegate()
        
        let assetWrapper = AssetCollectionWrapper(conversation: otherUserConversation, assetCollection: collection, assetCollectionDelegate: delegate, matchingCategories: [imagesCategoryMatch])
        sut = ConversationImagesViewController(collection: assetWrapper, initialMessage: initialMessage, inverse: true)
    }
    
    func testThatItDisplaysCorrectToolbarForImage_Normal() {
        sut.view.bounds.size = CGSize(width: 375.0, height: 667.0)
        verify(view: sut.view)
    }
    
    func testThatItDisplaysCorrectToolbarForImage_Ephemeral() {
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let message = MockMessageFactory.imageMessage(with: image)!
        message.isEphemeral = true
        sut.currentMessage = message
        
        sut.view.bounds.size = CGSize(width: 375.0, height: 667.0)
        verify(view: sut.view)
    }
}
