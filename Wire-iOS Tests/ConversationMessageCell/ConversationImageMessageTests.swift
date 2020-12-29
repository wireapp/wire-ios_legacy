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

import XCTest
@testable import Wire

final class ConversationImageMessageTests: ConversationCellSnapshotTestCase {

    var image: UIImage!
    var message: MockMessage!

    override func setUp() {
        super.setUp()
        
        image = image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        message = MockMessageFactory.imageMessage(with: image)!
        message.senderUser = MockUserType.createUser(name: "Bob")
    }

    override func tearDown() {
        image = nil
        message = nil
        
        MediaAssetCache.defaultImageCache.cache.removeAllObjects()
        super.tearDown()
    }
    
    func testTransparentImage() {
        // GIVEN
        
        // THEN
        verify(message: message, waitForImagesToLoad: true)
    }
    
    func testOpaqueImage() {
        // GIVEN
        
        // THEN
        verify(message: message, waitForImagesToLoad: true)
    }
    
    func testNotDownloadedImage() {
        // GIVEN
        
        // THEN
        verify(message: message, waitForImagesToLoad: false)
    }
    
    func testObfuscatedImage() {
        // GIVEN
        message.isObfuscated = true
        
        // THEN
        verify(message: message)
    }
    
}
