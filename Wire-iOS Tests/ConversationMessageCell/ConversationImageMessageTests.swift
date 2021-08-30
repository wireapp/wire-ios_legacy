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

final class ConversationImageMessageTests: XCTestCase {

    var image: UIImage!
    var message: MockMessage!

    override func setUp() {
        super.setUp()

        UIColor.setAccentOverride(.vividRed)
    }

    override func tearDown() {
        image = nil
        message = nil

        MediaAssetCache.defaultImageCache.cache.removeAllObjects()
        super.tearDown()
    }

    private func createSut(imageName: String) {
        image = image(inTestBundleNamed: imageName)
        message = MockMessageFactory.imageMessage(with: image)
        let sender = MockUserType.createDefaultOtherUser()
        message.senderUser = sender
    }

    func testTransparentImage() {
        // GIVEN
        createSut(imageName: "transparent.png")

        // THEN
        verify(message: message, waitForImagesToLoad: true)
    }

    func testOpaqueImage() {
        // GIVEN
        createSut(imageName: "unsplash_matterhorn.jpg")

        // THEN
        verify(message: message, waitForImagesToLoad: true)
    }

    func testNotDownloadedImage() {
        // GIVEN
        createSut(imageName: "unsplash_matterhorn.jpg")

        // THEN
        verify(message: message)
    }

    func testObfuscatedImage() {
        // GIVEN
        createSut(imageName: "unsplash_matterhorn.jpg")
        message.isObfuscated = true

        // THEN
        verify(message: message)
    }

    // MARK: - Receiving restrictions

    func testRestrictionMessageCell() {
        createSut(imageName: "unsplash_matterhorn.jpg")
        message.backingIsRestricted = true

        verify(message: message)
    }

}
