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
@testable import Wire
import WireLinkPreview

class MessagePreviewViewTests: ZMSnapshotTestCase {
    var sut: UIView!

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItRendersTextMessagePreview() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")!
        verify(view: message.previewView()!)
    }
    
    func testThatItRendersTextMessagePreview_LongText() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed.")!
        verify(view: message.previewView()!)
    }
    
    func testThatItRendersFileMessagePreview() {
        let message = MockMessageFactory.fileTransferMessage()!
        verify(view: message.previewView()!)
    }
    
    func testThatItRendersLocationMessagePreview() {
        let message = MockMessageFactory.locationMessage()!
        verify(view: message.previewView()!)
    }
    
    func testThatItRendersLinkPreviewMessagePreview() {
        let message = MockMessageFactory.linkMessage()!
        let article = Article(
            originalURLString: "https://www.example.com/article/1",
            permanentURLString: "https://www.example.com/article/1",
            resolvedURLString: "https://www.example.com/article/1",
            offset: 0
        )

        article.title = "You won't believe what happened next!"
        let textMessageData = MockTextMessageData()
        textMessageData.linkPreview = article
        textMessageData.linkPreviewImageCacheKey = "image-id-unsplash_matterhorn.jpg"
        textMessageData.imageData = UIImageJPEGRepresentation(image(inTestBundleNamed: "unsplash_matterhorn.jpg"), 0.9)
        textMessageData.linkPreviewHasImage = true
        message.backingTextMessageData = textMessageData
        
        let previewView = message.previewView()!
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        
        verify(view: previewView)
    }
    
    func testThatItRendersVideoMessagePreview() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.mimeType = "video/mp4"
        message.backingFileMessageData.filename = "vacation.mp4"
        message.backingFileMessageData.imagePreviewData = UIImageJPEGRepresentation(image(inTestBundleNamed: "unsplash_matterhorn.jpg"), 0.9)
        
        let previewView = message.previewView()!
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        
        verify(view: previewView)
    }
    
}
