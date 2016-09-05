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


@testable import Wire

class TextMessageCellTests: ZMSnapshotTestCase {

    var sut: TextMessageCell!

    var layoutProperties: ConversationCellLayoutProperties {
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false
        return layoutProperties
    }

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .whiteColor()
        accentColor = .StrongBlue
        sut = TextMessageCell(style: .Default, reuseIdentifier: name!)
        sut.layer.speed = 0
        [Message.shortVersionDateFormatter(), Message.longVersionTimeFormatter()].forEach {
            $0.locale = NSLocale(localeIdentifier: "en_US")
            $0.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        }
    }
    
    func testThatItRendersATextMessage_Sent() {
        sut.setSelected(true, animated: false)
        sut.configureForMessage(mockMessage(state: .Sent), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_Delivered() {
        sut.setSelected(true, animated: false)
        sut.configureForMessage(mockMessage(state: .Delivered), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_Expired() {
        sut.configureForMessage(mockMessage(state: .FailedToSend), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_Selected() {
        sut.setSelected(true, animated: false)
        sut.configureForMessage(mockMessage(), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_Pending_Selected() {
        sut.setSelected(true, animated: false)
        sut.configureForMessage(mockMessage(state: .Pending), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_LongText() {
        let text = "".stringByPaddingToLength(71,  withString: "Hello ", startingAtIndex: 0)
        sut.configureForMessage(mockMessage(text), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersEditedTimestampCorrectly_Selected() {
        sut.setSelected(true, animated: false)
        sut.configureForMessage(mockMessage(edited: true), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersEditedTimestampCorrectly_Selected_LongText() {
        let text = "".stringByPaddingToLength(70, withString: "Hello ", startingAtIndex: 0)
        sut.setSelected(true, animated: false)
        sut.configureForMessage(mockMessage(text, edited: true), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersEditedTimestampCorrectly_Selected_LongText_Pending() {
        let text = "".stringByPaddingToLength(70, withString: "Hello ", startingAtIndex: 0)
        sut.setSelected(true, animated: false)
        sut.configureForMessage(mockMessage(text, edited: true, state: .Pending), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatRenderLastSentMessageWithoutLikeIcon() {
        let layoutProperties = self.layoutProperties
        layoutProperties.alwaysShowDeliveryState = true
        sut.configureForMessage(mockMessage(state: .Sent), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatRenderLastSentMessageWithLikeIcon_whenSelected() {
        let layoutProperties = self.layoutProperties
        layoutProperties.alwaysShowDeliveryState = true
        sut.setSelected(true, animated: false)
        sut.configureForMessage(mockMessage(state: .Sent), layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersATextMessage_LikedReceiver() {
        let message = mockMessage(state: .Sent)
        message.backingUsersReaction = [ZMMessageReaction.Like.rawValue: [otherUsers.first!]]
        sut.configureForMessage(message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersATextMessage_LikedSender() {
        let message = mockMessage(state: .Sent)
        message.backingUsersReaction = [ZMMessageReaction.Like.rawValue: [selfUser]]
        sut.configureForMessage(message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersATextMessage_LikedSelected() {
        let message = mockMessage(state: .Sent)
        message.backingUsersReaction = [ZMMessageReaction.Like.rawValue: [selfUser]]
        sut.configureForMessage(message, layoutProperties: layoutProperties)
        sut.setSelected(true, animated: false)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersATextMessage_LikedByTwoPeople() {
        let message = mockMessage(state: .Sent)
        message.backingUsersReaction = [ZMMessageReaction.Like.rawValue: Array(otherUsers[0..<2])]
        sut.configureForMessage(message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    func testThatItRendersATextMessage_LikedByTwoPeopleIncludingSelf() {
        let message = mockMessage(state: .Sent)
        message.backingUsersReaction = [ZMMessageReaction.Like.rawValue: [selfUser] + [otherUsers.first!]]
        sut.configureForMessage(message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }

    func testThatItRendersATextMessage_LikedByALotOfPeople() {
        let message = mockMessage(state: .Sent)
        message.backingUsersReaction = [ZMMessageReaction.Like.rawValue: [selfUser] + otherUsers]
        sut.configureForMessage(message, layoutProperties: layoutProperties)
        verify(view: sut.prepareForSnapshot())
    }
    
    // MARK: - Helper
    
    func mockMessage(text: String? = "Hello World", edited: Bool = false, state: ZMDeliveryState = .Delivered) -> MockMessage {
        let message = MockMessageFactory.textMessageWithText(text)
        message.deliveryState = state
        message.serverTimestamp = NSDate(timeIntervalSince1970: 1234567230)
        message.updatedAt = edited ? NSDate(timeIntervalSince1970: 0) : nil
        return message
    }
    
    var selfUser: ZMUser {
        return (MockUser.mockSelfUser() as AnyObject) as! ZMUser
    }

    var otherUsers: [ZMUser] {
        return MockUser.mockUsers().map { $0 as! ZMUser }
    }

}

private extension TextMessageCell {

    func prepareForSnapshot() -> UIView {
        let size = systemLayoutSizeFittingSize(
            CGSize(width: 375, height: 0),
            withHorizontalFittingPriority: UILayoutPriorityRequired,
            verticalFittingPriority: UILayoutPriorityFittingSizeLevel
        )
        
        bounds = CGRect(origin: .zero, size: size)
        setNeedsLayout()
        layoutIfNeeded()
        return self
    }

}
