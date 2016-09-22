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
        let cell = sut.prepareForSnapshot(image.size, image: image)
        verify(view: cell)
    }

    func testThatItRendersImageMessageWhenImageIsSet_SmallImage() {
        let image = self.image(inTestBundleNamed: "unsplash_small.jpg")
        let cell = sut.prepareForSnapshot(image.size, image: image)
        verify(view: cell)
    }

    func testThatItRendersImageMessageWithResendButton() {
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let cell = sut.prepareForSnapshot(image.size, image: image, failedToSend: true)
        verify(view: cell)
    }
    
    func testThatItRendersImageMessageWithResendButton_SmallImage() {
        let image = self.image(inTestBundleNamed: "unsplash_small.jpg")
        let cell = sut.prepareForSnapshot(image.size, image: image, failedToSend: true)
        verify(view: cell)
    }

}

private extension ImageMessageCell {

    func prepareForSnapshot(_ imageSize: CGSize, image: UIImage? = nil, failedToSend: Bool = false) -> ImageMessageCell {
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false
        layoutProperties.alwaysShowDeliveryState = failedToSend
        
        let message = MockMessageFactory.imageMessage()
        message?.deliveryState = failedToSend ? .failedToSend : .delivered
        let imageMessageData = message?.imageMessageData as! MockImageMessageData
        imageMessageData.mockOriginalSize = imageSize

        prepareForReuse()
        configure(for: message, layoutProperties: layoutProperties)
        layoutIfNeeded()
        
        if let image = image {
            setImage(image)
        }

        let size = systemLayoutSizeFitting(
            CGSize(width: 320, height: 0),
            withHorizontalFittingPriority: UILayoutPriorityRequired,
            verticalFittingPriority: UILayoutPriorityFittingSizeLevel
        )

        bounds = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        layer.speed = 0

        setNeedsLayout()
        layoutIfNeeded()
        return self
    }

}
