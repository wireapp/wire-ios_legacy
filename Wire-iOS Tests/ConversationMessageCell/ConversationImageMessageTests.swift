//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import XCTest
@testable import Wire


import XCTest

class ConversationImageMessageTests: ConversationCellSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        defaultImageCache.cache.removeAllObjects()
        super.tearDown()
    }
    
    func testTransparentImage() {
        // GIVEN
        let image = self.image(inTestBundleNamed: "transparent.png")
        let message = MockMessageFactory.imageMessage(with: image)!
        message.sender = otherUser
        
        // THEN
        verify(message: message, waitForImagesToLoad: true)
    }
    
    func testOpaqueImage() {
        // GIVEN
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let message = MockMessageFactory.imageMessage(with: image)!
        message.sender = otherUser
        
        // THEN
        verify(message: message, waitForImagesToLoad: true)
    }
    
    func testNotDownloadedImage() {
        // GIVEN
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let message = MockMessageFactory.imageMessage(with: image)!
        message.sender = otherUser
        
        // THEN
        verify(message: message, waitForImagesToLoad: false)
    }
    
    func testObfuscatedImage() {
        // GIVEN
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let message = MockMessageFactory.imageMessage(with: image)!
        message.isObfuscated = true
        message.sender = otherUser
        
        // THEN
        verify(message: message)
    }
    
}
