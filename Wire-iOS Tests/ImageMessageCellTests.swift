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

class ImageMessageCellTests: ZMSnapshotTestCase {

    var sut: ImageMessageCell! = nil

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = UIColor.white
        sut = ImageMessageCell(style: .default, reuseIdentifier: name!)
    }

    func testThatItRendersImageMessagePlaceholderWhenNoImageIsSet() {
        verify(view: sut.prepareForSnapshot(CGSize(width: 450, height: 600)))
    }

    func testThatItRendersImageMessagePlaceholderWhenNoImageIsSet_LandscapeImage() {
        verify(view: sut.prepareForSnapshot(CGSize(width: 650, height: 200)))
    }

    func testThatItRendersImageMessagePlaceholderWhenNoImageIsSet_SmallImage() {
        verify(view: sut.prepareForSnapshot(CGSize(width: 200, height: 200)))
    }

    func testThatItRendersImageMessageWhenImageIsSet() {
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let wrap = sut.prepareForSnapshot(image.size, image: image)
        verify(view: wrap)
    }

    func testThatItRendersImageMessageWhenImageIsSet_SmallImage() {
        let image = self.image(inTestBundleNamed: "unsplash_small.jpg")
        let wrap = sut.prepareForSnapshot(image.size, image: image)
        verify(view: wrap)
    }

    func testThatItRendersImageMessageWithResendButton() {
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let wrap = sut.prepareForSnapshot(image.size, image: image, failedToSend: true)
        verify(view: wrap)
    }
    
    func testThatItRendersImageMessageWithResendButton_SmallImage() {
        let image = self.image(inTestBundleNamed: "unsplash_small.jpg")
        let wrap = sut.prepareForSnapshot(image.size, image: image, failedToSend: true)
        verify(view: wrap)
    }

    func testThatItRendersImageMessageObfuscated() {
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let wrap = sut.prepareForSnapshot(image.size, image: image, obfuscated: true)
        verify(view: wrap)
    }
    
    func testThatItRendersImageWhenSelected() {
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let wrap = sut.prepareForSnapshot(image.size, image: image, selected: true)
        verify(view: wrap)
    }
    
    func testThatItRendersImageWhenSelected_SmallImage() {
        let image = self.image(inTestBundleNamed: "unsplash_small.jpg")
        let wrap = sut.prepareForSnapshot(image.size, image: image, selected: true)
        verify(view: wrap)
    }
    
    func testThatItRendersImageWhenSelected_Ephemeral() {
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let wrap = sut.prepareForSnapshot(image.size, image: image, selected: true, ephemeral: true)
        verify(view: wrap)
    }
}

private extension ImageMessageCell {

    func prepareForSnapshot(_ imageSize: CGSize, image: UIImage? = nil, failedToSend: Bool = false, obfuscated: Bool = false, selected: Bool = false, ephemeral: Bool = false) -> UITableView {
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false
        layoutProperties.alwaysShowDeliveryState = failedToSend
        
        let message = MockMessageFactory.imageMessage()
        message?.deliveryState = failedToSend ? .failedToSend : .delivered
        message?.isObfuscated = obfuscated
        message?.isEphemeral = ephemeral
        let imageMessageData = message?.imageMessageData as! MockImageMessageData
        imageMessageData.mockOriginalSize = imageSize

        prepareForReuse()
        configure(for: message, layoutProperties: layoutProperties)
        setSelected(selected, animated: false)
        layoutIfNeeded()
        
        if let image = image {
            setImage(image)
        }

        layer.speed = 0

        return self.wrapInTableView()
    }

}
